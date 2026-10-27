-- ============================================================================
-- 03_seed_data.sql: Realistic Demonstration Dataset
-- Populates colleges, communities, users (drivers/students), vehicles,
-- locations, 25+ ride posts, 40+ requests, 15+ trips, payments, and ratings.
-- Standard demo password for all seeded users is: password123
-- ============================================================================

USE campuspool;

-- ----------------------------------------------------------------------------
-- 1. COLLEGES & CAMPUSES
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 3 well-known Pune university campuses with geo-coordinates.
-- WHY: Establishes realistic anchor points for student daily commutes and community groups.
INSERT INTO COLLEGE (college_id, name, address, city, state, latitude, longitude) VALUES
(1, 'COEP Technological University', 'Wellesley Rd, Shivajinagar', 'Pune', 'Maharashtra', 18.5293, 73.8566),
(2, 'Pune Institute of Computer Technology (PICT)', 'Survey No. 27, Dhankawadi', 'Pune', 'Maharashtra', 18.4575, 73.8508),
(3, 'MIT World Peace University (MIT-WPU)', 'Paud Rd, Kothrud', 'Pune', 'Maharashtra', 18.5178, 73.8151);

-- ----------------------------------------------------------------------------
-- 2. COMMUNITIES
-- ----------------------------------------------------------------------------
-- WHAT: Creates default general and college-specific carpooling circles.
-- WHY: Gives students the safety choice of pooling only within their verified university.
INSERT INTO COMMUNITY (community_id, name, type, college_id, description) VALUES
(1, 'Pune Open Campus Pool', 'GENERAL', NULL, 'Open to all verified college students and faculty across Pune.'),
(2, 'COEPian Commuters', 'COLLEGE', 1, 'Exclusive pooling network for COEP students, researchers, and alumni.'),
(3, 'PICT Tech Poolers', 'COLLEGE', 2, 'Daily car and bike pooling community for PICT Dhankawadi campus.'),
(4, 'MIT-WPU Kothrud Circle', 'COLLEGE', 3, 'Ride sharing group for MIT-WPU students travelling to Kothrud campus.');

-- ----------------------------------------------------------------------------
-- 3. LOCATIONS (TRANSIT HUBS, GATES, HOSTELS)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 12 key transit hubs, metro stations, gates, and residential nodes.
-- WHY: Provides realistic pickup and destination waypoints with exact coordinates.
INSERT INTO LOCATION (location_id, name, type, address, latitude, longitude, geohash) VALUES
(1, 'COEP North Gate', 'CAMPUS_GATE', 'Near Sancheti Hospital, Shivajinagar', 18.5301, 73.8559, 'tek3v'),
(2, 'COEP Hostel Campus', 'HOSTEL', 'Behind Sancheti Healthcare, Shivajinagar', 18.5325, 73.8540, 'tek3v'),
(3, 'PICT Main Gate 1', 'CAMPUS_GATE', 'Opposite Trimurti Chowk, Dhankawadi', 18.4580, 73.8502, 'tek3m'),
(4, 'MIT-WPU Main Entrance', 'CAMPUS_GATE', 'Paud Road, Rambaug Colony, Kothrud', 18.5175, 73.8148, 'tek3s'),
(5, 'Shivajinagar Metro Station', 'METRO_STATION', 'JM Road Junction, Shivajinagar', 18.5318, 73.8475, 'tek3t'),
(6, 'Swargate Bus Terminal', 'BUS_STAND', 'Jedhe Chowk, Swargate', 18.5018, 73.8636, 'tek3w'),
(7, 'Katraj Bus Depot', 'BUS_STAND', 'Pune-Satara Highway, Katraj', 18.4529, 73.8553, 'tek3j'),
(8, 'Kothrud Stand (Karve Statue)', 'JUNCTION', 'Karve Road, Kothrud', 18.5074, 73.8077, 'tek3k'),
(9, 'Hinjewadi Phase 1 Circle', 'JUNCTION', 'Near Shivaji Chowk, Hinjewadi IT Park', 18.5913, 73.7389, 'tek6h'),
(10, 'Baner Pan Card Club Road', 'LANDMARK', 'Baner High Street Junction', 18.5590, 73.7868, 'tek64'),
(11, 'Viman Nagar Phoenix Mall', 'LANDMARK', 'Ahmednagar Highway, Viman Nagar', 18.5626, 73.9168, 'tek72'),
(12, 'Wakad Bhumkar Chowk', 'JUNCTION', 'Mumbai-Bangalore Highway, Wakad', 18.5987, 73.7621, 'tek6k');

