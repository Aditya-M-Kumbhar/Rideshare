import pool from '../db.js';

// WHAT: Whitelisted catalog of DBMS demonstration queries directly mapped from 99_test_queries.sql.
// WHY: Guarantees examiner can test every single DBMS concept safely during the viva presentation.
export const DBMS_SHOWCASE_CATALOG = [
  {
    id: 'explain_index',
    category: '1. DDL & Indexing',
    title: 'EXPLAIN Plan on Composite Index',
    why: 'Demonstrates how the composite index idx_rides_search_composite avoids a costly full table scan on multi-column ride searches.',
    sql: `EXPLAIN SELECT ride_id, departure_time, seats_available, estimated_fare
FROM RIDE_POST
WHERE status = 'OPEN' 
  AND departure_time >= NOW()
  AND pickup_location_id = 10 
  AND destination_location_id = 1;`
  },
  {
    id: 'data_volume',
    category: '2. DML & Seed Data',
    title: 'Seed Volume & Relational Entity Audit',
    why: 'Verifies the realistic demonstration dataset satisfies examiner quotas across users, vehicles, rides, trips, and payments.',
    sql: `SELECT 'USER' AS entity, COUNT(*) AS total_records FROM USER
UNION ALL SELECT 'COLLEGE', COUNT(*) FROM COLLEGE
UNION ALL SELECT 'COMMUNITY', COUNT(*) FROM COMMUNITY
UNION ALL SELECT 'VEHICLE', COUNT(*) FROM VEHICLE
UNION ALL SELECT 'LOCATION', COUNT(*) FROM LOCATION
UNION ALL SELECT 'RIDE_POST', COUNT(*) FROM RIDE_POST
UNION ALL SELECT 'RIDE_REQUEST', COUNT(*) FROM RIDE_REQUEST
UNION ALL SELECT 'TRIP', COUNT(*) FROM TRIP
UNION ALL SELECT 'PAYMENT', COUNT(*) FROM PAYMENT
UNION ALL SELECT 'RATING', COUNT(*) FROM RATING;`
  },
  {
    id: 'inner_join',
    category: '3. Joins',
    title: 'Multi-Table INNER JOIN (5 Tables)',
    why: 'Combines RIDE_POST with driver, vehicle, and pickup/destination locations to assemble human-readable ride details.',
    sql: `SELECT 
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
WHERE r.status = 'OPEN'
LIMIT 10;`
  },
  {
    id: 'left_join',
    category: '3. Joins',
    title: 'LEFT OUTER JOIN (ISA Specialization)',
    why: 'Preserves non-student users while matching student academic records to demonstrate outer join semantics.',
    sql: `SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    u.email,
    s.roll_no,
    COALESCE(c.name, 'Non-Student / General User') AS college_affiliation
FROM USER u
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
ORDER BY u.user_id
LIMIT 15;`
  },
  {
    id: 'right_join',
    category: '3. Joins',
    title: 'RIGHT OUTER JOIN (Campus Participation)',
    why: 'Returns all colleges from the right table regardless of whether students are currently enrolled in them.',
    sql: `SELECT 
    c.name AS college_name,
    c.city,
    COUNT(s.user_id) AS enrolled_students_in_system
FROM STUDENT s
RIGHT JOIN COLLEGE c ON s.college_id = c.college_id
GROUP BY c.college_id, c.name, c.city;`
  },
  {
    id: 'self_join',
    category: '3. Joins',
    title: 'SELF JOIN (Peer Batchmate Matching)',
    why: 'Joins STUDENT with itself to match students belonging to the same college and year who can pool together.',
    sql: `SELECT 
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
ORDER BY s1.year, c.name
LIMIT 10;`
  },
  {
    id: 'subquery_exists',
    category: '4. Subqueries',
    title: 'Correlated Subquery with EXISTS',
    why: 'Selects active riders who have at least one PENDING booking request without loading unnecessary request rows.',
    sql: `SELECT u.user_id, CONCAT(u.first_name, ' ', u.last_name) AS rider_name, u.email
FROM USER u
WHERE EXISTS (
    SELECT 1 
    FROM RIDE_REQUEST req
    WHERE req.rider_id = u.user_id 
      AND req.status = 'PENDING'
);`
  },
  {
    id: 'subquery_not_exists',
    category: '4. Subqueries',
    title: 'Correlated Subquery with NOT EXISTS',
    why: 'Filters for drivers who have completed rides but have NEVER received a review score below 5 stars.',
    sql: `SELECT 
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
);`
  },
  {
    id: 'subquery_all',
    category: '4. Subqueries',
    title: 'Subquery with > ALL Predicate',
    why: 'Finds rides whose estimated fare is strictly higher than ALL rides in Community 4.',
    sql: `SELECT 
    ride_id, 
    driver_id, 
    estimated_fare, 
    notes
FROM RIDE_POST
WHERE estimated_fare > ALL (
    SELECT estimated_fare 
    FROM RIDE_POST 
    WHERE community_id = 4
)
LIMIT 10;`
  },
  {
    id: 'group_by_having',
    category: '5. Aggregates',
    title: 'GROUP BY with HAVING Filter',
    why: 'Aggregates trip distance and duration per driver and filters out drivers with 10 km or less total distance.',
    sql: `SELECT 
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
ORDER BY cumulative_distance_km DESC;`
  },
  {
    id: 'rollup',
    category: '5. Aggregates',
    title: 'Multi-Level Subtotals with WITH ROLLUP',
    why: 'Computes hierarchical revenue sub-totals across colleges and vehicle categories directly in SQL.',
    sql: `SELECT 
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
GROUP BY c.name, v.vehicle_type WITH ROLLUP;`
  },
  {
    id: 'window_dense_rank',
    category: '6. Window Functions',
    title: 'DENSE_RANK() Campus Driver Rankings',
    why: 'Ranks drivers based on customer ratings and completed trips using SQL analytical window partitioning.',
    sql: `SELECT 
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
GROUP BY d.user_id, u.first_name, u.last_name, c.name, d.average_rating;`
  },
  {
    id: 'window_running_total',
    category: '6. Window Functions',
    title: 'SUM() OVER() Running Cumulative Total',
    why: 'Maintains a running total of platform settlements without self-joins or temporary procedural tables.',
    sql: `SELECT 
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
ORDER BY payment_time;`
  },
  {
    id: 'window_row_number',
    category: '6. Window Functions',
    title: 'ROW_NUMBER() for Latest Trip per Driver',
    why: 'Partitions completed trips by driver to reliably extract the single most recent trip for each person.',
    sql: `WITH RankedTrips AS (
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
WHERE rn = 1;`
  },
  {
    id: 'cte_routes',
    category: '7. CTEs',
    title: 'Common Table Expression (CTE) Route Metrics',
    why: 'Modularizes route popularity aggregation into a clean, reusable CTE block.',
    sql: `WITH RouteMetrics AS (
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
ORDER BY total_rides_offered DESC;`
  },
  {
    id: 'recursive_cte',
    category: '7. CTEs',
    title: 'Recursive CTE: Route Itinerary Path Traversal',
    why: 'Recursively stitches stop waypoints in sequence order to assemble a complete route itinerary path string.',
    sql: `WITH RECURSIVE StopHierarchy AS (
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
ORDER BY sequence_no;`
  },
  {
    id: 'masked_users_view',
    category: '8. Database Views',
    title: 'Masked Privacy View (vw_masked_users)',
    why: 'Hides student roll numbers, phone numbers, and driver license numbers behind asterisks for peer privacy.',
    sql: `SELECT user_id, first_name, last_initial, masked_email, masked_phone, masked_license, masked_roll_no, driver_rating
FROM vw_masked_users
LIMIT 10;`
  },
  {
    id: 'stored_functions',
    category: '9. Stored Functions',
    title: 'Custom Deterministic Database Functions',
    why: 'Invokes fn_mask_id, Haversine spherical distance fn_distance_km, and fare-split fn_calculate_fare_share.',
    sql: `SELECT 
    fn_mask_id('MH12AB1234', 4, 2) AS masked_license_plate,
    fn_distance_km(18.5293, 73.8566, 18.5913, 73.7389) AS coep_to_hinjewadi_km,
    fn_calculate_fare_share(180.00, 3) AS fare_share_for_3_riders,
    fn_rating_badge(4.90) AS driver_badge;`
  },
  {
    id: 'audit_log',
    category: '10. Triggers & Auditing',
    title: 'Trigger-Generated Audit Trail Inspection',
    why: 'Queries AUDIT_LOG to view automated JSON before/after snapshots recorded by AFTER UPDATE triggers.',
    sql: `SELECT log_id, table_name, action_type, record_id, old_values, new_values, changed_at
FROM AUDIT_LOG
ORDER BY log_id DESC
LIMIT 10;`
  },
  {
    id: 'event_scheduler',
    category: '11. Scheduled Events',
    title: 'MySQL Event Scheduler Inspection',
    why: 'Demonstrates active background database jobs (ev_expire_past_rides) running in MySQL.',
    sql: `SELECT 
    event_schema, 
    event_name, 
    status, 
    interval_value, 
    interval_field, 
    last_executed 
FROM information_schema.EVENTS 
WHERE event_schema = 'campuspool';`
  }
];

