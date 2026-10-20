-- ============================================================================
-- 02_constraints_indexes.sql: Business Rule Constraints & Performance Indexes
-- Demonstrates CHECK constraints, domain integrity, and composite indexing.
-- ============================================================================

USE campuspool;

-- ----------------------------------------------------------------------------
-- 1. DOMAIN & BUSINESS RULE CHECK CONSTRAINTS
-- ----------------------------------------------------------------------------

-- WHAT: Restricts student academic year between 1st year and 5th year (Bachelors/Masters).
-- WHY: Prevents entry of invalid academic years into the student profile.
ALTER TABLE STUDENT
ADD CONSTRAINT chk_student_year CHECK (year >= 1 AND year <= 5);

-- WHAT: Restricts driver rating between 1.00 and 5.00.
-- WHY: Mathematical guarantee that average ratings remain within standard star bounds.
ALTER TABLE DRIVER
ADD CONSTRAINT chk_driver_rating CHECK (average_rating >= 1.00 AND average_rating <= 5.00);

-- WHAT: Guarantees vehicle passenger capacity is between 1 (bike pillion) and 8 (SUV/Van).
-- WHY: Prevents impossible seating allocations from corrupting ride offer logic.
ALTER TABLE VEHICLE
ADD CONSTRAINT chk_vehicle_capacity CHECK (capacity >= 1 AND capacity <= 8);

-- WHAT: Ensures coordinates conform to valid global latitude (-90 to +90) and longitude (-180 to +180).
-- WHY: Invalid geographical coordinates break distance formulas and map rendering.
ALTER TABLE LOCATION
ADD CONSTRAINT chk_loc_latitude CHECK (latitude >= -90.0000000 AND latitude <= 90.0000000),
ADD CONSTRAINT chk_loc_longitude CHECK (longitude >= -180.0000000 AND longitude <= 180.0000000);

ALTER TABLE COLLEGE
ADD CONSTRAINT chk_college_latitude CHECK (latitude >= -90.0000000 AND latitude <= 90.0000000),
ADD CONSTRAINT chk_college_longitude CHECK (longitude >= -180.0000000 AND longitude <= 180.0000000);

-- WHAT: Validates that offered seats are positive and available seats never exceed offered seats or drop below 0.
-- WHY: Enforces seat inventory integrity directly inside the database engine.
ALTER TABLE RIDE_POST
ADD CONSTRAINT chk_ride_seats_offered CHECK (seats_offered > 0 AND seats_offered <= 8),
ADD CONSTRAINT chk_ride_seats_available CHECK (seats_available >= 0 AND seats_available <= seats_offered),
ADD CONSTRAINT chk_ride_fare_positive CHECK (estimated_fare >= 0.00);

-- WHAT: Ensures riders request at least 1 seat and pay non-negative fare shares.
-- WHY: Rejects zero or negative seat bookings and zero or negative pricing corruption.
ALTER TABLE RIDE_REQUEST
ADD CONSTRAINT chk_request_seats CHECK (seats_requested >= 1 AND seats_requested <= 8),
ADD CONSTRAINT chk_request_fare CHECK (fare_share >= 0.00);

-- WHAT: Validates that trip distance and monetary fares are non-negative.
-- WHY: Protects financial integrity of completed ride settlements.
ALTER TABLE TRIP
ADD CONSTRAINT chk_trip_distance CHECK (distance_km >= 0.00),
ADD CONSTRAINT chk_trip_total_fare CHECK (total_fare >= 0.00),
ADD CONSTRAINT chk_trip_fare_per_person CHECK (fare_per_person >= 0.00);

-- WHAT: Restricts payment amount to strictly positive values.
-- WHY: Eliminates fraudulent zero-value or negative payment transactions.
ALTER TABLE PAYMENT
ADD CONSTRAINT chk_payment_amount CHECK (amount > 0.00);

-- WHAT: Limits user reviews to an integer score between 1 and 5.
-- WHY: Preserves standard 5-star rating scale semantics.
ALTER TABLE RATING
ADD CONSTRAINT chk_rating_score CHECK (score >= 1 AND score <= 5);


-- ----------------------------------------------------------------------------
-- 2. PERFORMANCE INDEXES (SINGLE & COMPOSITE)
-- ----------------------------------------------------------------------------

-- WHAT: Composite index on RIDE_POST for the primary search query (status, departure_time, pickup, destination).
-- WHY: Enables index range scans for riders finding upcoming open rides between specific points without full table scans.
CREATE INDEX idx_rides_search_composite 
ON RIDE_POST (status, departure_time, pickup_location_id, destination_location_id);

-- WHAT: Composite index on RIDE_POST for community-specific filters.
-- WHY: Speeds up filtered listings when a student selects their college community group.
CREATE INDEX idx_rides_community_status 
ON RIDE_POST (community_id, status, departure_time);

-- WHAT: Index on RIDE_POST driver_id.
-- WHY: Accelerates "My Offered Rides" queries on driver dashboards.
CREATE INDEX idx_rides_driver 
ON RIDE_POST (driver_id);

-- WHAT: Composite index on RIDE_REQUEST for rider dashboard lookups.
-- WHY: Speeds up fetching all pending/accepted booking requests made by a particular student.
CREATE INDEX idx_requests_rider_status 
ON RIDE_REQUEST (rider_id, status, request_time);

-- WHAT: Index on RIDE_REQUEST ride_id.
-- WHY: Optimizes driver notifications and seat confirmation checks for a specific ride.
CREATE INDEX idx_requests_ride 
ON RIDE_REQUEST (ride_id);

-- WHAT: Composite index on TRIP for status and start_time.
-- WHY: Speeds up active trip monitoring and historical trip reporting.
CREATE INDEX idx_trip_status_time 
ON TRIP (status, start_time);

-- WHAT: Composite index on RATING for calculating a user's average rating.
-- WHY: Allows instant aggregation of average score for a driver without scanning unrelated reviews.
CREATE INDEX idx_rating_target_user 
ON RATING (ratee_user_id, score);

-- WHAT: Composite index on NOTIFICATION for unread notifications per user.
-- WHY: Optimizes the notification bell badge query in the header (WHERE user_id = ? AND read_status = FALSE).
CREATE INDEX idx_notif_user_unread 
ON NOTIFICATION (user_id, read_status, sent_at);

-- WHAT: Composite index on AUDIT_LOG for forensic lookups by table and date.
-- WHY: Accelerates administrative auditing across specific tables and event windows.
CREATE INDEX idx_audit_table_time 
ON AUDIT_LOG (table_name, changed_at);