-- ----------------------------------------------------------------------------
-- 4. USERS (16 STUDENTS & DRIVERS)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 16 realistic students/drivers with bcrypt hashes for 'password123'.
-- WHY: Fulfills the minimum 15 user requirement with a mix of verified and unverified profiles.
INSERT INTO USER (user_id, first_name, last_name, email, password_hash, gender, date_of_birth, profile_photo, status, is_verified) VALUES
(1, 'Aarav', 'Sharma', 'aarav.sharma@coep.ac.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2002-04-14', '/avatars/aarav.png', 'ACTIVE', TRUE),
(2, 'Ananya', 'Deshmukh', 'ananya.d@pict.edu', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2003-08-22', '/avatars/ananya.png', 'ACTIVE', TRUE),
(3, 'Rohan', 'Patil', 'rohan.patil@mitwpu.edu.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2001-11-05', '/avatars/rohan.png', 'ACTIVE', TRUE),
(4, 'Priya', 'Kulkarni', 'priya.k@coep.ac.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2003-01-30', '/avatars/priya.png', 'ACTIVE', TRUE),
(5, 'Siddharth', 'Joshi', 'siddharth.j@pict.edu', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2002-07-19', '/avatars/sid.png', 'ACTIVE', TRUE),
(6, 'Neha', 'Shinde', 'neha.shinde@mitwpu.edu.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2004-03-12', '/avatars/neha.png', 'ACTIVE', FALSE),
(7, 'Vikram', 'Mehta', 'vikram.m@gmail.com', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2000-09-08', '/avatars/vikram.png', 'ACTIVE', TRUE),
(8, 'Tanvi', 'Chavan', 'tanvi.c@coep.ac.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2003-05-17', '/avatars/tanvi.png', 'ACTIVE', TRUE),
(9, 'Aditya', 'Gaikwad', 'aditya.g@pict.edu', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2002-12-01', '/avatars/aditya.png', 'ACTIVE', TRUE),
(10, 'Ishita', 'More', 'ishita.more@mitwpu.edu.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2003-10-25', '/avatars/ishita.png', 'ACTIVE', TRUE),
(11, 'Kabir', 'Bhosale', 'kabir.b@coep.ac.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2001-02-18', '/avatars/kabir.png', 'ACTIVE', TRUE),
(12, 'Shruti', 'Pawar', 'shruti.p@pict.edu', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2004-06-04', '/avatars/shruti.png', 'ACTIVE', FALSE),
(13, 'Gaurav', 'Kadam', 'gaurav.kadam@gmail.com', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2002-09-14', '/avatars/gaurav.png', 'ACTIVE', TRUE),
(14, 'Pooja', 'Rathod', 'pooja.r@mitwpu.edu.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2003-03-29', '/avatars/pooja.png', 'ACTIVE', TRUE),
(15, 'Kunal', 'Wagh', 'kunal.wagh@coep.ac.in', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'MALE', '2002-08-08', '/avatars/kunal.png', 'ACTIVE', TRUE),
(16, 'Diya', 'Sawant', 'diya.s@pict.edu', '$2b$10$EpRnTzVlqHNP0.fUbXUwSOyuiXe/QLSUG6xNekdHgTGmrpHEfIoxm', 'FEMALE', '2004-01-11', '/avatars/diya.png', 'ACTIVE', TRUE);

-- ----------------------------------------------------------------------------
-- 5. MULTIVALUED ATTRIBUTE: USER_PHONE
-- ----------------------------------------------------------------------------
-- WHAT: Inserts primary and alternate phone numbers for users.
-- WHY: Maps ER diagram multivalued attribute into a normalized 1NF child table.
INSERT INTO USER_PHONE (user_id, phone_no, is_primary) VALUES
(1, '9822011223', TRUE),
(1, '9822011224', FALSE),
(2, '9423055667', TRUE),
(3, '9158099881', TRUE),
(4, '9890123456', TRUE),
(5, '9765432109', TRUE),
(6, '9604112233', TRUE),
(7, '9823456789', TRUE),
(8, '9922114455', TRUE),
(9, '9881223344', TRUE),
(10, '9403556677', TRUE),
(11, '9730889900', TRUE),
(12, '9175443322', TRUE),
(13, '9850119922', TRUE),
(14, '9689223311', TRUE),
(15, '9970334455', TRUE),
(16, '9822887766', TRUE);

-- ----------------------------------------------------------------------------
-- 6. SPECIALIZATION: STUDENT ENTITY
-- ----------------------------------------------------------------------------
-- WHAT: Links student users with their university, degree program, and roll number.
-- WHY: ISA specialization table holding academic-specific attributes.
INSERT INTO STUDENT (user_id, roll_no, program, year, college_id) VALUES
(1, '112003045', 'B.Tech Computer Engineering', 4, 1),
(2, 'CE2021088', 'B.E. Information Technology', 3, 2),
(3, 'WPU-CSE-2022', 'B.Tech Computer Science', 3, 3),
(4, '112107012', 'B.Tech Mechanical Engineering', 3, 1),
(5, 'IT2020015', 'B.E. Computer Engineering', 4, 2),
(6, 'WPU-ECE-2023', 'B.Tech Electronics & Comm', 2, 3),
(8, '112103099', 'B.Tech Electrical Engineering', 3, 1),
(9, 'CE2021102', 'B.E. Information Technology', 3, 2),
(10, 'WPU-MBA-2023', 'MBA Business Analytics', 2, 3),
(11, '112008021', 'B.Tech Civil Engineering', 4, 1),
(12, 'FE2023055', 'First Year Engineering', 1, 2),
(14, 'WPU-CSE-2021', 'B.Tech Computer Science', 4, 3),
(15, '112103050', 'B.Tech Computer Engineering', 3, 1),
(16, 'CE2022034', 'B.E. Computer Engineering', 2, 2);

-- ----------------------------------------------------------------------------
-- 7. SPECIALIZATION: DRIVER ENTITY
-- ----------------------------------------------------------------------------
-- WHAT: Registers driving licenses and maintains baseline ratings for drivers.
-- WHY: ISA specialization table for users offering rides with verified driver credentials.
INSERT INTO DRIVER (user_id, license_no, average_rating) VALUES
(1, 'MH12-2020-0045892', 4.90),
(3, 'MH14-2019-0081234', 4.75),
(5, 'MH12-2021-0023411', 4.85),
(7, 'MH12-2018-0099120', 4.60),
(9, 'MH14-2021-0034119', 4.95),
(11, 'MH12-2019-0012890', 4.80),
(13, 'MH12-2020-0077812', 4.50),
(15, 'MH14-2021-0055102', 4.70);

-- ----------------------------------------------------------------------------
-- 8. EMERGENCY CONTACTS (WEAK ENTITY)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts primary and secondary emergency contacts for students.
-- WHY: Fulfills weak entity requirements from ER diagram; contacts are keyed to user_id.
INSERT INTO EMERGENCY_CONTACT (user_id, contact_no, contact_name, phone, relationship) VALUES
(1, 1, 'Ramesh Sharma', '9822099901', 'Father'),
(2, 1, 'Sunita Deshmukh', '9423011102', 'Mother'),
(3, 1, 'Anil Patil', '9158022203', 'Father'),
(4, 1, 'Madhav Kulkarni', '9890133304', 'Father'),
(5, 1, 'Vandana Joshi', '9765444405', 'Mother'),
(6, 1, 'Prakash Shinde', '9604155506', 'Father'),
(7, 1, 'Sunil Mehta', '9823466607', 'Uncle'),
(8, 1, 'Rekha Chavan', '9922177708', 'Mother');

-- ----------------------------------------------------------------------------
-- 9. COMMUNITY MEMBERSHIPS
-- ----------------------------------------------------------------------------
-- WHAT: Subscribes users to appropriate general and college communities.
-- WHY: Populates M:N relation for community-scoped ride filtering.
INSERT INTO COMMUNITY_MEMBER (user_id, community_id) VALUES
(1, 1), (1, 2),
(2, 1), (2, 3),
(3, 1), (3, 4),
(4, 1), (4, 2),
(5, 1), (5, 3),
(6, 1), (6, 4),
(7, 1),
(8, 1), (8, 2),
(9, 1), (9, 3),
(10, 1), (10, 4),
(11, 1), (11, 2),
(12, 1), (12, 3),
(13, 1),
(14, 1), (14, 4),
(15, 1), (15, 2),
(16, 1), (16, 3);

-- ----------------------------------------------------------------------------
-- 10. VEHICLES (10 VEHICLES OWNED BY DRIVERS)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 10 student/driver vehicles ranging from hatchbacks to bikes.
-- WHY: Satisfies the requirement of >=10 vehicles with genuine capacity limits.
INSERT INTO VEHICLE (vehicle_id, driver_id, plate_no, vehicle_type, make, model, color, capacity) VALUES
(1, 1, 'MH12-RN-4589', 'CAR_SEDAN', 'Honda', 'City', 'Silver', 4),
(2, 1, 'MH12-EQ-8812', 'SCOOTER', 'TVS', 'Jupiter', 'Grey', 1),
(3, 3, 'MH14-GH-3321', 'CAR_HATCHBACK', 'Maruti Suzuki', 'Swift', 'Red', 4),
(4, 5, 'MH12-KP-7744', 'CAR_SEDAN', 'Hyundai', 'Verna', 'White', 4),
(5, 7, 'MH12-AB-9901', 'CAR_SUV', 'Tata', 'Nexon', 'Blue', 4),
(6, 9, 'MH14-BC-1102', 'MOTORCYCLE', 'Royal Enfield', 'Classic 350', 'Black', 1),
(7, 9, 'MH14-DX-5509', 'CAR_HATCHBACK', 'Hyundai', 'i20', 'Grey', 4),
(8, 11, 'MH12-CD-6611', 'CAR_SEDAN', 'Skoda', 'Slavia', 'White', 4),
(9, 13, 'MH12-EF-4422', 'CAR_HATCHBACK', 'Tata', 'Altroz', 'Golden', 4),
(10, 15, 'MH14-JK-9933', 'MOTORCYCLE', 'Yamaha', 'FZ-S', 'Midnight Blue', 1);

-- ----------------------------------------------------------------------------
-- 11. RIDE POSTS (26 REALISTIC RIDES)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 26 ride offers covering open upcoming commutes and past completed pools.
-- WHY: Satisfies requirement of at least 25 ride posts with varied route points and statuses.
INSERT INTO RIDE_POST (ride_id, driver_id, vehicle_id, pickup_location_id, destination_location_id, community_id, post_time, departure_time, status, seats_offered, seats_available, estimated_fare, notes) VALUES
-- Active / Upcoming Open Rides
(1, 1, 1, 10, 1, 2, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 3 HOUR), 'OPEN', 3, 2, 60.00, 'Leaving Baner via University circle to COEP main gate. AC car.'),
(2, 3, 3, 8, 4, 4, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 4 HOUR), 'OPEN', 3, 3, 40.00, 'Daily commute from Kothrud stand to MIT-WPU gate.'),
(3, 5, 4, 7, 3, 3, DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_ADD(NOW(), INTERVAL 5 HOUR), 'OPEN', 3, 1, 50.00, 'Katraj to PICT morning run. Fast route via Highway.'),
(4, 9, 6, 6, 3, 3, DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_ADD(NOW(), INTERVAL 6 HOUR), 'OPEN', 1, 1, 35.00, 'Swargate to PICT bike pool. Helmet provided.'),
(5, 11, 8, 9, 1, 2, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 8 HOUR), 'OPEN', 3, 3, 90.00, 'Hinjewadi to COEP evening return batch. Peaceful drive.'),
(6, 15, 10, 12, 1, 1, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 7 HOUR), 'OPEN', 1, 1, 45.00, 'Wakad Bhumkar Chowk to Shivajinagar. Bike pillion.'),
(7, 1, 1, 11, 1, 2, DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_ADD(NOW(), INTERVAL 24 HOUR), 'OPEN', 3, 3, 75.00, 'Viman Nagar Phoenix Mall to COEP Shivajinagar tomorrow.'),
(8, 7, 5, 10, 3, 1, DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_ADD(NOW(), INTERVAL 26 HOUR), 'OPEN', 4, 4, 80.00, 'Baner to PICT via Chandani Chowk and Highway.'),
(9, 3, 3, 6, 4, 4, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 28 HOUR), 'OPEN', 3, 2, 45.00, 'Swargate to MIT Kothrud via Alka Talkies.'),
(10, 5, 4, 12, 3, 3, DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_ADD(NOW(), INTERVAL 30 HOUR), 'OPEN', 3, 3, 85.00, 'Wakad to PICT college. Leaving at 8:30 AM.'),

-- Fully Booked Rides
(11, 1, 1, 5, 1, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 2 HOUR), 'FULL', 3, 0, 30.00, 'Shivajinagar Metro to COEP Gate. Full capacity.'),
(12, 9, 7, 7, 3, 3, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 4 HOUR), 'FULL', 3, 0, 50.00, 'Katraj depot to PICT campus.'),

