-- ============================================================================
-- 06_stored_procedures.sql: Core Transactional Business Logic
-- Implements IN/OUT parameters, ACID transaction control, pessimistic locks
-- (SELECT ... FOR UPDATE), error handling (DECLARE HANDLER), and custom SIGNALs.
-- ============================================================================

USE campuspool;

DROP PROCEDURE IF EXISTS sp_create_ride;
DROP PROCEDURE IF EXISTS sp_request_seat;
DROP PROCEDURE IF EXISTS sp_accept_request;
DROP PROCEDURE IF EXISTS sp_reject_request;
DROP PROCEDURE IF EXISTS sp_start_trip;
DROP PROCEDURE IF EXISTS sp_complete_trip;
DROP PROCEDURE IF EXISTS sp_process_payment;
DROP PROCEDURE IF EXISTS sp_submit_rating;

DELIMITER //

-- ----------------------------------------------------------------------------
-- 1. CREATE RIDE POST PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Validates driver ownership of vehicle, seat capacity, and schedules a new ride offer.
-- WHY: Encapsulates all ride creation rules in SQL so web/mobile apps cannot post invalid rides.
CREATE PROCEDURE sp_create_ride(
    IN  p_driver_id INT,
    IN  p_vehicle_id INT,
    IN  p_pickup_location_id INT,
    IN  p_destination_location_id INT,
    IN  p_community_id INT,
    IN  p_departure_time DATETIME,
    IN  p_seats_offered INT,
    IN  p_estimated_fare DECIMAL(8, 2),
    IN  p_notes VARCHAR(255),
    OUT p_ride_id INT
)
proc_label: BEGIN
    DECLARE v_is_driver INT DEFAULT 0;
    DECLARE v_vehicle_capacity INT DEFAULT 0;
    DECLARE v_vehicle_owner INT DEFAULT 0;

    -- Error handler to roll back any open transactions on unexpected SQL errors
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validation 1: User must exist in the DRIVER table
    SELECT COUNT(*) INTO v_is_driver FROM DRIVER WHERE user_id = p_driver_id;
    IF v_is_driver = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Only verified drivers with registered licenses can post rides.';
    END IF;

    -- Validation 2: Vehicle must belong to this specific driver
    SELECT driver_id, capacity INTO v_vehicle_owner, v_vehicle_capacity 
    FROM VEHICLE 
    WHERE vehicle_id = p_vehicle_id;
    
    IF v_vehicle_owner IS NULL OR v_vehicle_owner <> p_driver_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: The selected vehicle does not belong to the posting driver.';
    END IF;

    -- Validation 3: Offered seats cannot exceed vehicle passenger capacity
    IF p_seats_offered > v_vehicle_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Offered seats cannot exceed vehicle passenger capacity.';
    END IF;

    -- Validation 4: Departure time must be in the future
    IF p_departure_time <= NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Departure time must be set in the future.';
    END IF;

    -- Validation 5: Pickup and destination cannot be identical
    IF p_pickup_location_id = p_destination_location_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Pickup and destination locations cannot be the same.';
    END IF;

    START TRANSACTION;
        INSERT INTO RIDE_POST (
            driver_id, vehicle_id, pickup_location_id, destination_location_id,
            community_id, departure_time, status, seats_offered,
            seats_available, estimated_fare, notes
        ) VALUES (
            p_driver_id, p_vehicle_id, p_pickup_location_id, p_destination_location_id,
            p_community_id, p_departure_time, 'OPEN', p_seats_offered,
            p_seats_offered, p_estimated_fare, p_notes
        );

        SET p_ride_id = LAST_INSERT_ID();
    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 2. REQUEST SEAT PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Submits a passenger seat booking request and records estimated cost share.
