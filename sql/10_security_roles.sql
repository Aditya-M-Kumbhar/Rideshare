-- ============================================================================
-- 10_security_roles.sql: Authorization, Privileges & Roles (DCL)
-- Directly maps to Database System Concepts (Chapter 4, Slides 4.20-4.23):
--   1. Forms of Authorization: SELECT, INSERT, UPDATE, DELETE, EXECUTE (Slide 4.20)
--   2. Roles: CREATE ROLE (Slide 4.21)
--   3. Grant Statement: GRANT <privileges> ON <relation> TO <role> (Slide 4.21, 4.22)
--   4. Revoke Statement: REVOKE <privileges> FROM <role> (Slide 4.23)
-- ============================================================================

USE campuspool;

-- ============================================================================
-- 1. CREATE ROLES (Silberschatz Slide 4.21)
-- Defines least-privilege security roles.
-- ============================================================================
CREATE ROLE IF NOT EXISTS app_role;
CREATE ROLE IF NOT EXISTS admin_role;
CREATE ROLE IF NOT EXISTS readonly_role;

-- ============================================================================
-- 2. GRANT PRIVILEGES TO ROLES (Silberschatz Slides 4.21, 4.22)
-- ============================================================================

-- A. Application Role: Execute procedures and read/write essential tables
GRANT EXECUTE ON campuspool.* TO app_role;

-- SELECT privileges on views and catalogs
GRANT SELECT ON campuspool.vw_available_rides TO app_role;
GRANT SELECT ON campuspool.vw_masked_users TO app_role;
GRANT SELECT ON campuspool.vw_driver_leaderboard TO app_role;
GRANT SELECT ON campuspool.COLLEGE TO app_role;
GRANT SELECT ON campuspool.COMMUNITY TO app_role;
GRANT SELECT ON campuspool.COMMUNITY_MEMBER TO app_role;
GRANT SELECT ON campuspool.LOCATION TO app_role;
GRANT SELECT ON campuspool.VEHICLE TO app_role;

-- DML Privileges for standard operational workflows
GRANT SELECT, INSERT ON campuspool.USER TO app_role;
GRANT SELECT, INSERT ON campuspool.STUDENT TO app_role;
GRANT SELECT, INSERT ON campuspool.DRIVER TO app_role;
GRANT SELECT, INSERT ON campuspool.USER_PHONE TO app_role;
GRANT SELECT, INSERT ON campuspool.EMERGENCY_CONTACT TO app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON campuspool.RIDE_POST TO app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON campuspool.RIDE_REQUEST TO app_role;
GRANT SELECT, INSERT, UPDATE ON campuspool.TRIP TO app_role;
GRANT SELECT, INSERT, UPDATE ON campuspool.PAYMENT TO app_role;
GRANT SELECT, INSERT ON campuspool.RATING TO app_role;
GRANT SELECT, INSERT, UPDATE ON campuspool.NOTIFICATION TO app_role;

-- B. Admin Role: Full database privileges (Slide 4.22: "all privileges")
GRANT ALL PRIVILEGES ON campuspool.* TO admin_role;

-- C. Read-Only Role: Read access only (Slide 4.20: "Read - allows reading, but not modification")
GRANT SELECT ON campuspool.* TO readonly_role;

-- ============================================================================
-- 3. REVOKE PRIVILEGES DEMONSTRATION (Silberschatz Slide 4.23)
-- Demonstrates granting and then revoking privileges to enforce least privilege.
-- ============================================================================
-- Step A: Grant DELETE on RIDE_POST
GRANT DELETE ON campuspool.RIDE_POST TO app_role;

-- Step B: Revoke DELETE from app_role (proves privilege withdrawal)
REVOKE DELETE ON campuspool.RIDE_POST FROM app_role;

-- ============================================================================
-- 4. APPLICATION USER & ROLE ASSIGNMENT
-- ============================================================================
CREATE USER IF NOT EXISTS 'campus_app'@'localhost' IDENTIFIED BY 'AppPassword123!';
CREATE USER IF NOT EXISTS 'campus_app'@'%' IDENTIFIED BY 'AppPassword123!';

-- Assign the app_role to the service account
GRANT app_role TO 'campus_app'@'localhost';
GRANT app_role TO 'campus_app'@'%';

-- Activate default role for connection
SET DEFAULT ROLE app_role TO 'campus_app'@'localhost';
SET DEFAULT ROLE app_role TO 'campus_app'@'%';
