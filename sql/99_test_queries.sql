-- ============================================================================
-- 99_test_queries.sql: Viva Examination & Demonstration Suite
-- Directly mapped to Database System Concepts (Chapters 3 & 4 - Silberschatz)
-- Each query demonstrates a textbook relational concept with clear explanations.
-- ============================================================================

USE campuspool;

-- ============================================================================
-- 1. BASIC QUERY STRUCTURE, DISTINCT & ARITHMETIC (Ch. 3, Slides 3.9 - 3.12)
-- Demonstrates: SELECT, DISTINCT, and arithmetic expression (estimated_fare * 1.05)
-- ============================================================================
SELECT DISTINCT 
    r.ride_id, 
    r.seats_offered,
    r.estimated_fare AS original_fare,
    ROUND(r.estimated_fare * 1.05, 2) AS fare_with_convenience_fee
FROM RIDE_POST r
WHERE r.status = 'OPEN';

-- ============================================================================
-- 2. WHERE CLAUSE WITH BETWEEN & ORDER BY (Ch. 3, Slides 3.13, 3.14, 3.19)
-- Demonstrates: Range filtering with BETWEEN and sorting with ORDER BY ... DESC
-- ============================================================================
SELECT ride_id, departure_time, seats_available, estimated_fare
FROM RIDE_POST
WHERE estimated_fare BETWEEN 40.00 AND 120.00
ORDER BY estimated_fare DESC;

-- ============================================================================
-- 3. STRING OPERATIONS WITH LIKE (Ch. 3, Slide 3.18)
-- Demonstrates: Pattern matching using the % wildcard
-- ============================================================================
SELECT user_id, first_name, last_name, email
FROM USER
WHERE email LIKE '%@%.edu%' OR email LIKE '%@coep.%';

-- ============================================================================
-- 4. SET OPERATIONS: UNION & UNION ALL (Ch. 3, Slides 3.22 - 3.23)
-- Demonstrates: Combining record sets across entities (Seed Data Audit)
-- ============================================================================
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
-- 5. AGGREGATE FUNCTIONS: COUNT, SUM, AVG, MIN, MAX (Ch. 3, Slides 3.24 - 3.25)
-- Demonstrates: Columnar aggregate computations
-- ============================================================================
SELECT 
    COUNT(*) AS total_completed_trips,
    ROUND(SUM(distance_km), 2) AS total_distance_covered_km,
    ROUND(AVG(total_fare), 2) AS avg_trip_fare,
    MIN(fare_per_person) AS min_seat_fare,
    MAX(fare_per_person) AS max_seat_fare
FROM TRIP
WHERE status = 'COMPLETED';

-- ============================================================================
-- 6. GROUP BY WITH HAVING CLAUSE (Ch. 3, Slides 3.26 - 3.27)
-- Demonstrates: Grouping by driver and filtering aggregate results with HAVING
-- ============================================================================
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
-- 7. MULTI-LEVEL SUBTOTALS WITH ROLLUP (Ch. 3, Advanced Grouping)
-- Demonstrates: Hierarchical aggregations across college and vehicle category
-- ============================================================================
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
-- 8. NESTED SUBQUERIES: IN & NOT IN (Ch. 3, Slides 3.31 - 3.33)
-- Demonstrates: Set membership tests
-- ============================================================================
-- Find all users who have registered a vehicle (are drivers)
SELECT user_id, first_name, last_name, email
FROM USER
WHERE user_id IN (SELECT driver_id FROM VEHICLE);

-- ============================================================================
-- 9. SET COMPARISONS: > ALL PREDICATE (Ch. 3, Slides 3.34 - 3.37)
-- Demonstrates: Value compared to all rows returned by subquery
-- ============================================================================
SELECT ride_id, driver_id, estimated_fare, notes
FROM RIDE_POST
WHERE estimated_fare > ALL (
    SELECT estimated_fare 
    FROM RIDE_POST 
    WHERE community_id = 4
);

-- ============================================================================
-- 10. TEST FOR EMPTY RELATIONS: EXISTS & NOT EXISTS (Ch. 3, Slides 3.38 - 3.39)
-- Demonstrates: Correlated subquery existence testing
-- ============================================================================
-- A. Riders with at least one pending request (EXISTS)
SELECT u.user_id, CONCAT(u.first_name, ' ', u.last_name) AS rider_name, u.email
FROM USER u
WHERE EXISTS (
    SELECT 1 
    FROM RIDE_REQUEST req
    WHERE req.rider_id = u.user_id AND req.status = 'PENDING'
);

