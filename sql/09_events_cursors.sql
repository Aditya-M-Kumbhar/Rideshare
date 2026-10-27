-- ============================================================================
-- 09_events_cursors.sql: Cursors & Scheduled Database Events
-- Demonstrates Procedural Extensions in SQL (Database Concepts Ch. 4):
--   1. Explicit SQL Cursor: DECLARE CURSOR, OPEN, FETCH, CLOSE, and NOT FOUND handler
--   2. MySQL Event Scheduler: Periodic background maintenance
-- ============================================================================

USE campuspool;

-- Enable the Event Scheduler worker thread
SET GLOBAL event_scheduler = ON;

DROP PROCEDURE IF EXISTS sp_dispatch_ride_reminders;
DROP EVENT IF EXISTS ev_expire_past_rides;

DELIMITER //

-- ============================================================================
-- 1. CURSOR PROCEDURE: DISPATCH RIDE REMINDERS
-- Uses an explicit cursor to iterate row-by-row over upcoming rides.
-- ============================================================================
CREATE PROCEDURE sp_dispatch_ride_reminders()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_ride_id INT;
    DECLARE v_rider_id INT;
    DECLARE v_departure_time DATETIME;

    -- Declare cursor for accepted passenger bookings
    DECLARE cur_reminders CURSOR FOR
        SELECT r.ride_id, req.rider_id, r.departure_time
        FROM RIDE_POST r
        JOIN RIDE_REQUEST req ON r.ride_id = req.ride_id AND req.status = 'ACCEPTED'
        WHERE r.status IN ('OPEN', 'FULL')
          AND r.departure_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);

    -- Cursor completion handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur_reminders;

    read_loop: LOOP
        FETCH cur_reminders INTO v_ride_id, v_rider_id, v_departure_time;
        IF v_done THEN
            LEAVE read_loop;
        END IF;

        -- Dispatch automated reminder notification
        INSERT INTO NOTIFICATION (user_id, type, message)
        VALUES (v_rider_id, 'REMINDER', CONCAT('Reminder: Your ride #', v_ride_id, ' departs within 24 hours!'));
    END LOOP;

    CLOSE cur_reminders;
END //

-- ============================================================================
-- 2. SCHEDULED EVENT: EXPIRE PAST OPEN RIDES
-- Automatically runs every 1 hour to cancel overdue unfilled rides.
-- ============================================================================
CREATE EVENT ev_expire_past_rides
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE RIDE_POST
    SET status = 'CANCELLED'
    WHERE departure_time < NOW() AND status = 'OPEN';
END //

DELIMITER ;
