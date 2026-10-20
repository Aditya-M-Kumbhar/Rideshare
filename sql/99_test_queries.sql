-- ============================================================================
-- 99_test_queries.sql: Examiner Demonstration Suite (Viva Ready)
-- Every query is labeled with the exact DBMS concept, practical WHY explanation,
-- and executable SQL that can be run individually in MySQL Workbench or terminal.
-- ============================================================================

USE campuspool;

-- ============================================================================
-- CONCEPT 1: DDL CONSTRAINTS & COMPOSITE INDEX EXPLAIN PLAN
-- ============================================================================
-- WHAT: Demonstrates index optimization using EXPLAIN on the multi-column search query.
-- WHY: Proves that composite index idx_rides_search_composite avoids a full table scan.
EXPLAIN 
SELECT ride_id, departure_time, seats_available, estimated_fare
FROM RIDE_POST
WHERE status = 'OPEN' 
  AND departure_time >= NOW()
  AND pickup_location_id = 10 
  AND destination_location_id = 1;


-- ============================================================================
-- CONCEPT 2: DML DATA VOLUME & SEED AUDIT
-- ============================================================================
-- WHAT: Aggregates record counts across all core tables in a single diagnostic output.
-- WHY: Proves that the database satisfies seed data quotas (15+ users, 10+ vehicles, 25+ rides, etc.).
SELECT 'USER' AS entity, COUNT(*) AS total_records FROM USER
UNION ALL
SELECT 'COLLEGE', COUNT(*) FROM COLLEGE
UNION ALL
SELECT 'COMMUNITY', COUNT(*) FROM COMMUNITY
UNION ALL
SELECT 'VEHICLE', COUNT(*) FROM VEHICLE
UNION ALL
SELECT 'LOCATION', COUNT(*) FROM LOCATION
UNION ALL
SELECT 'RIDE_POST', COUNT(*) FROM RIDE_POST
UNION ALL
SELECT 'RIDE_REQUEST', COUNT(*) FROM RIDE_REQUEST
UNION ALL
SELECT 'TRIP', COUNT(*) FROM TRIP
UNION ALL
SELECT 'PAYMENT', COUNT(*) FROM PAYMENT
UNION ALL
SELECT 'RATING', COUNT(*) FROM RATING;


-- ============================================================================
-- CONCEPT 3A: INNER JOIN & MULTI-TABLE ROUTE MAPPING
-- ============================================================================
-- WHAT: Joins 5 tables (RIDE_POST, USER, VEHICLE, LOCATION pickup, LOCATION destination).
-- WHY: Resolves foreign keys to generate a human-readable trip itinerary for rider search.
SELECT 
    r.ride_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    v.plate_no,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    loc_from.name AS pickup_location,
    loc_to.name AS destination_location,
    r.departure_time,
    r.seats_available,
    r.estimated_fare
FROM RIDE_POST r
INNER JOIN USER u ON r.driver_id = u.user_id
INNER JOIN VEHICLE v ON r.vehicle_id = v.vehicle_id
INNER JOIN LOCATION loc_from ON r.pickup_location_id = loc_from.location_id
INNER JOIN LOCATION loc_to ON r.destination_location_id = loc_to.location_id
WHERE r.status = 'OPEN';


-- ============================================================================
-- CONCEPT 3B: LEFT OUTER JOIN (STUDENT SPECIALIZATION AUDIT)
-- ============================================================================
-- WHAT: Returns every user in the system along with their college if enrolled as a student.
-- WHY: Proves that non-student drivers or staff still appear in the result set with NULL college info.
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    u.email,
    s.roll_no,
    COALESCE(c.name, 'Non-Student / General User') AS college_affiliation
FROM USER u
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
ORDER BY u.user_id;


-- ============================================================================
-- CONCEPT 3C: RIGHT OUTER JOIN (CAMPUS PARTICIPATION)
-- ============================================================================
-- WHAT: Returns all registered colleges and any student users affiliated with them.
-- WHY: Ensures colleges with zero registered students are still retained in administrative reports.
SELECT 
    c.name AS college_name,
    c.city,
    COUNT(s.user_id) AS enrolled_students_in_system
FROM STUDENT s
RIGHT JOIN COLLEGE c ON s.college_id = c.college_id
GROUP BY c.college_id, c.name, c.city;


