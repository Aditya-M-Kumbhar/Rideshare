-- WHAT: Creates the database for CampusPool if it does not already exist.
-- WHY: Provides an isolated workspace for all ride-sharing tables and routines without conflicting with other databases.
CREATE DATABASE IF NOT EXISTS campuspool
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- WHAT: Switches the active connection context to campuspool.
-- WHY: Ensures all subsequent tables, procedures, and views are built inside the correct database.
USE campuspool;