-- WHY: Prevents self-booking by drivers and ensures seats are still open before logging request.
CREATE PROCEDURE sp_request_seat(
    IN  p_ride_id INT,
    IN  p_rider_id INT,
    IN  p_seats_requested INT,
    IN  p_message VARCHAR(255),
    OUT p_request_id INT
)
proc_label: BEGIN
    DECLARE v_driver_id INT;
    DECLARE v_seats_available INT;
    DECLARE v_ride_status VARCHAR(20);
    DECLARE v_estimated_fare DECIMAL(8, 2);
    DECLARE v_calculated_fare DECIMAL(8, 2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Retrieve ride details
    SELECT driver_id, seats_available, status, estimated_fare
    INTO v_driver_id, v_seats_available, v_ride_status, v_estimated_fare
    FROM RIDE_POST 
    WHERE ride_id = p_ride_id;

    IF v_driver_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Specified ride post does not exist.';
    END IF;

    -- Rule 1: A driver cannot request a seat on their own ride
    IF v_driver_id = p_rider_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: You cannot request seats on a ride you are driving.';
    END IF;

    -- Rule 2: Ride must be currently OPEN
    IF v_ride_status <> 'OPEN' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: This ride is no longer accepting new booking requests.';
    END IF;

    -- Rule 3: Must have enough seats available
    IF p_seats_requested > v_seats_available THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Requested seats exceed currently available seats.';
    END IF;

    -- Calculate per-passenger fare share using stored function
    SET v_calculated_fare = fn_calculate_fare_share(v_estimated_fare, 1) * p_seats_requested;

    START TRANSACTION;
        INSERT INTO RIDE_REQUEST (
            ride_id, rider_id, seats_requested, message, fare_share, status
        ) VALUES (
            p_ride_id, p_rider_id, p_seats_requested, p_message, v_calculated_fare, 'PENDING'
        );

        SET p_request_id = LAST_INSERT_ID();
    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 3. ACCEPT REQUEST PROCEDURE (PESSIMISTIC ROW LOCKING)
-- ----------------------------------------------------------------------------
-- WHAT: Atomically locks the ride record with SELECT ... FOR UPDATE and accepts rider request.
-- WHY: Prevents race condition / overbooking when two riders request the last seat simultaneously.
CREATE PROCEDURE sp_accept_request(
    IN p_request_id INT,
    IN p_driver_id INT
)
proc_label: BEGIN
    DECLARE v_ride_id INT;
    DECLARE v_ride_driver INT;
    DECLARE v_seats_requested INT;
    DECLARE v_seats_available INT;
    DECLARE v_request_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- Retrieve request details
        SELECT ride_id, seats_requested, status
        INTO v_ride_id, v_seats_requested, v_request_status
        FROM RIDE_REQUEST
        WHERE request_id = p_request_id;

        IF v_ride_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Ride request not found.';
        END IF;

        IF v_request_status <> 'PENDING' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Only pending requests can be accepted.';
        END IF;

        -- CRITICAL: Pessimistic Row Lock (SELECT ... FOR UPDATE) on the ride row
        SELECT driver_id, seats_available
        INTO v_ride_driver, v_seats_available
        FROM RIDE_POST
        WHERE ride_id = v_ride_id
        FOR UPDATE;

        -- Verify driver authorization
        IF v_ride_driver <> p_driver_id THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Unauthorized. Only the posting driver can accept requests.';
        END IF;

        -- Verify remaining seat availability
        IF v_seats_available < v_seats_requested THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Insufficient seats available to accept this request.';
        END IF;

        -- Update the request status to ACCEPTED
        UPDATE RIDE_REQUEST
        SET status = 'ACCEPTED'
        WHERE request_id = p_request_id;

        -- Decrement seats and update status if full
        UPDATE RIDE_POST
        SET seats_available = seats_available - v_seats_requested,
            status = CASE WHEN (seats_available - v_seats_requested) = 0 THEN 'FULL' ELSE status END
        WHERE ride_id = v_ride_id;

    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 4. REJECT REQUEST PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Marks a pending seat request as REJECTED.
-- WHY: Allows driver to decline a booking request cleanly without altering seat counts.
CREATE PROCEDURE sp_reject_request(
    IN p_request_id INT,
    IN p_driver_id INT
)
proc_label: BEGIN
    DECLARE v_ride_id INT;
    DECLARE v_ride_driver INT;
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        SELECT r.driver_id, req.status 
        INTO v_ride_driver, v_status
        FROM RIDE_REQUEST req
        JOIN RIDE_POST r ON req.ride_id = r.ride_id
        WHERE req.request_id = p_request_id;

        IF v_ride_driver IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Request not found.';
        END IF;

        IF v_ride_driver <> p_driver_id THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Unauthorized. Only the driver can reject requests.';
        END IF;

        IF v_status <> 'PENDING' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Only pending requests can be rejected.';
        END IF;

        UPDATE RIDE_REQUEST SET status = 'REJECTED' WHERE request_id = p_request_id;
    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 5. START TRIP PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Transitions scheduled ride into an active live trip with recorded start time.
-- WHY: Establishes a 1:1 TRIP execution entity and locks the ride from further passenger edits.
CREATE PROCEDURE sp_start_trip(
    IN  p_ride_id INT,
    IN  p_driver_id INT,
    OUT p_trip_id INT
)
proc_label: BEGIN
    DECLARE v_vehicle_id INT;
    DECLARE v_ride_status VARCHAR(20);
    DECLARE v_fare DECIMAL(8, 2);
    DECLARE v_driver INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT driver_id, vehicle_id, status, estimated_fare
    INTO v_driver, v_vehicle_id, v_ride_status, v_fare
    FROM RIDE_POST
    WHERE ride_id = p_ride_id;

    IF v_driver <> p_driver_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Only the ride driver can start the trip.';
    END IF;

    IF v_ride_status NOT IN ('OPEN', 'FULL') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot start a ride that is already completed or cancelled.';
    END IF;

    START TRANSACTION;
        -- Create or update the TRIP record
        INSERT INTO TRIP (
            ride_id, driver_id, vehicle_id, start_time, distance_km, total_fare, fare_per_person, status
        ) VALUES (
            p_ride_id, p_driver_id, v_vehicle_id, NOW(), 0.00, v_fare, v_fare, 'IN_PROGRESS'
        )
        ON DUPLICATE KEY UPDATE 
            start_time = NOW(),
            status = 'IN_PROGRESS';

        SELECT trip_id INTO p_trip_id FROM TRIP WHERE ride_id = p_ride_id;
    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 6. COMPLETE TRIP & GENERATE PAYMENTS PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Concludes the trip, records final odometer distance, and generates pending payment records.
-- WHY: Ensures riders receive settlement statements and triggers the window for mutual ratings.
CREATE PROCEDURE sp_complete_trip(
    IN p_trip_id INT,
    IN p_driver_id INT,
    IN p_distance_km DECIMAL(6, 2)
)
proc_label: BEGIN
    DECLARE v_ride_id INT;
    DECLARE v_trip_driver INT;
    DECLARE v_trip_status VARCHAR(20);
    DECLARE v_accepted_riders INT DEFAULT 0;
    DECLARE v_fare_per_rider DECIMAL(8, 2);
    DECLARE v_total_fare DECIMAL(8, 2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT ride_id, driver_id, status, total_fare
    INTO v_ride_id, v_trip_driver, v_trip_status, v_total_fare
    FROM TRIP
    WHERE trip_id = p_trip_id;

    IF v_trip_driver IS NULL OR v_trip_driver <> p_driver_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Unauthorized. Only the assigned driver can complete this trip.';
    END IF;

    IF v_trip_status <> 'IN_PROGRESS' AND v_trip_status <> 'SCHEDULED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Trip is not currently in progress.';
    END IF;

    START TRANSACTION;
        -- Calculate total accepted passengers
        SELECT COUNT(*) INTO v_accepted_riders 
        FROM RIDE_REQUEST 
        WHERE ride_id = v_ride_id AND status = 'ACCEPTED';

        IF v_accepted_riders > 0 THEN
            SET v_fare_per_rider = fn_calculate_fare_share(v_total_fare, v_accepted_riders);
        ELSE
            SET v_fare_per_rider = v_total_fare;
        END IF;

        -- Update TRIP to COMPLETED with end timestamp and distance
        UPDATE TRIP
        SET end_time = NOW(),
            distance_km = p_distance_km,
            fare_per_person = v_fare_per_rider,
            status = 'COMPLETED'
        WHERE trip_id = p_trip_id;

        -- Mark RIDE_POST as COMPLETED
        UPDATE RIDE_POST
        SET status = 'COMPLETED'
        WHERE ride_id = v_ride_id;

        -- Insert pending payment records for all accepted riders who have not yet paid
        INSERT INTO PAYMENT (trip_id, rider_id, amount, method, status, transaction_reference)
        SELECT 
            p_trip_id,
            req.rider_id,
            v_fare_per_rider,
            'UPI',
            'PENDING',
            CONCAT('TXN-', p_trip_id, '-', req.rider_id, '-', UNIX_TIMESTAMP(NOW()))
        FROM RIDE_REQUEST req
        WHERE req.ride_id = v_ride_id 
          AND req.status = 'ACCEPTED'
          AND NOT EXISTS (
              SELECT 1 FROM PAYMENT p 
              WHERE p.trip_id = p_trip_id AND p.rider_id = req.rider_id
          );

    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 7. PROCESS PAYMENT PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Marks an outstanding trip payment settlement as COMPLETED with a transaction reference.
-- WHY: Finalizes passenger liability and confirms monetary transfer for audit reporting.
CREATE PROCEDURE sp_process_payment(
    IN p_payment_id INT,
    IN p_rider_id INT,
    IN p_method VARCHAR(20),
    IN p_reference VARCHAR(100)
)
proc_label: BEGIN
    DECLARE v_existing_rider INT;
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT rider_id, status INTO v_existing_rider, v_status
    FROM PAYMENT
    WHERE payment_id = p_payment_id;

    IF v_existing_rider IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Payment record not found.';
    END IF;

    IF v_existing_rider <> p_rider_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Unauthorized payment settlement attempt.';
    END IF;

    IF v_status = 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: This payment has already been settled.';
    END IF;

    START TRANSACTION;
        UPDATE PAYMENT
        SET status = 'COMPLETED',
            method = p_method,
            transaction_reference = p_reference,
            payment_time = NOW()
        WHERE payment_id = p_payment_id;
    COMMIT;
END //

-- ----------------------------------------------------------------------------
-- 8. SUBMIT RATING PROCEDURE
-- ----------------------------------------------------------------------------
-- WHAT: Allows trip participants (driver or passenger) to rate each other after a completed trip.
-- WHY: Guarantees ratings can only be filed once per party and only on completed journeys.
CREATE PROCEDURE sp_submit_rating(
    IN  p_trip_id INT,
    IN  p_rater_user_id INT,
    IN  p_ratee_user_id INT,
    IN  p_score TINYINT,
    IN  p_comment TEXT,
    OUT p_rating_id INT
)
proc_label: BEGIN
    DECLARE v_trip_status VARCHAR(20);
    DECLARE v_existing_rating INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Verification 1: Trip must be COMPLETED
    SELECT status INTO v_trip_status FROM TRIP WHERE trip_id = p_trip_id;
    IF v_trip_status IS NULL OR v_trip_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: You can only rate users after a trip is successfully completed.';
    END IF;

    -- Verification 2: Check for duplicate rating
    SELECT COUNT(*) INTO v_existing_rating 
    FROM RATING 
    WHERE trip_id = p_trip_id 
      AND rater_user_id = p_rater_user_id 
      AND ratee_user_id = p_ratee_user_id;

    IF v_existing_rating > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: You have already submitted a rating for this user on this trip.';
    END IF;

    -- Verification 3: Score bounds
    IF p_score < 1 OR p_score > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Rating score must be between 1 and 5.';
    END IF;

    START TRANSACTION;
        INSERT INTO RATING (trip_id, rater_user_id, ratee_user_id, score, comment)
        VALUES (p_trip_id, p_rater_user_id, p_ratee_user_id, p_score, p_comment);

        SET p_rating_id = LAST_INSERT_ID();
    COMMIT;
END //

DELIMITER ;
