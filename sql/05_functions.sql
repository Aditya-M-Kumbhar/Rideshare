-- ============================================================================
-- 05_functions.sql: Stored Functions
-- Demonstrates User-Defined Functions & Deterministic Computations (Ch. 4)
-- ============================================================================

USE campuspool;

DROP FUNCTION IF EXISTS fn_mask_id;
DROP FUNCTION IF EXISTS fn_calculate_fare_share;
DROP FUNCTION IF EXISTS fn_distance_km;
DROP FUNCTION IF EXISTS fn_rating_badge;

DELIMITER //

-- ============================================================================
-- 1. IDENTIFIER MASKING FUNCTION (String Operations - Ch. 3, Slide 3.18)
-- Replaces middle characters of sensitive IDs (plates, roll numbers) with asterisks.
-- ============================================================================
CREATE FUNCTION fn_mask_id(
    input_str VARCHAR(100),
    prefix_len INT,
    suffix_len INT
) 
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE str_len INT;
    IF input_str IS NULL OR input_str = '' THEN
        RETURN 'N/A';
    END IF;
    SET str_len = CHAR_LENGTH(input_str);
    IF str_len <= (prefix_len + suffix_len) THEN
        RETURN CONCAT(LEFT(input_str, 1), '****');
    END IF;
    RETURN CONCAT(LEFT(input_str, prefix_len), '****', RIGHT(input_str, suffix_len));
END //

-- ============================================================================
-- 2. FARE SHARE CALCULATOR (Arithmetic Expressions - Ch. 3, Slide 3.12)
-- Divides total trip cost equally among all riders plus the driver.
-- ============================================================================
CREATE FUNCTION fn_calculate_fare_share(
    total_cost DECIMAL(8, 2),
    rider_count INT
) 
RETURNS DECIMAL(8, 2)
DETERMINISTIC
BEGIN
    DECLARE total_people INT;
    IF total_cost IS NULL OR total_cost <= 0.00 THEN
        RETURN 0.00;
    END IF;
    SET total_people = COALESCE(rider_count, 1) + 1; -- Riders + 1 Driver
    RETURN ROUND(total_cost / total_people, 2);
END //

-- ============================================================================
-- 3. HAVERSINE DISTANCE FUNCTION (Spherical Geometry in Kilometers)
-- Computes Great-Circle distance between two coordinates directly in SQL.
-- ============================================================================
CREATE FUNCTION fn_distance_km(
    lat1 DECIMAL(10, 7),
    lon1 DECIMAL(10, 7),
    lat2 DECIMAL(10, 7),
    lon2 DECIMAL(10, 7)
)
RETURNS DECIMAL(8, 2)
DETERMINISTIC
BEGIN
    DECLARE d_lat, d_lon, a, c DECIMAL(14, 10);
    IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
        RETURN 0.00;
    END IF;
    IF lat1 = lat2 AND lon1 = lon2 THEN
        RETURN 0.00;
    END IF;
    SET d_lat = RADIANS(lat2 - lat1);
    SET d_lon = RADIANS(lon2 - lon1);
    SET a = SIN(d_lat / 2) * SIN(d_lat / 2) +
            COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
            SIN(d_lon / 2) * SIN(d_lon / 2);
    SET c = 2 * ATAN2(SQRT(a), SQRT(1 - a));
    RETURN ROUND(6371.00 * c, 2);
END //

-- ============================================================================
-- 4. RATING BADGE CLASSIFIER (Conditional Expressions - Ch. 3, Slide 3.55)
-- Returns reputation tier label based on numeric star score.
-- ============================================================================
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
