-- ============================================================================
-- 07_triggers.sql: Reactive Database Triggers
-- Enforces integrity rules, seat management, driver rating recalculation,
-- automated notifications, and audit log generation directly in the DBMS.
-- ============================================================================

USE campuspool;

DROP TRIGGER IF EXISTS trg_prevent_driver_self_request;
DROP TRIGGER IF EXISTS trg_prevent_overbooking;
DROP TRIGGER IF EXISTS trg_restore_seats_on_cancel;
DROP TRIGGER IF EXISTS trg_notify_driver_on_request;
DROP TRIGGER IF EXISTS trg_notify_rider_on_status_change;
DROP TRIGGER IF EXISTS trg_block_uncompleted_trip_rating;
DROP TRIGGER IF EXISTS trg_update_driver_rating_after_insert;
DROP TRIGGER IF EXISTS trg_audit_ride_post_update;
DROP TRIGGER IF EXISTS trg_audit_trip_update;

DELIMITER //

-- ----------------------------------------------------------------------------
-- 1. PREVENT DRIVER FROM REQUESTING OWN RIDE (BEFORE INSERT)
-- ----------------------------------------------------------------------------
-- WHAT: Rejects any ride request where the rider_id matches the ride's driver_id.
-- WHY: Hard database-level safeguard preventing drivers from gaming seat counts or ratings on their own rides.
CREATE TRIGGER trg_prevent_driver_self_request
BEFORE INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_driver_id INT;
    
    SELECT driver_id INTO v_driver_id 
    FROM RIDE_POST 
    WHERE ride_id = NEW.ride_id;
    
    IF v_driver_id IS NOT NULL AND v_driver_id = NEW.rider_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Violation: Drivers are strictly prohibited from booking seats on their own rides.';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 2. PREVENT OVERBOOKING ON REQUEST INSERTION (BEFORE INSERT)
-- ----------------------------------------------------------------------------
-- WHAT: Validates that the requested seat count does not exceed current seats_available.
-- WHY: Stops oversaturated requests at the front door before any write commit.
CREATE TRIGGER trg_prevent_overbooking
BEFORE INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    DECLARE v_status VARCHAR(20);
    
    SELECT seats_available, status INTO v_avail, v_status
    FROM RIDE_POST
    WHERE ride_id = NEW.ride_id;
    
    IF v_status <> 'OPEN' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Violation: Cannot submit requests for rides that are not currently OPEN.';
    END IF;
    
    IF NEW.seats_requested > v_avail THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Violation: Requested seats exceed available seats on this ride.';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 3. RESTORE SEATS ON CANCELLATION (AFTER UPDATE)
-- ----------------------------------------------------------------------------
-- WHAT: Restores available seats to the ride post when an ACCEPTED request is CANCELLED.
-- WHY: Keeps seat inventory self-healing without requiring client applications to manually add seats back.
CREATE TRIGGER trg_restore_seats_on_cancel
AFTER UPDATE ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    -- If a previously ACCEPTED request is now CANCELLED
    IF OLD.status = 'ACCEPTED' AND NEW.status = 'CANCELLED' THEN
        UPDATE RIDE_POST
        SET seats_available = seats_available + OLD.seats_requested,
            status = 'OPEN'
        WHERE ride_id = NEW.ride_id;
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 4. DISPATCH NOTIFICATION TO DRIVER (AFTER INSERT)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts an automated alert into NOTIFICATION for the driver when a rider requests a seat.
-- WHY: Triggers real-time alerts automatically at the DBMS layer as soon as a request row is inserted.
CREATE TRIGGER trg_notify_driver_on_request
AFTER INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_driver_id INT;
    DECLARE v_rider_name VARCHAR(120);
    
    SELECT driver_id INTO v_driver_id FROM RIDE_POST WHERE ride_id = NEW.ride_id;
    SELECT CONCAT(first_name, ' ', last_name) INTO v_rider_name FROM USER WHERE user_id = NEW.rider_id;
    
    IF v_driver_id IS NOT NULL THEN
        INSERT INTO NOTIFICATION (user_id, type, message)
        VALUES (
            v_driver_id, 
            'RIDE_REQUEST', 
            CONCAT(COALESCE(v_rider_name, 'A student'), ' requested ', NEW.seats_requested, ' seat(s) on your ride #', NEW.ride_id)
        );
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 5. DISPATCH NOTIFICATION TO RIDER ON STATUS CHANGE (AFTER UPDATE)
-- ----------------------------------------------------------------------------
-- WHAT: Generates a notification for the rider whenever their booking request is ACCEPTED or REJECTED.
-- WHY: Keeps students informed of their carpool status without extra application middleware logic.
CREATE TRIGGER trg_notify_rider_on_status_change
AFTER UPDATE ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        IF NEW.status = 'ACCEPTED' THEN
            INSERT INTO NOTIFICATION (user_id, type, message)
            VALUES (
                NEW.rider_id, 
                'REQUEST_ACCEPTED', 
                CONCAT('Great news! Your seat request for ride #', NEW.ride_id, ' was accepted by the driver.')
            );
        ELSEIF NEW.status = 'REJECTED' THEN
            INSERT INTO NOTIFICATION (user_id, type, message)
            VALUES (
                NEW.rider_id, 
                'REQUEST_REJECTED', 
                CONCAT('Notice: Your seat request for ride #', NEW.ride_id, ' was declined.')
            );
        END IF;
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 6. BLOCK RATINGS FOR INCOMPLETE TRIPS (BEFORE INSERT)
-- ----------------------------------------------------------------------------
-- WHAT: Rejects rating insertion if the referenced trip is not in 'COMPLETED' status.
-- WHY: Protects driver/rider reputation metrics from premature reviews on active or scheduled rides.
CREATE TRIGGER trg_block_uncompleted_trip_rating
BEFORE INSERT ON RATING
FOR EACH ROW
BEGIN
    DECLARE v_trip_status VARCHAR(20);
    
    SELECT status INTO v_trip_status 
    FROM TRIP 
    WHERE trip_id = NEW.trip_id;
    
    IF v_trip_status IS NULL OR v_trip_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Violation: Ratings can only be submitted for COMPLETED trips.';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 7. RECALCULATE DRIVER AVERAGE RATING (AFTER INSERT)