-- Completed Past Rides (Historical Trips)
(13, 1, 1, 10, 1, 2, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 7 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 0, 60.00, 'Baner to COEP completed successfully.'),
(14, 3, 3, 8, 4, 4, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 6 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 1, 40.00, 'Kothrud to MIT morning pool completed.'),
(15, 5, 4, 7, 3, 3, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 5 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 0, 50.00, 'Katraj to PICT completed.'),
(16, 7, 5, 9, 1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 5 DAY), INTERVAL 2 HOUR), 'COMPLETED', 4, 1, 85.00, 'Hinjewadi to Shivajinagar completed.'),
(17, 9, 6, 6, 3, 3, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 4 DAY), INTERVAL 1 HOUR), 'COMPLETED', 1, 0, 35.00, 'Swargate to PICT bike ride completed.'),
(18, 11, 8, 11, 1, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 4 DAY), INTERVAL 2 HOUR), 'COMPLETED', 3, 0, 75.00, 'Viman Nagar to COEP completed.'),
(19, 13, 9, 12, 4, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 3 DAY), INTERVAL 2 HOUR), 'COMPLETED', 3, 0, 70.00, 'Wakad to MIT-WPU completed.'),
(20, 15, 10, 10, 1, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 3 DAY), INTERVAL 1 HOUR), 'COMPLETED', 1, 0, 45.00, 'Baner to COEP bike ride completed.'),
(21, 1, 1, 5, 1, 2, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 2 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 1, 30.00, 'Metro to COEP completed.'),
(22, 3, 3, 6, 4, 4, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 2 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 0, 45.00, 'Swargate to Kothrud completed.'),
(23, 5, 4, 8, 3, 3, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 0, 55.00, 'Kothrud to PICT completed.'),
(24, 7, 5, 10, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 1 HOUR), 'COMPLETED', 4, 2, 60.00, 'Baner to Shivajinagar completed.'),
(25, 9, 7, 7, 3, 3, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 1 HOUR), 'COMPLETED', 3, 0, 50.00, 'Katraj to PICT completed.'),
(26, 11, 8, 9, 1, 2, DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 10 HOUR), 'CANCELLED', 3, 3, 90.00, 'Cancelled due to college holiday.');