-- ============================================================================
-- CONCEPT 3D: SELF JOIN (PEER COMMUTER MATCHING)
-- ============================================================================
-- WHAT: Joins STUDENT to itself to find pairs of students attending the same college in the same year.
-- WHY: Identifies natural batchmates who can form recurring daily carpool groups.
SELECT 
    s1.year AS academic_year,
    c.name AS college_name,
    CONCAT(u1.first_name, ' ', u1.last_name) AS student_1,
    CONCAT(u2.first_name, ' ', u2.last_name) AS student_2
FROM STUDENT s1
JOIN STUDENT s2 ON s1.college_id = s2.college_id 
               AND s1.year = s2.year 
               AND s1.user_id < s2.user_id
JOIN USER u1 ON s1.user_id = u1.user_id
JOIN USER u2 ON s2.user_id = u2.user_id
JOIN COLLEGE c ON s1.college_id = c.college_id
ORDER BY s1.year, c.name;


-- ============================================================================
-- CONCEPT 4A: SUBQUERY WITH EXISTS (ACTIVE RIDERS)
-- ============================================================================
-- WHAT: Finds users who currently have at least one PENDING booking request.
-- WHY: Demonstrates correlated subquery optimization using the EXISTS predicate.
SELECT u.user_id, CONCAT(u.first_name, ' ', u.last_name) AS rider_name, u.email
FROM USER u
WHERE EXISTS (
    SELECT 1 
    FROM RIDE_REQUEST req
    WHERE req.rider_id = u.user_id 
      AND req.status = 'PENDING'
);


-- ============================================================================
-- CONCEPT 4B: SUBQUERY WITH NOT EXISTS (ZERO-COMPLAINT DRIVERS)
-- ============================================================================
-- WHAT: Selects drivers who have driven completed trips but NEVER received a rating below 5 stars.
-- WHY: Demonstrates correlated subquery filtering for pristine driver safety records.
SELECT 
    d.user_id AS driver_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    d.average_rating
FROM DRIVER d
JOIN USER u ON d.user_id = u.user_id
WHERE EXISTS (
    SELECT 1 FROM TRIP t WHERE t.driver_id = d.user_id AND t.status = 'COMPLETED'
)
AND NOT EXISTS (
    SELECT 1 FROM RATING r 
    JOIN TRIP t2 ON r.trip_id = t2.trip_id 
    WHERE r.ratee_user_id = d.user_id AND r.score < 5
);


-- ============================================================================
-- CONCEPT 4C: SUBQUERY WITH > ALL (ABOVE-AVERAGE FARE RIDES)
-- ============================================================================
-- WHAT: Finds rides whose estimated fare is strictly greater than ALL rides in Community 4.
-- WHY: Demonstrates SQL multi-value comparison predicate '> ALL'.
SELECT 
    ride_id, 
    driver_id, 
    estimated_fare, 
    notes
FROM RIDE_POST
WHERE estimated_fare > ALL (
    SELECT estimated_fare 
    FROM RIDE_POST 
    WHERE community_id = 4
);


-- ============================================================================
-- CONCEPT 5A: AGGREGATION WITH GROUP BY & HAVING
-- ============================================================================
-- WHAT: Groups completed trips by driver and filters for drivers with total distance > 10 km.
-- WHY: Enforces post-aggregation filtering via the HAVING clause.
SELECT 
    d.user_id AS driver_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    COUNT(t.trip_id) AS total_trips,
    ROUND(SUM(t.distance_km), 2) AS cumulative_distance_km,
    ROUND(AVG(t.duration_minutes), 1) AS avg_duration_mins
FROM TRIP t
JOIN DRIVER d ON t.driver_id = d.user_id
JOIN USER u ON d.user_id = u.user_id
WHERE t.status = 'COMPLETED'
GROUP BY d.user_id, u.first_name, u.last_name
HAVING cumulative_distance_km > 10.00
ORDER BY cumulative_distance_km DESC;


-- ============================================================================
-- CONCEPT 5B: ADVANCED GROUP BY WITH ROLLUP
-- ============================================================================
-- WHAT: Computes multi-level hierarchical sub-totals across vehicle types and driver colleges.
-- WHY: Demonstrates OLAP subtotal generation directly in MySQL with WITH ROLLUP.
SELECT 
    COALESCE(c.name, 'ALL COLLEGES (TOTAL)') AS college_name,
    COALESCE(v.vehicle_type, 'SUBTOTAL') AS vehicle_type,
    COUNT(t.trip_id) AS completed_trips,
    ROUND(SUM(t.total_fare), 2) AS total_revenue_generated