// WHAT: Returns catalog of showcase queries for the frontend DBMS viva demonstrator.
// WHY: Allows the React showcase page to render tabs, titles, and explanations.
export function getShowcaseList(req, res) {
  res.json(DBMS_SHOWCASE_CATALOG);
}

// WHAT: Safely executes a whitelisted demo query and returns tabular column/row outputs.
// WHY: Gives the examiner an interactive workbench inside the web application.
export async function executeShowcaseQuery(req, res) {
  try {
    const { queryId } = req.body;
    const entry = DBMS_SHOWCASE_CATALOG.find(q => q.id === queryId);

    if (!entry) {
      return res.status(404).json({ error: 'Demonstration query not found in whitelist.' });
    }

    const start = performance.now();
    const [results, fields] = await pool.query(entry.sql);
    const executionTimeMs = (performance.now() - start).toFixed(2);

    // Extract columns
    let columns = [];
    if (fields && Array.isArray(fields)) {
      columns = fields.map(f => f.name);
    } else if (Array.isArray(results) && results.length > 0) {
      columns = Object.keys(results[0]);
    }

    res.json({
      queryId: entry.id,
      title: entry.title,
      category: entry.category,
      why: entry.why,
      sql: entry.sql,
      executionTimeMs,
      columns,
      rows: Array.isArray(results) ? results : [results]
    });
  } catch (err) {
    console.error('Execute showcase error:', err);
    res.status(500).json({ error: err.message, sqlMessage: err.sqlMessage });
  }
}
