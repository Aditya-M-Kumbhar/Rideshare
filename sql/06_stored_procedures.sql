-- ============================================================================
-- 06_stored_procedures.sql: Core Transactional Procedures
-- Demonstrates Procedural Constructs in SQL (Database Concepts Ch. 4):
--   - IN / OUT Parameters
--   - ACID Transactions: START TRANSACTION, COMMIT, ROLLBACK
--   - Concurrency Control: SELECT ... FOR UPDATE (Pessimistic Locking)
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

-- ============================================================================
-- 1. CREATE RIDE PROCEDURE
-- Inserts a new ride post with seats offered and initial seats available.
-- ============================================================================
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
BEGIN
    IF p_departure_time <= NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Departure time must be set in the future.';
    END IF;

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
END //

-- ============================================================================
-- 2. REQUEST SEAT PROCEDURE
-- Records a passenger booking request and calculates their fare share.
-- ============================================================================
CREATE PROCEDURE sp_request_seat(
    IN  p_ride_id INT,
    IN  p_rider_id INT,
    IN  p_seats_requested INT,
    IN  p_message VARCHAR(255),
    OUT p_request_id INT
)
BEGIN
    DECLARE v_fare DECIMAL(8, 2);

    -- Calculate fare share per passenger using stored function
    SELECT fn_calculate_fare_share(estimated_fare, 1) * p_seats_requested
    INTO v_fare
    FROM RIDE_POST WHERE ride_id = p_ride_id;

    INSERT INTO RIDE_REQUEST (
        ride_id, rider_id, seats_requested, message, fare_share, status
    ) VALUES (
        p_ride_id, p_rider_id, p_seats_requested, p_message, COALESCE(v_fare, 50.00), 'PENDING'
    );

    SET p_request_id = LAST_INSERT_ID();
END //

-- ============================================================================
-- 3. ACCEPT REQUEST PROCEDURE (Pessimistic Concurrency Control)
-- Uses SELECT ... FOR UPDATE to lock the ride row and safely deduct seats.
-- ============================================================================
CREATE PROCEDURE sp_accept_request(
    IN p_request_id INT,
    IN p_driver_id INT
)
BEGIN
    DECLARE v_ride_id INT;
    DECLARE v_seats INT;

    START TRANSACTION;
        -- Retrieve request details
        SELECT ride_id, seats_requested INTO v_ride_id, v_seats
        FROM RIDE_REQUEST WHERE request_id = p_request_id;

        -- Concurrency lock: Exclusive row lock on RIDE_POST
        SELECT seats_available FROM RIDE_POST 
        WHERE ride_id = v_ride_id FOR UPDATE;

        -- Mark request as ACCEPTED
        UPDATE RIDE_REQUEST SET status = 'ACCEPTED' WHERE request_id = p_request_id;

        -- Deduct seats and mark FULL if no seats remain
        UPDATE RIDE_POST
        SET seats_available = seats_available - v_seats,
            status = CASE WHEN (seats_available - v_seats) <= 0 THEN 'FULL' ELSE status END
        WHERE ride_id = v_ride_id;
    COMMIT;
END //

-- ============================================================================
-- 4. REJECT REQUEST PROCEDURE
-- ============================================================================
CREATE PROCEDURE sp_reject_request(
    IN p_request_id INT,
    IN p_driver_id INT
)
BEGIN
    UPDATE RIDE_REQUEST SET status = 'REJECTED' WHERE request_id = p_request_id;
END //

-- ============================================================================
-- 5. START TRIP PROCEDURE
-- Transitions scheduled ride into an active live trip.
-- ============================================================================
CREATE PROCEDURE sp_start_trip(
    IN  p_ride_id INT,
    IN  p_driver_id INT,
    OUT p_trip_id INT
)
BEGIN
    DECLARE v_veh_id INT;
    DECLARE v_fare DECIMAL(8, 2);

    SELECT vehicle_id, estimated_fare INTO v_veh_id, v_fare
    FROM RIDE_POST WHERE ride_id = p_ride_id;

    INSERT INTO TRIP (ride_id, driver_id, vehicle_id, start_time, distance_km, total_fare, fare_per_person, status)
    VALUES (p_ride_id, p_driver_id, v_veh_id, NOW(), 0.00, v_fare, v_fare, 'IN_PROGRESS')
    ON DUPLICATE KEY UPDATE start_time = NOW(), status = 'IN_PROGRESS';

    SELECT trip_id INTO p_trip_id FROM TRIP WHERE ride_id = p_ride_id;
