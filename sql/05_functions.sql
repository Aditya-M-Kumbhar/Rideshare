-- ============================================================================
-- 05_functions.sql: Stored Functions
-- Demonstrates deterministic calculation functions, Haversine spherical math,
-- string masking algorithms, and dynamic fare splitting in pure SQL.
-- ============================================================================

USE campuspool;

DROP FUNCTION IF EXISTS fn_mask_id;
DROP FUNCTION IF EXISTS fn_calculate_fare_share;
DROP FUNCTION IF EXISTS fn_distance_km;
DROP FUNCTION IF EXISTS fn_rating_badge;

DELIMITER //

-- ----------------------------------------------------------------------------
-- 1. IDENTIFIER MASKING FUNCTION
-- ----------------------------------------------------------------------------
-- WHAT: Masks any string by retaining prefix and suffix while replacing the middle with asterisks.
-- WHY: Reusable security routine to sanitize vehicle plates (MH12****34) or phone numbers without repeating code.
CREATE FUNCTION fn_mask_id(
    input_str VARCHAR(100),
    prefix_len INT,
    suffix_len INT
) 
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE str_len INT;
    DECLARE masked_result VARCHAR(100);
    
    IF input_str IS NULL OR input_str = '' THEN
        RETURN 'N/A';
    END IF;
    
    SET str_len = CHAR_LENGTH(input_str);
    
    -- If string is too short to mask gracefully, return first char + asterisks
    IF str_len <= (prefix_len + suffix_len) THEN
        RETURN CONCAT(LEFT(input_str, 1), '****');
    END IF;
    
    SET masked_result = CONCAT(
        LEFT(input_str, prefix_len),
        REPEAT('*', 4),
        RIGHT(input_str, suffix_len)
    );
    
    RETURN masked_result;
END //

-- ----------------------------------------------------------------------------
-- 2. FARE SHARE CALCULATOR
-- ----------------------------------------------------------------------------
-- WHAT: Divides estimated trip fuel/toll cost evenly among the total group (riders + 1 driver).
-- WHY: Enforces fair carpooling cost sharing where the driver also absorbs one equal share.
CREATE FUNCTION fn_calculate_fare_share(
    total_cost DECIMAL(8, 2),
    rider_count INT
) 
RETURNS DECIMAL(8, 2)
DETERMINISTIC
BEGIN
    DECLARE total_passengers INT;
    DECLARE calculated_share DECIMAL(8, 2);
    
    IF total_cost IS NULL OR total_cost <= 0.00 THEN
        RETURN 0.00;
    END IF;
    
    -- Minimum group is 1 rider + 1 driver = 2 people
    IF rider_count IS NULL OR rider_count < 1 THEN
        SET total_passengers = 2;
    ELSE
        SET total_passengers = rider_count + 1;
    END IF;
    
    -- Round up to nearest integer rupee for smooth campus transactions
    SET calculated_share = ROUND(total_cost / total_passengers, 2);
    RETURN calculated_share;
END //

-- ----------------------------------------------------------------------------
-- 3. HAVERSINE SPHERICAL DISTANCE FUNCTION (KILOMETERS)
-- ----------------------------------------------------------------------------
-- WHAT: Computes Great-Circle distance in kilometers between two GPS coordinates (lat1, lon1) and (lat2, lon2).
-- WHY: Enables dynamic distance calculation and route proximity queries directly in the database without external APIs.
CREATE FUNCTION fn_distance_km(
    lat1 DECIMAL(10, 7),
    lon1 DECIMAL(10, 7),
    lat2 DECIMAL(10, 7),
    lon2 DECIMAL(10, 7)
)
RETURNS DECIMAL(8, 2)
DETERMINISTIC
BEGIN
    DECLARE earth_radius_km DECIMAL(8, 2) DEFAULT 6371.00;
    DECLARE d_lat DECIMAL(12, 9);
    DECLARE d_lon DECIMAL(12, 9);
    DECLARE a DECIMAL(14, 10);
    DECLARE c DECIMAL(14, 10);
    DECLARE distance_val DECIMAL(8, 2);
    
    -- If coordinates are identical or null, distance is 0
    IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
        RETURN 0.00;
    END IF;
    
    IF lat1 = lat2 AND lon1 = lon2 THEN
        RETURN 0.00;
    END IF;
    
    -- Convert coordinate degree differences to radians
    SET d_lat = RADIANS(lat2 - lat1);
    SET d_lon = RADIANS(lon2 - lon1);
    
    -- Haversine formula: a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
    SET a = SIN(d_lat / 2) * SIN(d_lat / 2) +
            COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
            SIN(d_lon / 2) * SIN(d_lon / 2);
            
    -- c = 2 * atan2(√a, √(1-a))
    SET c = 2 * ATAN2(SQRT(a), SQRT(1 - a));
    
    SET distance_val = ROUND(earth_radius_km * c, 2);
    RETURN distance_val;
END //

-- ----------------------------------------------------------------------------
-- 4. RATING BADGE TEXT CLASSIFIER
-- ----------------------------------------------------------------------------
-- WHAT: Converts numeric star rating into a descriptive peer badge string.
-- WHY: Standardizes driver reputation display in UI cards and examiner reports.
CREATE FUNCTION fn_rating_badge(score DECIMAL(3, 2))
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    IF score IS NULL THEN
        RETURN 'New Driver';
    ELSEIF score >= 4.80 THEN
        RETURN 'Top Rated ⭐';
    ELSEIF score >= 4.50 THEN
        RETURN 'Highly Rated 👍';
    ELSEIF score >= 4.00 THEN
        RETURN 'Reliable Driver';
    ELSE
        RETURN 'Standard Driver';
    END IF;
END //

DELIMITER ;