FROM TRIP t
JOIN VEHICLE v ON t.vehicle_id = v.vehicle_id
JOIN USER u ON t.driver_id = u.user_id
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
WHERE t.status = 'COMPLETED'
GROUP BY c.name, v.vehicle_type WITH ROLLUP;


-- ============================================================================
-- CONCEPT 6A: WINDOW FUNCTION - DENSE_RANK()
-- ============================================================================
-- WHAT: Ranks drivers across the university based on their average rating and trip count.
-- WHY: Demonstrates analytical window ranking functions over partitioned partitions.
SELECT 
    d.user_id AS driver_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    c.name AS college_name,
    d.average_rating,
    COUNT(t.trip_id) AS trips_driven,
    DENSE_RANK() OVER (
        ORDER BY d.average_rating DESC, COUNT(t.trip_id) DESC
    ) AS campus_rank
FROM DRIVER d
JOIN USER u ON d.user_id = u.user_id
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
LEFT JOIN TRIP t ON d.user_id = t.driver_id AND t.status = 'COMPLETED'
GROUP BY d.user_id, u.first_name, u.last_name, c.name, d.average_rating;


-- ============================================================================
-- CONCEPT 6B: WINDOW FUNCTION - RUNNING TOTAL (CUMULATIVE SAVINGS)
-- ============================================================================
-- WHAT: Calculates running total of carpool fare collected day by day.
-- WHY: Demonstrates SUM() OVER (ORDER BY ...) running window accumulation.
SELECT 
    payment_id,
    payment_time,
    amount,
    method,
    SUM(amount) OVER (
        ORDER BY payment_time, payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_platform_volume
FROM PAYMENT
WHERE status = 'COMPLETED'
ORDER BY payment_time;


-- ============================================================================
-- CONCEPT 6C: WINDOW FUNCTION - ROW_NUMBER()
-- ============================================================================
-- WHAT: Finds the single most recent trip completed by each driver.
-- WHY: Demonstrates row ranking with ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...).
WITH RankedTrips AS (
    SELECT 
        t.trip_id,
        t.driver_id,
        CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
        t.end_time,
        t.distance_km,
        ROW_NUMBER() OVER (
            PARTITION BY t.driver_id 
            ORDER BY t.end_time DESC
        ) AS rn
    FROM TRIP t
    JOIN USER u ON t.driver_id = u.user_id
    WHERE t.status = 'COMPLETED'
)
SELECT trip_id, driver_id, driver_name, end_time AS latest_trip_completed, distance_km
FROM RankedTrips
WHERE rn = 1;


-- ============================================================================
-- CONCEPT 7A: COMMON TABLE EXPRESSION (CTE) - ROUTE POPULARITY
-- ============================================================================
-- WHAT: Computes top origin-destination pairs with average savings.
-- WHY: Improves SQL readability by isolating intermediate aggregations.
WITH RouteMetrics AS (
    SELECT 
        loc_from.name AS pickup,
        loc_to.name AS destination,
        COUNT(r.ride_id) AS total_rides_offered,
        ROUND(AVG(r.estimated_fare), 2) AS avg_fare
    FROM RIDE_POST r
    JOIN LOCATION loc_from ON r.pickup_location_id = loc_from.location_id
    JOIN LOCATION loc_to ON r.destination_location_id = loc_to.location_id
    GROUP BY loc_from.name, loc_to.name
)
SELECT pickup, destination, total_rides_offered, avg_fare
FROM RouteMetrics
WHERE total_rides_offered >= 1
ORDER BY total_rides_offered DESC;


-- ============================================================================
-- CONCEPT 7B: RECURSIVE CTE (WAYPOINT ITINERARY PATH TRAVERSAL)
-- ============================================================================
-- WHAT: Recursively stitches together sequence stops for Ride #1 into an ordered path string.
-- WHY: Demonstrates RECURSIVE CTE syntax in MySQL 8 for hierarchical and sequential graph structures.
WITH RECURSIVE StopHierarchy AS (
    -- Anchor member: First pickup stop (sequence_no = 1)
    SELECT 
        s.ride_id,
        s.sequence_no,
        loc.name AS current_stop,
        CAST(loc.name AS CHAR(500)) AS itinerary_path
    FROM RIDE_STOP s
    JOIN LOCATION loc ON s.location_id = loc.location_id
    WHERE s.ride_id = 1 AND s.sequence_no = 1

    UNION ALL

    -- Recursive member: Appends subsequent stops in sequence order
    SELECT 
        s2.ride_id,
        s2.sequence_no,
        loc2.name AS current_stop,
        CONCAT(sh.itinerary_path, ' -> ', loc2.name)
    FROM RIDE_STOP s2
    JOIN LOCATION loc2 ON s2.location_id = loc2.location_id
    JOIN StopHierarchy sh ON s2.ride_id = sh.ride_id AND s2.sequence_no = sh.sequence_no + 1
)
SELECT ride_id, sequence_no, current_stop, itinerary_path
FROM StopHierarchy
ORDER BY sequence_no;