-- B. Drivers with completed trips and zero low ratings (NOT EXISTS)
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
-- 11. DERIVED RELATIONS: SUBQUERY IN FROM CLAUSE (Ch. 3, Slide 3.42)
-- Demonstrates: Treating query output as a temporary derived relation
-- ============================================================================
SELECT driver_id, total_trips, total_km
FROM (
    SELECT driver_id, COUNT(*) AS total_trips, SUM(distance_km) AS total_km
    FROM TRIP
    WHERE status = 'COMPLETED'
    GROUP BY driver_id
) AS driver_summary
WHERE total_km > 20.00;

-- ============================================================================
-- 12. WITH CLAUSE: COMMON TABLE EXPRESSIONS (CTE) (Ch. 3, Slides 3.43 - 3.44)
-- Demonstrates: Modular temporary view definitions
-- ============================================================================
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
ORDER BY total_rides_offered DESC;

-- Recursive CTE: Route Waypoint Itinerary Traversal
WITH RECURSIVE StopHierarchy AS (
    SELECT 
        s.ride_id,
        s.sequence_no,
        loc.name AS current_stop,
        CAST(loc.name AS CHAR(500)) AS itinerary_path
    FROM RIDE_STOP s
    JOIN LOCATION loc ON s.location_id = loc.location_id
    WHERE s.ride_id = 1 AND s.sequence_no = 1
    UNION ALL
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
-- 13. JOINED RELATIONS: INNER, LEFT, RIGHT, SELF JOINS (Ch. 3, Slides 3.58 - 3.62)
-- ============================================================================
-- A. Multi-table INNER JOIN (5 Tables)
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

-- B. LEFT OUTER JOIN: Preserves all users even without student records
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

-- C. RIGHT OUTER JOIN: Preserves all colleges even with zero students
SELECT 
    c.name AS college_name,
    c.city,
    COUNT(s.user_id) AS enrolled_students_in_system
FROM STUDENT s
RIGHT JOIN COLLEGE c ON s.college_id = c.college_id
GROUP BY c.college_id, c.name, c.city;

-- D. SELF JOIN: Matches peer students from same college and year
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
-- 14. ANALYTICAL WINDOW FUNCTIONS (Ch. 4, Advanced SQL)
-- Demonstrates: DENSE_RANK(), SUM() OVER(), ROW_NUMBER()
-- ============================================================================
-- A. DENSE_RANK() Leaderboard
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

-- B. SUM() OVER(): Running Cumulative Settlement Total
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

-- C. ROW_NUMBER(): Latest trip per driver
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
-- 15. DATABASE VIEWS (Ch. 3, Slides 3.45 - 3.49)
-- ============================================================================
SELECT user_id, first_name, last_initial, masked_email, masked_phone, masked_license, masked_roll_no, driver_rating
FROM vw_masked_users
LIMIT 10;

-- ============================================================================
-- 16. STORED FUNCTIONS EXECUTION (Ch. 4)
-- ============================================================================
SELECT 
    fn_mask_id('MH12AB1234', 4, 2) AS masked_license_plate,
    fn_distance_km(18.5293, 73.8566, 18.5913, 73.7389) AS coep_to_hinjewadi_km,
    fn_calculate_fare_share(180.00, 3) AS fare_share_for_3_riders,
    fn_rating_badge(4.90) AS driver_badge;

-- ============================================================================
-- 17. INDEX OPTIMIZATION & EXPLAIN PLAN (Ch. 4)
-- ============================================================================
EXPLAIN SELECT ride_id, departure_time, seats_available, estimated_fare
FROM RIDE_POST
WHERE status = 'OPEN' 
  AND departure_time >= NOW()
  AND pickup_location_id = 10 
  AND destination_location_id = 1;

-- ============================================================================
-- 18. AUDIT LOG INSPECTION (Ch. 4, Triggers & Auditing)
-- ============================================================================
SELECT log_id, table_name, action_type, record_id, old_values, new_values, changed_at
FROM AUDIT_LOG
ORDER BY log_id DESC
LIMIT 10;

-- ============================================================================
-- 19. SCHEDULED EVENTS INSPECTION (Ch. 4, Events & Jobs)
-- ============================================================================
SELECT 
    event_schema, 
    event_name, 
    status, 
    interval_value, 
    interval_field, 
    last_executed 
FROM information_schema.EVENTS 
WHERE event_schema = 'campuspool';