-- ----------------------------------------------------------------------------
-- WHAT: Recomputes and updates the driver's average_rating column after each new review.
-- WHY: Maintains a pre-aggregated rating cache in DRIVER for lightning-fast search queries.
CREATE TRIGGER trg_update_driver_rating_after_insert
AFTER INSERT ON RATING
FOR EACH ROW
BEGIN
    DECLARE v_new_avg DECIMAL(3, 2);
    DECLARE v_is_driver INT;
    
    -- Check if ratee is a driver
    SELECT COUNT(*) INTO v_is_driver FROM DRIVER WHERE user_id = NEW.ratee_user_id;
    
    IF v_is_driver > 0 THEN
        SELECT ROUND(AVG(score), 2) INTO v_new_avg
        FROM RATING
        WHERE ratee_user_id = NEW.ratee_user_id;
        
        UPDATE DRIVER
        SET average_rating = COALESCE(v_new_avg, 5.00)
        WHERE user_id = NEW.ratee_user_id;
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 8. AUDIT LOG ON RIDE POST UPDATE (AFTER UPDATE)
-- ----------------------------------------------------------------------------
-- WHAT: Captures status and seat count modifications on RIDE_POST into the AUDIT_LOG table.
-- WHY: Provides immutable change history and forensic traceability for all ride alterations.
CREATE TRIGGER trg_audit_ride_post_update
AFTER UPDATE ON RIDE_POST
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status OR OLD.seats_available <> NEW.seats_available THEN
        INSERT INTO AUDIT_LOG (
            table_name, action_type, record_id, changed_by_user_id, old_values, new_values
        ) VALUES (
            'RIDE_POST',
            'UPDATE',
            NEW.ride_id,
            NEW.driver_id,
            JSON_OBJECT('status', OLD.status, 'seats_available', OLD.seats_available, 'seats_offered', OLD.seats_offered),
            JSON_OBJECT('status', NEW.status, 'seats_available', NEW.seats_available, 'seats_offered', NEW.seats_offered)
        );
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 9. AUDIT LOG ON TRIP STATUS UPDATE (AFTER UPDATE)
-- ----------------------------------------------------------------------------
-- WHAT: Captures trip start, completion, and fare changes into the AUDIT_LOG table.
-- WHY: Guarantees full compliance tracking of monetary and operational status shifts.
CREATE TRIGGER trg_audit_trip_update
AFTER UPDATE ON TRIP
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO AUDIT_LOG (
            table_name, action_type, record_id, changed_by_user_id, old_values, new_values
        ) VALUES (
            'TRIP',
            'UPDATE',
            NEW.trip_id,
            NEW.driver_id,
            JSON_OBJECT('status', OLD.status, 'distance_km', OLD.distance_km, 'end_time', OLD.end_time),
            JSON_OBJECT('status', NEW.status, 'distance_km', NEW.distance_km, 'end_time', NEW.end_time)
        );
    END IF;
END //

DELIMITER ;