-- ----------------------------------------------------------------------------
-- 12. RIDE STOPS (INTERMEDIATE WAYPOINTS)
-- ----------------------------------------------------------------------------
-- WHAT: Defines stop sequences for selected ride routes.
-- WHY: Implements weak entity RIDE_STOP for multi-hop route testing.
INSERT INTO RIDE_STOP (ride_id, sequence_no, location_id, stop_type, expected_time) VALUES
(1, 1, 10, 'PICKUP', DATE_ADD(NOW(), INTERVAL 3 HOUR)),
(1, 2, 5, 'WAYPOINT', DATE_ADD(DATE_ADD(NOW(), INTERVAL 3 HOUR), INTERVAL 25 MINUTE)),
(1, 3, 1, 'DROPOFF', DATE_ADD(DATE_ADD(NOW(), INTERVAL 3 HOUR), INTERVAL 45 MINUTE)),
(3, 1, 7, 'PICKUP', DATE_ADD(NOW(), INTERVAL 5 HOUR)),
(3, 2, 6, 'WAYPOINT', DATE_ADD(DATE_ADD(NOW(), INTERVAL 5 HOUR), INTERVAL 20 MINUTE)),
(3, 3, 3, 'DROPOFF', DATE_ADD(DATE_ADD(NOW(), INTERVAL 5 HOUR), INTERVAL 40 MINUTE)),
(13, 1, 10, 'PICKUP', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(13, 2, 5, 'WAYPOINT', DATE_ADD(DATE_SUB(NOW(), INTERVAL 7 DAY), INTERVAL 25 MINUTE)),
(13, 3, 1, 'DROPOFF', DATE_ADD(DATE_SUB(NOW(), INTERVAL 7 DAY), INTERVAL 45 MINUTE));

-- ----------------------------------------------------------------------------
-- 13. RIDE REQUESTS (42 REALISTIC BOOKING REQUESTS)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 42 ride requests across pending, accepted, rejected, and cancelled states.
-- WHY: Satisfies requirement of at least 40 requests to test seat allocations and concurrency.
INSERT INTO RIDE_REQUEST (request_id, ride_id, rider_id, seats_requested, message, fare_share, request_time, status) VALUES
-- Requests on upcoming Ride 1 (Offered: 3, Available: 2, 1 Accepted)
(1, 1, 4, 1, 'Hi Aarav, heading to Mechanical dept lab. Can I join?', 60.00, DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'ACCEPTED'),
(2, 1, 8, 1, 'Need a seat from Baner to COEP.', 60.00, DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'PENDING'),
(3, 1, 15, 1, 'Travelling with laptop bag only.', 60.00, DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'PENDING'),

-- Requests on Ride 2
(4, 2, 6, 1, 'Going for morning lecture at MIT.', 40.00, DATE_SUB(NOW(), INTERVAL 45 MINUTE), 'PENDING'),
(5, 2, 10, 1, 'Heading to MBA auditorium.', 40.00, DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'PENDING'),

-- Requests on Ride 3 (Offered: 3, Available: 1, 2 Accepted)
(6, 3, 2, 1, 'Need seat to IT dept PICT.', 50.00, DATE_SUB(NOW(), INTERVAL 120 MINUTE), 'ACCEPTED'),
(7, 3, 12, 1, 'First year student going for physics lab.', 50.00, DATE_SUB(NOW(), INTERVAL 100 MINUTE), 'ACCEPTED'),
(8, 3, 16, 1, 'Any extra space for a backpack?', 50.00, DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'REJECTED'),

-- Requests on Ride 4
(9, 4, 16, 1, 'Regular daily rider from Swargate.', 35.00, DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'PENDING'),

-- Requests on Full Ride 11 (Offered: 3, Available: 0, 3 Accepted)
(10, 11, 4, 1, 'Metro to campus please.', 30.00, DATE_SUB(NOW(), INTERVAL 18 HOUR), 'ACCEPTED'),
(11, 11, 8, 1, 'Booking seat.', 30.00, DATE_SUB(NOW(), INTERVAL 16 HOUR), 'ACCEPTED'),
(12, 11, 15, 1, 'Joining ride.', 30.00, DATE_SUB(NOW(), INTERVAL 14 HOUR), 'ACCEPTED'),

-- Requests on Full Ride 12 (Offered: 3, Available: 0, 3 Accepted)
(13, 12, 2, 1, 'PICT daily commute.', 50.00, DATE_SUB(NOW(), INTERVAL 20 HOUR), 'ACCEPTED'),
(14, 12, 12, 1, 'Morning lecture.', 50.00, DATE_SUB(NOW(), INTERVAL 19 HOUR), 'ACCEPTED'),
(15, 12, 16, 1, 'Regular pooler.', 50.00, DATE_SUB(NOW(), INTERVAL 18 HOUR), 'ACCEPTED'),

-- Requests on Completed Historical Rides (Rides 13 to 25)
-- Ride 13 (3 seats accepted)
(16, 13, 4, 1, 'Lab session travel.', 60.00, DATE_SUB(NOW(), INTERVAL 8 DAY), 'ACCEPTED'),
(17, 13, 8, 1, 'Exam day pool.', 60.00, DATE_SUB(NOW(), INTERVAL 8 DAY), 'ACCEPTED'),
(18, 13, 11, 1, 'Hostel visit.', 60.00, DATE_SUB(NOW(), INTERVAL 8 DAY), 'ACCEPTED'),

-- Ride 14 (2 seats accepted, 1 rejected)
(19, 14, 6, 1, 'MIT campus lecture.', 40.00, DATE_SUB(NOW(), INTERVAL 7 DAY), 'ACCEPTED'),
(20, 14, 10, 1, 'Study group.', 40.00, DATE_SUB(NOW(), INTERVAL 7 DAY), 'ACCEPTED'),
(21, 14, 14, 1, 'Requested late.', 40.00, DATE_SUB(NOW(), INTERVAL 7 DAY), 'REJECTED'),

-- Ride 15 (3 seats accepted)
(22, 15, 2, 1, 'PICT class.', 50.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),
(23, 15, 12, 1, 'Practical viva.', 50.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),
(24, 15, 16, 1, 'Daily commute.', 50.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),

-- Ride 16 (3 seats accepted)
(25, 16, 4, 1, 'Tech fest commute.', 85.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),
(26, 16, 8, 1, 'Joining pool.', 85.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),
(27, 16, 15, 1, 'Meeting friend.', 85.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 'ACCEPTED'),

-- Ride 17 (1 seat accepted)
(28, 17, 2, 1, 'Bike ride to PICT.', 35.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 'ACCEPTED'),

-- Ride 18 (3 seats accepted)
(29, 18, 4, 1, 'Viman Nagar return.', 75.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 'ACCEPTED'),
(30, 18, 8, 1, 'Evening lecture.', 75.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 'ACCEPTED'),
(31, 18, 15, 1, 'COEP event.', 75.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 'ACCEPTED'),

-- Ride 19 (3 seats accepted)
(32, 19, 6, 1, 'Wakad to Kothrud.', 70.00, DATE_SUB(NOW(), INTERVAL 4 DAY), 'ACCEPTED'),
(33, 19, 10, 1, 'Campus pool.', 70.00, DATE_SUB(NOW(), INTERVAL 4 DAY), 'ACCEPTED'),
(34, 19, 14, 1, 'Heading to college.', 70.00, DATE_SUB(NOW(), INTERVAL 4 DAY), 'ACCEPTED'),

-- Ride 20 (1 seat accepted)
(35, 20, 4, 1, 'Quick bike ride to COEP.', 45.00, DATE_SUB(NOW(), INTERVAL 4 DAY), 'ACCEPTED'),

-- Ride 21 (2 seats accepted)
(36, 21, 8, 1, 'Metro connection pool.', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 'ACCEPTED'),
(37, 21, 15, 1, 'Morning pool.', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 'ACCEPTED'),

-- Ride 22 (3 seats accepted)
(38, 22, 6, 1, 'Swargate to MIT.', 45.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 'ACCEPTED'),
(39, 22, 10, 1, 'Joining pool.', 45.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 'ACCEPTED'),
(40, 22, 14, 1, 'Daily run.', 45.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 'ACCEPTED'),

-- Cancelled requests
(41, 1, 14, 1, 'Change of schedule, cancelling.', 60.00, DATE_SUB(NOW(), INTERVAL 2 HOUR), 'CANCELLED'),
(42, 2, 16, 1, 'Found alternate bus.', 40.00, DATE_SUB(NOW(), INTERVAL 1 HOUR), 'CANCELLED');

-- ----------------------------------------------------------------------------
-- 14. TRIPS (15 COMPLETED/SCHEDULED TRIPS)
-- ----------------------------------------------------------------------------
-- WHAT: Inserts 15 trip records (1:1 with ride posts) with real distances and fare splits.
-- WHY: Satisfies the requirement of at least 15 trips for aggregations, window functions, and ratings.
INSERT INTO TRIP (trip_id, ride_id, driver_id, vehicle_id, start_time, end_time, distance_km, total_fare, fare_per_person, status) VALUES
(1, 13, 1, 1, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 7 DAY), INTERVAL 45 MINUTE), 14.50, 180.00, 60.00, 'COMPLETED'),
(2, 14, 3, 3, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 6 DAY), INTERVAL 30 MINUTE), 8.20, 80.00, 40.00, 'COMPLETED'),
(3, 15, 5, 4, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 5 DAY), INTERVAL 35 MINUTE), 9.80, 150.00, 50.00, 'COMPLETED'),
(4, 16, 7, 5, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 5 DAY), INTERVAL 65 MINUTE), 19.30, 255.00, 85.00, 'COMPLETED'),
(5, 17, 9, 6, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 4 DAY), INTERVAL 22 MINUTE), 7.40, 35.00, 35.00, 'COMPLETED'),
(6, 18, 11, 8, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 4 DAY), INTERVAL 50 MINUTE), 16.00, 225.00, 75.00, 'COMPLETED'),
(7, 19, 13, 9, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 3 DAY), INTERVAL 55 MINUTE), 17.50, 210.00, 70.00, 'COMPLETED'),
(8, 20, 15, 10, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 3 DAY), INTERVAL 30 MINUTE), 12.80, 45.00, 45.00, 'COMPLETED'),
(9, 21, 1, 1, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 2 DAY), INTERVAL 20 MINUTE), 4.20, 60.00, 30.00, 'COMPLETED'),
(10, 22, 3, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 2 DAY), INTERVAL 38 MINUTE), 9.10, 135.00, 45.00, 'COMPLETED'),
(11, 23, 5, 4, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 40 MINUTE), 11.20, 165.00, 55.00, 'COMPLETED'),
(12, 24, 7, 5, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 42 MINUTE), 13.00, 120.00, 60.00, 'COMPLETED'),
(13, 25, 9, 7, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 DAY), INTERVAL 33 MINUTE), 9.80, 150.00, 50.00, 'COMPLETED'),
(14, 11, 1, 1, NULL, NULL, 4.20, 90.00, 30.00, 'SCHEDULED'),
(15, 12, 9, 7, NULL, NULL, 9.80, 150.00, 50.00, 'SCHEDULED');