END //

-- ============================================================================
-- 6. COMPLETE TRIP & GENERATE PAYMENTS PROCEDURE
-- Marks trip and ride completed, and inserts payment settlement records.
-- ============================================================================
CREATE PROCEDURE sp_complete_trip(
    IN p_trip_id INT,
    IN p_driver_id INT,
    IN p_distance_km DECIMAL(6, 2)
)
BEGIN
    DECLARE v_ride_id INT;
    DECLARE v_riders INT DEFAULT 1;
    DECLARE v_share DECIMAL(8, 2);

    SELECT ride_id INTO v_ride_id FROM TRIP WHERE trip_id = p_trip_id;

    -- Count accepted passengers
    SELECT COUNT(*) INTO v_riders 
    FROM RIDE_REQUEST WHERE ride_id = v_ride_id AND status = 'ACCEPTED';
    SET v_riders = GREATEST(v_riders, 1);

    -- Calculate per-passenger split cost
    SELECT fn_calculate_fare_share(total_fare, v_riders) INTO v_share
    FROM TRIP WHERE trip_id = p_trip_id;

    START TRANSACTION;
        UPDATE TRIP 
        SET end_time = NOW(), distance_km = p_distance_km, fare_per_person = v_share, status = 'COMPLETED'
        WHERE trip_id = p_trip_id;

        UPDATE RIDE_POST SET status = 'COMPLETED' WHERE ride_id = v_ride_id;

        -- Insert pending payment records for accepted riders (Insert with Subquery - Slide 3.53)
        INSERT INTO PAYMENT (trip_id, rider_id, amount, method, status, transaction_reference)
        SELECT p_trip_id, req.rider_id, v_share, 'UPI', 'PENDING',
               CONCAT('TXN-', p_trip_id, '-', req.rider_id, '-', UNIX_TIMESTAMP(NOW()))
        FROM RIDE_REQUEST req
        WHERE req.ride_id = v_ride_id AND req.status = 'ACCEPTED'
          AND NOT EXISTS (SELECT 1 FROM PAYMENT p WHERE p.trip_id = p_trip_id AND p.rider_id = req.rider_id);
    COMMIT;
END //

-- ============================================================================
-- 7. PROCESS PAYMENT PROCEDURE
-- Marks payment completed with payment method and transaction ID.
-- ============================================================================
CREATE PROCEDURE sp_process_payment(
    IN p_payment_id INT,
    IN p_rider_id INT,
    IN p_method VARCHAR(20),
    IN p_reference VARCHAR(100)
)
BEGIN
    UPDATE PAYMENT
    SET status = 'COMPLETED', method = p_method, transaction_reference = p_reference, payment_time = NOW()
    WHERE payment_id = p_payment_id;
END //

-- ============================================================================
-- 8. SUBMIT RATING PROCEDURE
-- Stores a mutual peer review score (1 to 5) and feedback comment.
-- ============================================================================
CREATE PROCEDURE sp_submit_rating(
    IN  p_trip_id INT,
    IN  p_rater_user_id INT,
    IN  p_ratee_user_id INT,
    IN  p_score TINYINT,
    IN  p_comment TEXT,
    OUT p_rating_id INT
)
BEGIN
    INSERT INTO RATING (trip_id, rater_user_id, ratee_user_id, score, comment)
    VALUES (p_trip_id, p_rater_user_id, p_ratee_user_id, p_score, p_comment);

    SET p_rating_id = LAST_INSERT_ID();
END //

DELIMITER ;