-- ============================================================================
-- CONCEPT 8: VIEWS - MASKED PRIVACY CATALOG & UPDATABLE VIEW
-- ============================================================================
-- WHAT: Demonstrates masked student PII and shows an updatable view in action.
-- WHY: Proves compliance with GDPR/DPDP data privacy guidelines and tests view updatability.
SELECT user_id, first_name, last_initial, masked_email, masked_phone, masked_license, masked_roll_no, driver_rating
FROM vw_masked_users
LIMIT 5;

-- Test of Updatable View:
-- UPDATE vw_updatable_emergency_contact SET phone = '9822099901' WHERE user_id = 1 AND contact_no = 1;


-- ============================================================================
-- CONCEPT 9: STORED FUNCTIONS
-- ============================================================================
-- WHAT: Executes custom database functions: fn_mask_id, fn_distance_km, fn_calculate_fare_share.
-- WHY: Shows that geometric, string sanitization, and pricing rules run inside the DBMS engine.
SELECT 
    fn_mask_id('MH12AB1234', 4, 2) AS masked_license_plate,
    fn_distance_km(18.5293, 73.8566, 18.5913, 73.7389) AS coep_to_hinjewadi_km,
    fn_calculate_fare_share(180.00, 3) AS fare_share_for_3_riders,
    fn_rating_badge(4.90) AS driver_badge;


-- ============================================================================
-- CONCEPT 10: TRIGGER ENFORCEMENT & INTEGRITY PROTECTION
-- ============================================================================
-- WHAT: Attempts an illegal insert where a driver books a seat on their own ride.
-- WHY: Demonstrates that DBMS triggers intercept and block illegal actions with custom SQLSTATE 45000.
-- Note: Running this statement will produce an intentional error message:
/*
INSERT INTO RIDE_REQUEST (ride_id, rider_id, seats_requested, message, fare_share)
VALUES (1, 1, 1, 'Attempting self-booking', 50.00);
-- Result: Trigger Violation: Drivers are strictly prohibited from booking seats on their own rides.
*/


-- ============================================================================
-- CONCEPT 11: AUDIT TRAIL LOGGING
-- ============================================================================
-- WHAT: Queries AUDIT_LOG to view automated BEFORE/AFTER snapshots recorded by triggers.
-- WHY: Proves non-repudiation and enterprise change auditing.
SELECT log_id, table_name, action_type, record_id, old_values, new_values, changed_at
FROM AUDIT_LOG
ORDER BY log_id DESC
LIMIT 5;


-- ============================================================================
-- CONCEPT 12: CURSORS & BATCH PROCESSING
-- ============================================================================
-- WHAT: Executes sp_dispatch_ride_reminders to demonstrate cursor iteration.
-- WHY: Shows cursor traversal and verification in the NOTIFICATION table.
CALL sp_dispatch_ride_reminders();
SELECT notification_id, user_id, type, message, sent_at
FROM NOTIFICATION
WHERE type = 'REMINDER'
ORDER BY notification_id DESC
LIMIT 5;


-- ============================================================================
-- CONCEPT 13: MYSQL EVENT SCHEDULER INSPECTION
-- ============================================================================
-- WHAT: Queries MySQL data dictionary to prove the background event is scheduled and active.
-- WHY: Demonstrates operational DBA monitoring of automated database jobs.
SELECT 
    event_schema, 
    event_name, 
    status, 
    interval_value, 
    interval_field, 
    last_executed 
FROM information_schema.EVENTS 
WHERE event_schema = 'campuspool';


-- ============================================================================
-- CONCEPT 14: DATA CONTROL LANGUAGE (DCL) & ROLE PRIVILEGES
-- ============================================================================
-- WHAT: Inspects table and procedure privileges assigned to app_role.
-- WHY: Demonstrates least-privilege security verification to the examiner.
SHOW GRANTS FOR 'app_role';
