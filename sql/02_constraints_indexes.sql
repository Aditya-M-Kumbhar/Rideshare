-- ============================================================================
-- 02_constraints_indexes.sql: Domain Constraints & Performance Indexes
-- Demonstrates Concepts from Database System Concepts (Chapter 4):
--   1. Domain Integrity & CHECK Constraints (Slides 4.12, 4.13)
--   2. Single & Composite Indexes for Query Optimization
-- ============================================================================

USE campuspool;

-- ============================================================================
-- 1. DOMAIN CHECK CONSTRAINTS (Silberschatz Ch. 4, Slide 4.12 & 4.13)
-- Enforces predicates P directly at the database engine level.
-- ============================================================================

-- Check 1: Student academic year must be between 1 and 5
ALTER TABLE STUDENT
ADD CONSTRAINT chk_student_year CHECK (year >= 1 AND year <= 5);

-- Check 2: Driver average rating must be between 1.00 and 5.00
ALTER TABLE DRIVER
ADD CONSTRAINT chk_driver_rating CHECK (average_rating >= 1.00 AND average_rating <= 5.00);

-- Check 3: Vehicle passenger capacity must be between 1 and 8
ALTER TABLE VEHICLE
ADD CONSTRAINT chk_vehicle_capacity CHECK (capacity >= 1 AND capacity <= 8);

-- Check 4: Latitude and Longitude coordinate range validation
ALTER TABLE LOCATION
ADD CONSTRAINT chk_loc_lat CHECK (latitude >= -90.0000000 AND latitude <= 90.0000000),
ADD CONSTRAINT chk_loc_lng CHECK (longitude >= -180.0000000 AND longitude <= 180.0000000);

ALTER TABLE COLLEGE
ADD CONSTRAINT chk_col_lat CHECK (latitude >= -90.0000000 AND latitude <= 90.0000000),
ADD CONSTRAINT chk_col_lng CHECK (longitude >= -180.0000000 AND longitude <= 180.0000000);

-- Check 5: Seats available cannot exceed seats offered or be negative
ALTER TABLE RIDE_POST
ADD CONSTRAINT chk_ride_seats_offered CHECK (seats_offered > 0 AND seats_offered <= 8),
ADD CONSTRAINT chk_ride_seats_avail CHECK (seats_available >= 0 AND seats_available <= seats_offered),
ADD CONSTRAINT chk_ride_fare_pos CHECK (estimated_fare >= 0.00);

-- Check 6: Ride request seat quota and fare share validation
ALTER TABLE RIDE_REQUEST
ADD CONSTRAINT chk_req_seats CHECK (seats_requested >= 1 AND seats_requested <= 8),
ADD CONSTRAINT chk_req_fare CHECK (fare_share >= 0.00);

-- Check 7: Trip financial and distance integrity
ALTER TABLE TRIP
ADD CONSTRAINT chk_trip_dist CHECK (distance_km >= 0.00),
ADD CONSTRAINT chk_trip_fare CHECK (total_fare >= 0.00);

-- Check 8: Payment amount must be strictly positive
ALTER TABLE PAYMENT
ADD CONSTRAINT chk_pay_amount CHECK (amount > 0.00);

-- Check 9: Rating review score must be between 1 and 5
ALTER TABLE RATING
ADD CONSTRAINT chk_rate_score CHECK (score >= 1 AND score <= 5);

-- ============================================================================
-- 2. PERFORMANCE INDEXES (Single & Composite)
-- ============================================================================

-- Composite Index: Primary search query (Status + Departure Time + Locations)
CREATE INDEX idx_rides_search_composite 
ON RIDE_POST (status, departure_time, pickup_location_id, destination_location_id);

-- Composite Index: Community filtering for student groups
CREATE INDEX idx_rides_community_status 
ON RIDE_POST (community_id, status, departure_time);

-- Single Index: Driver's offered rides
CREATE INDEX idx_rides_driver 
ON RIDE_POST (driver_id);

-- Composite Index: Rider's booking request dashboard
CREATE INDEX idx_requests_rider_status 
ON RIDE_REQUEST (rider_id, status, request_time);

-- Single Index: Ride requests by ride
CREATE INDEX idx_requests_ride 
ON RIDE_REQUEST (ride_id);

-- Composite Index: Trip monitoring
CREATE INDEX idx_trip_status_time 
ON TRIP (status, start_time);
