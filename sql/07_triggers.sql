-- ============================================================================
-- 07_triggers.sql: Reactive Database Triggers
-- Demonstrates Active Database Rules & Event-Condition-Action (ECA) Mechanics
-- Enforces integrity constraints, automated alerts, and audit logging.
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
DROP TRIGGER IF EXISTS trg_user_age_bi;
DROP TRIGGER IF EXISTS trg_user_age_bu;

DELIMITER //

-- ============================================================================
-- 1. DERIVED ATTRIBUTE: AUTO USER AGE (BEFORE INSERT & UPDATE)
-- Dynamically maintains the derived 'age' attribute from date_of_birth.
-- ============================================================================
CREATE TRIGGER trg_user_age_bi
BEFORE INSERT ON USER
FOR EACH ROW
BEGIN
    IF NEW.date_of_birth IS NOT NULL THEN
        SET NEW.age = TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE());
    END IF;
END //

CREATE TRIGGER trg_user_age_bu
BEFORE UPDATE ON USER
FOR EACH ROW
BEGIN
    IF NEW.date_of_birth IS NOT NULL THEN
        SET NEW.age = TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE());
    END IF;
END //

-- ============================================================================
-- 2. INTEGRITY RULE: PREVENT DRIVER FROM BOOKING OWN RIDE (BEFORE INSERT)
-- ============================================================================
CREATE TRIGGER trg_prevent_driver_self_request
BEFORE INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_driver_id INT;
    SELECT driver_id INTO v_driver_id FROM RIDE_POST WHERE ride_id = NEW.ride_id;
    
    IF v_driver_id IS NOT NULL AND v_driver_id = NEW.rider_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Error: Drivers cannot book seats on their own rides.';
    END IF;
END //

-- ============================================================================
-- 3. INTEGRITY RULE: PREVENT OVERBOOKING (BEFORE INSERT)
-- ============================================================================
CREATE TRIGGER trg_prevent_overbooking
BEFORE INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT seats_available INTO v_avail FROM RIDE_POST WHERE ride_id = NEW.ride_id;
    
    IF NEW.seats_requested > v_avail THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Error: Requested seats exceed currently available seats.';
    END IF;
END //

-- ============================================================================
-- 4. SELF-HEALING SEATS: RESTORE ON CANCELLATION (AFTER UPDATE)
-- ============================================================================
CREATE TRIGGER trg_restore_seats_on_cancel
AFTER UPDATE ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    IF OLD.status = 'ACCEPTED' AND NEW.status = 'CANCELLED' THEN
        UPDATE RIDE_POST
        SET seats_available = seats_available + OLD.seats_requested,
            status = 'OPEN'
        WHERE ride_id = NEW.ride_id;
    END IF;
END //

-- ============================================================================
-- 5. NOTIFICATION DISPATCH TO DRIVER ON REQUEST (AFTER INSERT)
-- ============================================================================
CREATE TRIGGER trg_notify_driver_on_request
AFTER INSERT ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    DECLARE v_driver_id INT;
    SELECT driver_id INTO v_driver_id FROM RIDE_POST WHERE ride_id = NEW.ride_id;
    
    IF v_driver_id IS NOT NULL THEN
        INSERT INTO NOTIFICATION (user_id, type, message)
        VALUES (v_driver_id, 'RIDE_REQUEST', CONCAT('New seat request received for ride #', NEW.ride_id));
    END IF;
END //

-- ============================================================================
-- 6. NOTIFICATION DISPATCH TO RIDER ON STATUS CHANGE (AFTER UPDATE)
-- ============================================================================
CREATE TRIGGER trg_notify_rider_on_status_change
AFTER UPDATE ON RIDE_REQUEST
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        IF NEW.status = 'ACCEPTED' THEN
            INSERT INTO NOTIFICATION (user_id, type, message)
            VALUES (NEW.rider_id, 'REQUEST_ACCEPTED', CONCAT('Your seat request for ride #', NEW.ride_id, ' was accepted!'));
        ELSEIF NEW.status = 'REJECTED' THEN
            INSERT INTO NOTIFICATION (user_id, type, message)
            VALUES (NEW.rider_id, 'REQUEST_REJECTED', CONCAT('Your seat request for ride #', NEW.ride_id, ' was declined.'));
        END IF;
    END IF;
END //

-- ============================================================================
-- 7. INTEGRITY RULE: BLOCK PREMATURE RATINGS (BEFORE INSERT)
-- ============================================================================
CREATE TRIGGER trg_block_uncompleted_trip_rating
BEFORE INSERT ON RATING
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM TRIP WHERE trip_id = NEW.trip_id;
    
    IF v_status IS NULL OR v_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Error: Ratings can only be submitted for COMPLETED trips.';
    END IF;
END //

-- ============================================================================
-- 8. DRIVER RATING RECALCULATION (AFTER INSERT)
-- Maintains pre-aggregated average_rating in DRIVER table.
-- ============================================================================
CREATE TRIGGER trg_update_driver_rating_after_insert
AFTER INSERT ON RATING
FOR EACH ROW
BEGIN
    DECLARE v_avg DECIMAL(3, 2);
    
    SELECT ROUND(AVG(score), 2) INTO v_avg 
    FROM RATING WHERE ratee_user_id = NEW.ratee_user_id;
    
    UPDATE DRIVER
    SET average_rating = COALESCE(v_avg, 5.00)
    WHERE user_id = NEW.ratee_user_id;
END //

-- ============================================================================
-- 9. AUDIT LOGGING TRIGGERS (AFTER UPDATE)
-- ============================================================================
CREATE TRIGGER trg_audit_ride_post_update
AFTER UPDATE ON RIDE_POST
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status OR OLD.seats_available <> NEW.seats_available THEN
        INSERT INTO AUDIT_LOG (table_name, action_type, record_id, changed_by_user_id, old_values, new_values)
        VALUES ('RIDE_POST', 'UPDATE', NEW.ride_id, NEW.driver_id,
                JSON_OBJECT('status', OLD.status, 'seats_available', OLD.seats_available),
                JSON_OBJECT('status', NEW.status, 'seats_available', NEW.seats_available));
    END IF;
END //

CREATE TRIGGER trg_audit_trip_update
AFTER UPDATE ON TRIP
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO AUDIT_LOG (table_name, action_type, record_id, changed_by_user_id, old_values, new_values)
        VALUES ('TRIP', 'UPDATE', NEW.trip_id, NEW.driver_id,
                JSON_OBJECT('status', OLD.status, 'end_time', OLD.end_time),
                JSON_OBJECT('status', NEW.status, 'end_time', NEW.end_time));
    END IF;
END //

DELIMITER ;

-- Initialize age for pre-existing records
UPDATE USER SET age = TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE());
