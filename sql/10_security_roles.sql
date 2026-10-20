-- ============================================================================
-- 10_security_roles.sql: Data Control Language (DCL) & Least-Privilege Security
-- Implements RBAC with app_role, admin_role, and readonly_role.
-- ============================================================================

USE campuspool;

-- ----------------------------------------------------------------------------
-- 1. CREATE ROLES
-- ----------------------------------------------------------------------------
-- WHAT: Creates 3 discrete security roles for the application, DBA, and auditors.
-- WHY: Enables least-privilege access control without assigning raw table rights directly to accounts.
CREATE ROLE IF NOT EXISTS app_role;
CREATE ROLE IF NOT EXISTS admin_role;
CREATE ROLE IF NOT EXISTS readonly_role;

-- ----------------------------------------------------------------------------
-- 2. ASSIGN PRIVILEGES TO ROLES
-- ----------------------------------------------------------------------------
-- WHAT: Grants the app_role permission to EXECUTE procedures and SELECT from views and essential tables.
-- WHY: Prevents SQL injection or compromised server code from executing arbitrary DDL, DROP, or DELETE statements.
GRANT EXECUTE ON campuspool.* TO app_role;

-- Read-only views and reference catalogs for frontend consumption
GRANT SELECT ON campuspool.vw_available_rides TO app_role;
GRANT SELECT ON campuspool.vw_masked_users TO app_role;
GRANT SELECT ON campuspool.vw_driver_leaderboard TO app_role;
GRANT SELECT ON campuspool.COLLEGE TO app_role;
GRANT SELECT ON campuspool.COMMUNITY TO app_role;
GRANT SELECT ON campuspool.COMMUNITY_MEMBER TO app_role;
GRANT SELECT ON campuspool.LOCATION TO app_role;
GRANT SELECT ON campuspool.VEHICLE TO app_role;
GRANT SELECT, INSERT ON campuspool.USER TO app_role;
GRANT SELECT, INSERT ON campuspool.STUDENT TO app_role;
GRANT SELECT, INSERT ON campuspool.DRIVER TO app_role;
GRANT SELECT, INSERT ON campuspool.USER_PHONE TO app_role;
GRANT SELECT, INSERT ON campuspool.EMERGENCY_CONTACT TO app_role;
GRANT SELECT ON campuspool.RIDE_POST TO app_role;
GRANT SELECT ON campuspool.RIDE_STOP TO app_role;
GRANT SELECT ON campuspool.RIDE_REQUEST TO app_role;
GRANT SELECT ON campuspool.TRIP TO app_role;
GRANT SELECT ON campuspool.PAYMENT TO app_role;
GRANT SELECT ON campuspool.RATING TO app_role;
GRANT SELECT, UPDATE ON campuspool.NOTIFICATION TO app_role;

-- Admin role has full control over the database
GRANT ALL PRIVILEGES ON campuspool.* TO admin_role;

-- Read-only role for campus audit examiners and report generators
GRANT SELECT ON campuspool.* TO readonly_role;

-- ----------------------------------------------------------------------------
-- 3. CREATE LEAST-PRIVILEGE SERVICE USERS & ASSIGN ROLES
-- ----------------------------------------------------------------------------
-- WHAT: Creates dedicated accounts for the Node.js backend and reporting tools.
-- WHY: Eliminates connecting as root in production or during university viva presentations.

-- Application Service Account (Used by Node.js backend)
CREATE USER IF NOT EXISTS 'campus_app'@'localhost' IDENTIFIED BY 'AppPassword123!';
CREATE USER IF NOT EXISTS 'campus_app'@'%' IDENTIFIED BY 'AppPassword123!';
GRANT app_role TO 'campus_app'@'localhost', 'campus_app'@'%';
SET DEFAULT ROLE app_role TO 'campus_app'@'localhost', 'campus_app'@'%';

-- Campus Auditor / Examiner Account
CREATE USER IF NOT EXISTS 'campus_auditor'@'localhost' IDENTIFIED BY 'AuditPass123!';
GRANT readonly_role TO 'campus_auditor'@'localhost';
SET DEFAULT ROLE readonly_role TO 'campus_auditor'@'localhost';

-- Refresh MySQL privilege tables
FLUSH PRIVILEGES;
