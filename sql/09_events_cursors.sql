-- ============================================================================
-- 09_events_cursors.sql: Cursors and Scheduled Background Events
-- Demonstrates cursor iteration with handlers and MySQL Event Scheduler.
-- ============================================================================

USE campuspool;

-- WHAT: Enables the MySQL Event Scheduler background worker thread.
-- WHY: Required so that periodic scheduled events run autonomously without external cron jobs.
SET GLOBAL event_scheduler = ON;

DROP PROCEDURE IF EXISTS sp_dispatch_ride_reminders;
DROP EVENT IF EXISTS ev_expire_past_rides;

DELIMITER //

-- ----------------------------------------------------------------------------
-- 1. CURSOR PROCEDURE: DISPATCH RIDE REMINDERS
-- ----------------------------------------------------------------------------
-- WHAT: Uses an explicit SQL CURSOR to iterate over all upcoming rides departing in the next 12 hours.
-- WHY: Demonstrates row-by-row procedural processing, DECLARE CURSOR, OPEN, FETCH, and CONTINUE HANDLER FOR NOT FOUND.
CREATE PROCEDURE sp_dispatch_ride_reminders()
proc_label: BEGIN
    -- Cursor variables
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_ride_id INT;
    DECLARE v_rider_id INT;
    DECLARE v_departure_time DATETIME;
    DECLARE v_pickup_name VARCHAR(120);
    DECLARE v_driver_name VARCHAR(120);

    -- Declare cursor to scan upcoming confirmed bookings
    DECLARE cur_reminders CURSOR FOR
        SELECT 
            r.ride_id, 
            req.rider_id, 
            r.departure_time, 
            loc.name AS pickup_name,
            CONCAT(u.first_name, ' ', u.last_name) AS driver_name
        FROM RIDE_POST r
        JOIN RIDE_REQUEST req ON r.ride_id = req.ride_id AND req.status = 'ACCEPTED'
        JOIN LOCATION loc ON r.pickup_location_id = loc.location_id
        JOIN USER u ON r.driver_id = u.user_id
        WHERE r.status IN ('OPEN', 'FULL')
          AND r.departure_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);

    -- Cursor error/termination handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- Open the cursor and process rows
    OPEN cur_reminders;

    read_loop: LOOP
        FETCH cur_reminders INTO v_ride_id, v_rider_id, v_departure_time, v_pickup_name, v_driver_name;
        
        IF v_done THEN
            LEAVE read_loop;
        END IF;

        -- Insert a reminder notification for each passenger
        INSERT INTO NOTIFICATION (user_id, type, message)
        VALUES (
            v_rider_id,
            'REMINDER',
            CONCAT('Upcoming Ride Reminder: Your ride #', v_ride_id, ' with ', v_driver_name, ' departs from ', v_pickup_name, ' at ', DATE_FORMAT(v_departure_time, '%h:%i %p'))
        );
    END LOOP;

    -- Close the cursor to free MySQL server memory
    CLOSE cur_reminders;
END //

-- ----------------------------------------------------------------------------
-- 2. SCHEDULED EVENT: AUTO-EXPIRE PAST OPEN RIDES
-- ----------------------------------------------------------------------------
-- WHAT: Recurring MySQL Event running every hour to mark overdue unfilled rides as CANCELLED.
-- WHY: Automates database cleanup so riders never see departed or stale rides in the search catalog.
CREATE EVENT ev_expire_past_rides
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
COMMENT 'Auto-expires rides whose departure time has passed while still in OPEN status.'
DO
BEGIN
    UPDATE RIDE_POST
    SET status = 'CANCELLED'
    WHERE departure_time < NOW()
      AND status = 'OPEN';
END //

DELIMITER ;
