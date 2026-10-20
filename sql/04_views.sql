-- ============================================================================
-- 04_views.sql: Masked Privacy Views, Ride Catalogs, and Analytics
-- Demonstrates Updatable vs Non-Updatable Views and Security Abstractions.
-- ============================================================================

USE campuspool;

-- ----------------------------------------------------------------------------
-- 1. MASKED USER PRIVACY VIEW (NON-UPDATABLE: Contains Expressions & Joins)
-- ----------------------------------------------------------------------------
-- WHAT: Masks sensitive identifiers (email, phone, student roll number, driver license).
-- WHY: Enables peer riders to verify driver identity and campus trust without exposing raw PII.
CREATE OR REPLACE VIEW vw_masked_users AS
SELECT 
    u.user_id,
    u.first_name,
    CONCAT(LEFT(u.last_name, 1), '.') AS last_initial,
    -- Email masking: first 2 chars + **** + @domain
    CONCAT(
        LEFT(u.email, 2), 
        '****@', 
        SUBSTRING_INDEX(u.email, '@', -1)
    ) AS masked_email,
    -- Phone masking: first 4 digits + **** + last 2 digits
    CONCAT(
        LEFT(COALESCE(p.phone_no, '9999999999'), 4), 
        '****', 
        RIGHT(COALESCE(p.phone_no, '9999999999'), 2)
    ) AS masked_phone,
    u.gender,
    u.age,
    u.profile_photo,
    u.status,
    u.is_verified,
    -- Masked Driver License: MH12****34 format
    CASE 
        WHEN d.user_id IS NOT NULL 
        THEN CONCAT(LEFT(d.license_no, 4), '****', RIGHT(d.license_no, 2))
        ELSE NULL 
    END AS masked_license,
    d.average_rating AS driver_rating,
    -- Student Details with Masked Roll No
    s.program AS student_program,
    s.year AS student_year,
    c.name AS college_name,
    CASE 
        WHEN s.roll_no IS NOT NULL 
        THEN CONCAT(LEFT(s.roll_no, 3), '****', RIGHT(s.roll_no, 2))
        ELSE NULL 
    END AS masked_roll_no
FROM USER u
LEFT JOIN DRIVER d ON u.user_id = d.user_id
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
LEFT JOIN USER_PHONE p ON u.user_id = p.user_id AND p.is_primary = TRUE;

-- ----------------------------------------------------------------------------
-- 2. AVAILABLE RIDES CATALOG VIEW (NON-UPDATABLE: Multi-table JOIN with Calculations)
-- ----------------------------------------------------------------------------
-- WHAT: Enriched ride catalog combining driver info, vehicle, pickup, destination, and community.
-- WHY: Standard search view consumed by the frontend; simplifies complex joins into a single SELECT.
CREATE OR REPLACE VIEW vw_available_rides AS
SELECT 
    r.ride_id,
    r.status AS ride_status,
    r.departure_time,
    r.seats_offered,
    r.seats_available,
    r.estimated_fare,
    r.notes,
    -- Driver details
    r.driver_id,
    CONCAT(u.first_name, ' ', LEFT(u.last_name, 1), '.') AS driver_name,
    u.is_verified AS driver_verified,
    d.average_rating AS driver_rating,
    -- Vehicle details
    v.vehicle_id,
    v.vehicle_type,
    CONCAT(v.make, ' ', v.model) AS vehicle_model,
    v.color AS vehicle_color,
    -- Masked vehicle plate: MH12****89 format
    CONCAT(LEFT(v.plate_no, 4), '****', RIGHT(v.plate_no, 2)) AS masked_plate_no,
    -- Route details
    loc_from.location_id AS pickup_location_id,
    loc_from.name AS pickup_name,
    loc_from.address AS pickup_address,
    loc_from.latitude AS pickup_lat,
    loc_from.longitude AS pickup_lng,
    loc_to.location_id AS destination_location_id,
    loc_to.name AS destination_name,
    loc_to.address AS destination_address,
    loc_to.latitude AS destination_lat,
    loc_to.longitude AS destination_lng,
    -- Community scope
    r.community_id,
    COALESCE(comm.name, 'Open Campus Pool') AS community_name,
    COALESCE(comm.type, 'GENERAL') AS community_type
FROM RIDE_POST r
JOIN USER u ON r.driver_id = u.user_id
JOIN DRIVER d ON u.user_id = d.user_id
JOIN VEHICLE v ON r.vehicle_id = v.vehicle_id
JOIN LOCATION loc_from ON r.pickup_location_id = loc_from.location_id
JOIN LOCATION loc_to ON r.destination_location_id = loc_to.location_id
LEFT JOIN COMMUNITY comm ON r.community_id = comm.community_id;

-- ----------------------------------------------------------------------------
-- 3. DRIVER PERFORMANCE LEADERBOARD VIEW (NON-UPDATABLE: Uses GROUP BY & Aggregations)
-- ----------------------------------------------------------------------------
-- WHAT: Summarizes driver achievements including completed trips, ratings, distance, and earnings.
-- WHY: Recognizes active campus poolers and demonstrates multi-table aggregate views.
CREATE OR REPLACE VIEW vw_driver_leaderboard AS
SELECT 
    d.user_id AS driver_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    c.name AS college_name,
    d.average_rating,
    COUNT(DISTINCT t.trip_id) AS total_trips_completed,
    COALESCE(SUM(t.distance_km), 0.00) AS total_distance_km,
    COALESCE(SUM(p.amount), 0.00) AS total_fare_collected,
    COUNT(DISTINCT r.rating_id) AS total_reviews_received
FROM DRIVER d
JOIN USER u ON d.user_id = u.user_id
LEFT JOIN STUDENT s ON u.user_id = s.user_id
LEFT JOIN COLLEGE c ON s.college_id = c.college_id
LEFT JOIN TRIP t ON d.user_id = t.driver_id AND t.status = 'COMPLETED'
LEFT JOIN PAYMENT p ON t.trip_id = p.trip_id AND p.status = 'COMPLETED'
LEFT JOIN RATING r ON t.trip_id = r.trip_id AND r.ratee_user_id = d.user_id
GROUP BY d.user_id, u.first_name, u.last_name, c.name, d.average_rating;

-- ----------------------------------------------------------------------------
-- 4. UPDATABLE VIEW EXAMPLE: USER CONTACT & EMERGENCY INFO
-- ----------------------------------------------------------------------------
-- WHAT: Simple view on a single base table (EMERGENCY_CONTACT) with a 1:1 row projection.
-- WHY: Demonstrates an UPDATABLE view in MySQL where UPDATE/INSERT statements modify the base table directly.
CREATE OR REPLACE VIEW vw_updatable_emergency_contact AS
SELECT 
    user_id,
    contact_no,
    contact_name,
    phone,
    relationship
FROM EMERGENCY_CONTACT;
-- Note for examiners: You can run:
-- UPDATE vw_updatable_emergency_contact SET phone = '9998887776' WHERE user_id = 1 AND contact_no = 1;
-- MySQL permits this because the view contains no GROUP BY, DISTINCT, AGGREGATES, or JOINS.
