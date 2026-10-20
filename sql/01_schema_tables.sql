-- ============================================================================
-- 01_schema_tables.sql: Base Tables and Entity Definitions
-- Derived from rideshare.pdf ER diagram with normalization to 3NF/BCNF
-- ============================================================================

USE campuspool;

-- WHAT: Drops existing tables in reverse dependency order.
-- WHY: Allows clean re-running of schema scripts during development and evaluation without foreign key errors.
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

-- WHAT: Stores participating university campuses with geographic coordinates.
-- WHY: Rides and communities are centered around colleges, enabling geocoding and campus verification.
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

-- WHAT: Defines trust-based ride-sharing groups (General, specific College, or Custom).
-- WHY: Lets riders restrict pools to people from their own college or verified circles for safety.
CREATE TABLE COMMUNITY (
    community_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('GENERAL', 'COLLEGE', 'CUSTOM') DEFAULT 'GENERAL',
    college_id INT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_community_college FOREIGN KEY (college_id) 
        REFERENCES COLLEGE(college_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Master user entity with personal details, status, and verification state.
-- WHY: Central identity table representing all participants (both drivers and riders) in 3NF.
CREATE TABLE USER (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY') DEFAULT 'PREFER_NOT_TO_SAY',
    date_of_birth DATE NOT NULL,
    -- Derived attribute: age calculated from date of birth
    age INT GENERATED ALWAYS AS (TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())) VIRTUAL,
    profile_photo VARCHAR(255) DEFAULT '/avatars/default.png',
    status ENUM('ACTIVE', 'SUSPENDED', 'INACTIVE') DEFAULT 'ACTIVE',
    is_verified BOOLEAN DEFAULT FALSE,
    joined_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- WHAT: Associates users with communities they belong to.
-- WHY: Resolves the M:N relationship between USER and COMMUNITY with timestamp tracking.
CREATE TABLE COMMUNITY_MEMBER (
    user_id INT NOT NULL,
    community_id INT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, community_id),
    CONSTRAINT fk_cm_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cm_community FOREIGN KEY (community_id) 
        REFERENCES COMMUNITY(community_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Stores phone numbers for users.
-- WHY: Resolves the multivalued 'phone_numbers' attribute from the ER diagram to maintain 1NF.
CREATE TABLE USER_PHONE (
    user_id INT NOT NULL,
    phone_no VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, phone_no),
    CONSTRAINT fk_phone_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Subtype entity for users enrolled in an academic institution (ISA specialization).
-- WHY: Keeps college-specific academic attributes separate from general users (3NF normalization).
CREATE TABLE STUDENT (
    user_id INT PRIMARY KEY,
    roll_no VARCHAR(50) NOT NULL,
    program VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    college_id INT NOT NULL,
    CONSTRAINT fk_student_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_student_college FOREIGN KEY (college_id) 
        REFERENCES COLLEGE(college_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Subtype entity for users registered to drive vehicles (ISA specialization).
-- WHY: Isolates driver license data and maintains dynamic driver ratings.
CREATE TABLE DRIVER (
    user_id INT PRIMARY KEY,
    license_no VARCHAR(50) NOT NULL UNIQUE,
    average_rating DECIMAL(3, 2) DEFAULT 5.00,
    CONSTRAINT fk_driver_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Weak entity storing emergency contacts for users (identified by user_id + contact_no).
-- WHY: Ensures campus safety compliance; contacts have no independent identity outside their user.
CREATE TABLE EMERGENCY_CONTACT (
    user_id INT NOT NULL,
    contact_no INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, contact_no),
    CONSTRAINT fk_contact_user FOREIGN KEY (user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Stores vehicle details owned and operated by verified drivers.
-- WHY: Required for assigning seats, verifying vehicle capacity, and checking license plate numbers.
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
    CONSTRAINT fk_vehicle_driver FOREIGN KEY (driver_id) 
        REFERENCES DRIVER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Geographic points of interest, campus gates, transit hubs, and student hostels.
-- WHY: Eliminates redundant coordinate and address storage across rides and stops (3NF).
CREATE TABLE LOCATION (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    type ENUM('CAMPUS_GATE', 'HOSTEL', 'METRO_STATION', 'BUS_STAND', 'JUNCTION', 'LANDMARK') DEFAULT 'LANDMARK',
    address VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    geohash VARCHAR(16) NULL
) ENGINE=InnoDB;

-- WHAT: Ride offers posted by drivers with departure time, route endpoints, and seat quotas.
-- WHY: Core entity allowing drivers to announce carpool availability and set cost share.
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
    CONSTRAINT fk_ride_destination FOREIGN KEY (destination_location_id) 
        REFERENCES LOCATION(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ride_community FOREIGN KEY (community_id) 
        REFERENCES COMMUNITY(community_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Ordered intermediate waypoints for a ride post (weak entity of RIDE_POST).
-- WHY: Supports multi-stop pooling routes with estimated arrival times along the commute.
CREATE TABLE RIDE_STOP (
    ride_id INT NOT NULL,
    sequence_no INT NOT NULL,
    location_id INT NOT NULL,
    stop_type ENUM('PICKUP', 'DROPOFF', 'WAYPOINT') DEFAULT 'WAYPOINT',
    expected_time DATETIME NOT NULL,
    PRIMARY KEY (ride_id, sequence_no),
    CONSTRAINT fk_stop_ride FOREIGN KEY (ride_id) 
        REFERENCES RIDE_POST(ride_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stop_location FOREIGN KEY (location_id) 
        REFERENCES LOCATION(location_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: Booking requests submitted by riders to join a specific ride post.
-- WHY: Implements request-and-accept workflow with seat hold validation and fare confirmation.
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

-- WHAT: Execution record of an accepted ride (1:1 relationship with completed/started ride post).
-- WHY: Records actual trip execution, real distance, time duration, and final calculated fares.
CREATE TABLE TRIP (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    ride_id INT NOT NULL UNIQUE,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    start_time DATETIME NULL,
    end_time DATETIME NULL,
    distance_km DECIMAL(6, 2) NOT NULL DEFAULT 0.00,
    -- Duration in minutes calculated when end_time is populated
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

-- WHAT: Financial settlement record for a passenger participating in a trip.
-- WHY: Manages payment integrity, methods, transaction references, and audit tracking.
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

-- WHAT: Mutual peer review and feedback submitted after a trip completes.
-- WHY: Cultivates safety and accountability in campus pooling by calculating verified driver ratings.
CREATE TABLE RATING (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    rater_user_id INT NOT NULL,
    ratee_user_id INT NOT NULL,
    score TINYINT NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rating_trip FOREIGN KEY (trip_id) 
        REFERENCES TRIP(trip_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rating_rater FOREIGN KEY (rater_user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rating_ratee FOREIGN KEY (ratee_user_id) 
        REFERENCES USER(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- WHAT: System alerts dispatched to users on ride milestones, requests, and updates.
-- WHY: Keeps riders and drivers instantly informed without polling or manual message tracking.
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

-- WHAT: Immutable audit trail logging critical row modifications and security events.
-- WHY: Satisfies enterprise compliance, monitors trigger actions, and supports forensic rollbacks.
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
