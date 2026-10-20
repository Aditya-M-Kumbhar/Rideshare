-- ============================================================================
-- run_all.sql: Master Orchestration Script
-- Executes all SQL initialization modules in proper relational dependency order.
-- Usage: mysql -u root -p < sql/run_all.sql
-- ============================================================================

-- WHAT: Sets feedback echo and switches into campuspool database.
-- WHY: Provides clear console progress output during batch evaluation.
SELECT '>>> Starting CampusPool Database Initialization...' AS status;

-- 1. Database Creation
SOURCE 00_create_database.sql;

-- 2. Base Relational Tables & Entities
SOURCE 01_schema_tables.sql;

-- 3. Check Constraints & Composite Indexes
SOURCE 02_constraints_indexes.sql;

-- 4. Realistic Seed Dataset (Users, Rides, Requests, Trips, Payments)
SOURCE 03_seed_data.sql;

-- 5. Views (Masked Privacy Catalog, Available Rides, Leaderboards)
SOURCE 04_views.sql;

-- 6. Stored Functions (Masking, Haversine, Fare Calculation)
SOURCE 05_functions.sql;

-- 7. Stored Procedures (Transactional Operations & Handlers)
SOURCE 06_stored_procedures.sql;

-- 8. Triggers (Reactive Integrity, Audit, Ratings, Alerts)
SOURCE 07_triggers.sql;

-- 9. Events & Cursors (Ride Expiration & Batch Reminders)
SOURCE 09_events_cursors.sql;

-- 10. Security Roles & Grants (app_role, admin_role, readonly_role)
SOURCE 10_security_roles.sql;

SELECT '>>> CampusPool Database Successfully Built and Seeded!' AS status;