-- ----------------------------------------------------------------------------
-- 15. PAYMENTS (SETTLEMENTS FOR COMPLETED TRIPS)
-- ----------------------------------------------------------------------------
-- WHAT: Records payment transactions for passengers on completed trips.
-- WHY: Establishes monetary audit trails and tests payment verification status.
INSERT INTO PAYMENT (payment_id, trip_id, rider_id, amount, method, status, transaction_reference, payment_time) VALUES
(1, 1, 4, 60.00, 'UPI', 'COMPLETED', 'UPI-20261013-00192', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(2, 1, 8, 60.00, 'CAMPUS_WALLET', 'COMPLETED', 'WAL-20261013-44120', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(3, 1, 11, 60.00, 'UPI', 'COMPLETED', 'UPI-20261013-88712', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(4, 2, 6, 40.00, 'CASH', 'COMPLETED', 'CSH-20261014-11002', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(5, 2, 10, 40.00, 'UPI', 'COMPLETED', 'UPI-20261014-99014', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(6, 3, 2, 50.00, 'UPI', 'COMPLETED', 'UPI-20261015-77123', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(7, 3, 12, 50.00, 'CAMPUS_WALLET', 'COMPLETED', 'WAL-20261015-22341', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(8, 3, 16, 50.00, 'UPI', 'COMPLETED', 'UPI-20261015-99881', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(9, 4, 4, 85.00, 'UPI', 'COMPLETED', 'UPI-20261015-66710', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(10, 4, 8, 85.00, 'DEBIT_CARD', 'COMPLETED', 'CRD-20261015-33129', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(11, 4, 15, 85.00, 'UPI', 'COMPLETED', 'UPI-20261015-44211', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(12, 5, 2, 35.00, 'UPI', 'COMPLETED', 'UPI-20261016-12345', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(13, 6, 4, 75.00, 'CAMPUS_WALLET', 'COMPLETED', 'WAL-20261016-55441', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(14, 6, 8, 75.00, 'UPI', 'COMPLETED', 'UPI-20261016-99120', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(15, 6, 15, 75.00, 'CASH', 'COMPLETED', 'CSH-20261016-77881', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(16, 7, 6, 70.00, 'UPI', 'COMPLETED', 'UPI-20261017-33211', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(17, 7, 10, 70.00, 'UPI', 'COMPLETED', 'UPI-20261017-88711', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(18, 7, 14, 70.00, 'CAMPUS_WALLET', 'COMPLETED', 'WAL-20261017-99123', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(19, 8, 4, 45.00, 'UPI', 'COMPLETED', 'UPI-20261017-44551', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(20, 9, 8, 30.00, 'UPI', 'COMPLETED', 'UPI-20261018-77112', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(21, 9, 15, 30.00, 'CAMPUS_WALLET', 'COMPLETED', 'WAL-20261018-88334', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(22, 10, 6, 45.00, 'UPI', 'COMPLETED', 'UPI-20261018-99441', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(23, 10, 10, 45.00, 'UPI', 'COMPLETED', 'UPI-20261018-33221', DATE_SUB(NOW(), INTERVAL 2 DAY));

-- ----------------------------------------------------------------------------
-- 16. RATINGS & REVIEWS
-- ----------------------------------------------------------------------------
-- WHAT: Inserts reciprocal ratings between riders and drivers for completed trips.
-- WHY: Powers driver rating calculations and demonstrates aggregate/window queries.
INSERT INTO RATING (rating_id, trip_id, rater_user_id, ratee_user_id, score, comment, created_at) VALUES
(1, 1, 4, 1, 5, 'Very punctual and polite driver. Smooth ride to COEP!', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(2, 1, 8, 1, 5, 'Clean car and played relaxing music. Highly recommended.', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(3, 1, 1, 4, 5, 'Great co-passenger, reached pickup location exactly on time.', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(4, 2, 6, 3, 5, 'Good driving and friendly conversation on the way to MIT.', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(5, 2, 10, 3, 4, 'Nice ride, small delay due to Kothrud traffic but handled well.', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(6, 3, 2, 5, 5, 'Siddharth is an excellent driver. Safe driving on highway.', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(7, 3, 12, 5, 5, 'Awesome carpool experience for my first college week.', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(8, 4, 4, 7, 4, 'Very comfortable SUV, comfortable highway ride.', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(9, 4, 8, 7, 5, 'Felt very safe and reached college 15 minutes before time.', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(10, 5, 2, 9, 5, 'Very safe two-wheeler rider. Provided clean extra helmet.', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(11, 6, 4, 11, 5, 'Kabir drove smoothly through Nagar road traffic.', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(12, 6, 8, 11, 5, 'Very courteous and shared good exam tips.', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(13, 7, 6, 13, 4, 'Good driving, steady pace from Wakad to Kothrud.', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(14, 8, 4, 15, 5, 'Super quick bike pool from Baner to COEP.', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(15, 9, 8, 1, 5, 'Aarav is always reliable. 5 stars without doubt.', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(16, 10, 6, 3, 5, 'Always on time, very helpful.', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(17, 11, 2, 5, 5, 'Great pooler, comfortable ride.', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(18, 12, 4, 7, 4, 'Comfortable commute.', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(19, 13, 2, 9, 5, 'Great ride again!', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- ----------------------------------------------------------------------------
-- 17. NOTIFICATIONS
-- ----------------------------------------------------------------------------
-- WHAT: Inserts sample system notifications for driver and rider dashboards.
-- WHY: Simulates transactional notifications generated by ride events.
INSERT INTO NOTIFICATION (notification_id, user_id, type, message, read_status, sent_at) VALUES
(1, 1, 'RIDE_REQUEST', 'Priya Kulkarni requested 1 seat on your ride from Baner to COEP.', TRUE, DATE_SUB(NOW(), INTERVAL 90 MINUTE)),
(2, 4, 'REQUEST_ACCEPTED', 'Aarav Sharma accepted your booking request for ride to COEP!', TRUE, DATE_SUB(NOW(), INTERVAL 80 MINUTE)),
(3, 1, 'RIDE_REQUEST', 'Tanvi Chavan requested 1 seat on your ride from Baner to COEP.', FALSE, DATE_SUB(NOW(), INTERVAL 60 MINUTE)),
(4, 3, 'RIDE_REQUEST', 'Neha Shinde requested 1 seat on your ride to MIT-WPU.', FALSE, DATE_SUB(NOW(), INTERVAL 45 MINUTE)),
(5, 4, 'PAYMENT_RECEIVED', 'Your payment of INR 60.00 for trip #1 was successful.', TRUE, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(6, 1, 'RATING_RECEIVED', 'Priya Kulkarni rated you 5 stars: "Very punctual and polite driver."', TRUE, DATE_SUB(NOW(), INTERVAL 7 DAY));

-- ----------------------------------------------------------------------------
-- 18. INITIAL AUDIT LOGS
-- ----------------------------------------------------------------------------
-- WHAT: Seed records representing historical audit captures.
-- WHY: Demonstrates compliance logging of updates and administrative actions.
INSERT INTO AUDIT_LOG (log_id, table_name, action_type, record_id, changed_by_user_id, old_values, new_values, changed_at) VALUES
(1, 'RIDE_POST', 'UPDATE', 1, 1, '{"seats_available": 3}', '{"seats_available": 2}', DATE_SUB(NOW(), INTERVAL 80 MINUTE)),
(2, 'RIDE_REQUEST', 'UPDATE', 1, 1, '{"status": "PENDING"}', '{"status": "ACCEPTED"}', DATE_SUB(NOW(), INTERVAL 80 MINUTE)),
(3, 'TRIP', 'INSERT', 1, 1, NULL, '{"trip_id": 1, "ride_id": 13, "status": "COMPLETED"}', DATE_SUB(NOW(), INTERVAL 7 DAY));
