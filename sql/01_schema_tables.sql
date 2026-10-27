-- ============================================================================
-- 01_schema_tables.sql: Base Relational Tables & Entity Definitions
-- Directly derived from the CampusPool ER Diagram (docs/rideshare.pdf)
-- Demonstrates Normalization: 1NF, 2NF, 3NF, and BCNF (Database Concepts Ch. 3 & 4)
-- ============================================================================

USE campuspool;

-- ----------------------------------------------------------------------------
-- Cleanup: Drop tables in reverse dependency order (Child tables first)
-- ----------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS AUDIT_LOG;
DROP TABLE IF EXISTS NOTIFICATION;
DROP TABLE IF EXISTS RATING;
DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS TRIP;
DROP TABLE IF EXISTS RIDE_REQUEST;
DROP TABLE IF EXISTS RIDE_STOP;
DROP TABLE IF EXISTS RIDE_POST;
DROP TABLE IF EXISTS LOCATION;
DROP TABLE IF EXISTS VEHICLE;
DROP TABLE IF EXISTS EMERGENCY_CONTACT;
DROP TABLE IF EXISTS DRIVER;
DROP TABLE IF EXISTS STUDENT;
DROP TABLE IF EXISTS USER_PHONE;
DROP TABLE IF EXISTS COMMUNITY_MEMBER;
DROP TABLE IF EXISTS COMMUNITY;
DROP TABLE IF EXISTS COLLEGE;
DROP TABLE IF EXISTS USER;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. COLLEGE Relation (ER Entity: COLLEGE)
-- DBMS Concept: 3NF / BCNF Entity. Candidate Key: college_id
-- ============================================================================
CREATE TABLE COLLEGE (
    college_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- 2. COMMUNITY Relation (ER Entity: COMMUNITY)
-- DBMS Concept: Relational decomposition of campus communities and circles.
-- ============================================================================
CREATE TABLE COMMUNITY (
    community_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('GENERAL', 'COLLEGE', 'CUSTOM') DEFAULT 'GENERAL',
    college_id INT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comm_college FOREIGN KEY (college_id) 
        REFERENCES COLLEGE(college_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 3. USER Relation (ER Entity: USER)
-- DBMS Concepts:
--   a) 1NF: Composite attribute 'name' split into atomic 'first_name', 'last_name'.
--   b) 1NF: Multivalued attribute 'phone_numbers' decomposed to USER_PHONE.
--   c) Derived Attribute: 'age' computed from 'date_of_birth'.
--   d) Candidate Keys: user_id (PK), email (UNIQUE).
-- ============================================================================
CREATE TABLE USER (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY') DEFAULT 'PREFER_NOT_TO_SAY',
    date_of_birth DATE NOT NULL,
    age INT NULL,                                   -- Derived attribute (maintained by trigger)
    profile_photo VARCHAR(255) DEFAULT '/avatars/default.png',
    status ENUM('ACTIVE', 'SUSPENDED', 'INACTIVE') DEFAULT 'ACTIVE',
    is_verified BOOLEAN DEFAULT FALSE,
    joined_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- 4. COMMUNITY_MEMBER Relation (ER Relationship: USER belongs_to COMMUNITY)
-- DBMS Concept: M:N relationship resolved into intersection table with composite PK.
-- ============================================================================
CREATE TABLE COMMUNITY_MEMBER (
    user_id INT NOT NULL,
    community_id INT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, community_id),
    CONSTRAINT fk_cm_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cm_comm FOREIGN KEY (community_id) 
        REFERENCES COMMUNITY(community_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 5. USER_PHONE Relation (ER Multivalued Attribute: USER.phone_numbers)
-- DBMS Concept: 1NF Multivalued Attribute Decomposition.
-- Eliminates non-atomic repeated phone strings into a 1NF child relation.
-- ============================================================================
CREATE TABLE USER_PHONE (
    user_id INT NOT NULL,
    phone_no VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, phone_no),
    CONSTRAINT fk_uphone_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 6. STUDENT Relation (ER ISA Subtype: STUDENT ISA USER)
-- DBMS Concept: Specialization / Subtyping hierarchy.
-- user_id serves as both Primary Key and Foreign Key to USER.
-- ============================================================================
CREATE TABLE STUDENT (
    user_id INT PRIMARY KEY,
    roll_no VARCHAR(50) NOT NULL,
    program VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    college_id INT NOT NULL,
    CONSTRAINT fk_stud_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stud_college FOREIGN KEY (college_id) 
        REFERENCES COLLEGE(college_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 7. DRIVER Relation (ER ISA Subtype: DRIVER ISA USER)
-- DBMS Concept: Specialization / Subtyping hierarchy with Candidate Key license_no.
-- ============================================================================
CREATE TABLE DRIVER (
    user_id INT PRIMARY KEY,
    license_no VARCHAR(50) NOT NULL UNIQUE,
    average_rating DECIMAL(3, 2) DEFAULT 5.00,
    CONSTRAINT fk_driv_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 8. EMERGENCY_CONTACT Relation (ER Weak Entity: EMERGENCY_CONTACT)
-- DBMS Concepts:
--   a) Weak Entity: Depends existentially on USER (identifying relationship).
--   b) Discriminator / Partial Key: contact_no.
--   c) Composite Primary Key: (user_id, contact_no) -> 2NF & 3NF satisfied.
-- ============================================================================
CREATE TABLE EMERGENCY_CONTACT (
    user_id INT NOT NULL,
    contact_no INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, contact_no),
    CONSTRAINT fk_econtact_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 9. VEHICLE Relation (ER Entity: VEHICLE, DRIVER owns VEHICLE)
-- DBMS Concept: 3NF / BCNF Entity. Foreign key driver_id references DRIVER.
-- ============================================================================
CREATE TABLE VEHICLE (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    plate_no VARCHAR(30) NOT NULL UNIQUE,
    vehicle_type ENUM('CAR_SEDAN', 'CAR_HATCHBACK', 'CAR_SUV', 'MOTORCYCLE', 'SCOOTER') NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_veh_driver FOREIGN KEY (driver_id) 
        REFERENCES DRIVER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 10. LOCATION Relation (ER Entity: LOCATION)
-- DBMS Concept: Normalized master catalog for pickup/dropoff points (prevents redundancy).
-- ============================================================================
CREATE TABLE LOCATION (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    type ENUM('CAMPUS_GATE', 'HOSTEL', 'METRO_STATION', 'BUS_STAND', 'JUNCTION', 'LANDMARK') DEFAULT 'LANDMARK',
    address VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    geohash VARCHAR(16) NULL
) ENGINE=InnoDB;

-- ============================================================================
-- 11. RIDE_POST Relation (ER Entity: RIDE_POST)
-- DBMS Concept: Core carpool offer entity with multiple Foreign Keys (3NF).
-- ============================================================================
CREATE TABLE RIDE_POST (
    ride_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    pickup_location_id INT NOT NULL,
    destination_location_id INT NOT NULL,
    community_id INT NULL,
    post_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    departure_time DATETIME NOT NULL,
    status ENUM('OPEN', 'FULL', 'CANCELLED', 'COMPLETED') DEFAULT 'OPEN',
    seats_offered INT NOT NULL,
    seats_available INT NOT NULL,
    estimated_fare DECIMAL(8, 2) NOT NULL,
    notes VARCHAR(255) NULL,
    CONSTRAINT fk_ride_driver FOREIGN KEY (driver_id) 
        REFERENCES DRIVER(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ride_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES VEHICLE(vehicle_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ride_pickup FOREIGN KEY (pickup_location_id) 
        REFERENCES LOCATION(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ride_dest FOREIGN KEY (destination_location_id) 
        REFERENCES LOCATION(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ride_comm FOREIGN KEY (community_id) 
        REFERENCES COMMUNITY(community_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 12. RIDE_STOP Relation (ER Weak Entity: RIDE_STOP)
-- DBMS Concepts:
--   a) Weak Entity: Dependent on RIDE_POST.
--   b) Discriminator / Partial Key: sequence_no.
--   c) Composite Primary Key: (ride_id, sequence_no) -> Full FD satisfies 2NF/3NF.
-- ============================================================================
CREATE TABLE RIDE_STOP (
    ride_id INT NOT NULL,
    sequence_no INT NOT NULL,
    location_id INT NOT NULL,
    stop_type ENUM('PICKUP', 'DROPOFF', 'WAYPOINT') DEFAULT 'WAYPOINT',
    expected_time DATETIME NOT NULL,
    PRIMARY KEY (ride_id, sequence_no),
    CONSTRAINT fk_stop_ride FOREIGN KEY (ride_id) 
        REFERENCES RIDE_POST(ride_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stop_loc FOREIGN KEY (location_id) 
        REFERENCES LOCATION(location_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 13. RIDE_REQUEST Relation (ER Entity: RIDE_REQUEST)
-- DBMS Concept: Passenger booking request entity (M:N between USER and RIDE_POST).
-- ============================================================================
CREATE TABLE RIDE_REQUEST (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    ride_id INT NOT NULL,
    rider_id INT NOT NULL,
    seats_requested INT NOT NULL DEFAULT 1,
    message VARCHAR(255) NULL,
    fare_share DECIMAL(8, 2) NOT NULL,
    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED') DEFAULT 'PENDING',
    CONSTRAINT fk_req_ride FOREIGN KEY (ride_id) 
        REFERENCES RIDE_POST(ride_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_req_rider FOREIGN KEY (rider_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 14. TRIP Relation (ER Entity: TRIP)
-- DBMS Concepts:
--   a) 1:1 Relationship with completed RIDE_POST (ride_id UNIQUE).
--   b) Virtual Generated Column: duration_minutes derived from start_time and end_time.
-- ============================================================================
CREATE TABLE TRIP (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    ride_id INT NOT NULL UNIQUE,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    start_time DATETIME NULL,
    end_time DATETIME NULL,
    distance_km DECIMAL(6, 2) NOT NULL DEFAULT 0.00,
    duration_minutes INT GENERATED ALWAYS AS (
        CASE 
            WHEN start_time IS NOT NULL AND end_time IS NOT NULL 
            THEN TIMESTAMPDIFF(MINUTE, start_time, end_time) 
            ELSE NULL 
        END
    ) VIRTUAL,
    total_fare DECIMAL(8, 2) NOT NULL,
    fare_per_person DECIMAL(8, 2) NOT NULL,
    status ENUM('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'SCHEDULED',
    CONSTRAINT fk_trip_ride FOREIGN KEY (ride_id) 
        REFERENCES RIDE_POST(ride_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_trip_driver FOREIGN KEY (driver_id) 
        REFERENCES DRIVER(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_trip_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES VEHICLE(vehicle_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 15. PAYMENT Relation (ER Entity: PAYMENT)
-- DBMS Concept: Settlement relation with transaction_reference candidate key.
-- ============================================================================
CREATE TABLE PAYMENT (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    rider_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL,
    method ENUM('CASH', 'UPI', 'CAMPUS_WALLET', 'DEBIT_CARD') NOT NULL,
    status ENUM('PENDING', 'COMPLETED', 'REFUNDED', 'FAILED') DEFAULT 'PENDING',
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pay_trip FOREIGN KEY (trip_id) 
        REFERENCES TRIP(trip_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pay_rider FOREIGN KEY (rider_id) 
        REFERENCES USER(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 16. RATING Relation (ER Entity: RATING)
-- DBMS Concept: Peer evaluation entity linking rater, ratee, and trip.
-- ============================================================================
CREATE TABLE RATING (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    rater_user_id INT NOT NULL,
    ratee_user_id INT NOT NULL,
    score TINYINT NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rate_trip FOREIGN KEY (trip_id) 
        REFERENCES TRIP(trip_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rate_rater FOREIGN KEY (rater_user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rate_ratee FOREIGN KEY (ratee_user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 17. NOTIFICATION Relation (ER Entity: NOTIFICATION)
-- DBMS Concept: Reactive notification entity triggered by database events.
-- ============================================================================
CREATE TABLE NOTIFICATION (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('RIDE_REQUEST', 'REQUEST_ACCEPTED', 'REQUEST_REJECTED', 'TRIP_STARTED', 'TRIP_COMPLETED', 'PAYMENT_RECEIVED', 'RATING_RECEIVED', 'REMINDER') NOT NULL,
    message VARCHAR(255) NOT NULL,
    read_status BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 18. AUDIT_LOG Relation
-- DBMS Concept: System audit trail recording row modifications.
-- ============================================================================
CREATE TABLE AUDIT_LOG (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    changed_by_user_id INT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
