-- ============================================================================
-- 08_transactions_demo.sql: Concurrency, Isolation Levels & ACID Demonstration
-- Step-by-step scripts demonstrating pessimistic locking, isolation levels,
-- savepoints, and deadlock detection for examiners.
-- ============================================================================

USE campuspool;

-- ============================================================================
-- SCENARIO 1: ATOMIC SEAT BOOKING WITH PESSIMISTIC LOCKING (FOR UPDATE)
-- ============================================================================
-- WHAT: Demonstrates race condition prevention when 2 riders attempt to take the last seat.
-- WHY: Shows that Session B is blocked waiting until Session A commits or rolls back.

-- ----------------------------------------------------------------------------
-- Instructions for Live Examiner Demo:
-- Open two separate MySQL terminal windows (Session A and Session B).
-- ----------------------------------------------------------------------------

-- [SESSION A]: Starts transaction and locks Ride #1 row
-- Run this in Terminal A:
/*
START TRANSACTION;

-- Session A inspects available seats and locks the specific row exclusively
SELECT ride_id, seats_available, status 
FROM RIDE_POST 
WHERE ride_id = 1 
FOR UPDATE;

-- Simulate rider booking: decrement seats by 1
UPDATE RIDE_POST 
SET seats_available = seats_available - 1 
WHERE ride_id = 1;

-- Notice: DO NOT COMMIT YET! Leave Terminal A open.
*/

-- [SESSION B]: Concurrently attempts to lock and book the same Ride #1
-- Run this in Terminal B while Session A is still uncommitted:
/*
START TRANSACTION;

-- This query in Session B will immediately BLOCK (hang) waiting for Session A's lock:
SELECT ride_id, seats_available 
FROM RIDE_POST 
WHERE ride_id = 1 
FOR UPDATE;

-- Notice: Session B waits up to innodb_lock_wait_timeout seconds.
*/

-- [FINISH SESSION A]: Commit Session A in Terminal A:
/*
COMMIT;
-- Instantly, Session B unblocks and proceeds with the updated seats_available!
*/

-- [CLEANUP SESSION B]: Commit Session B in Terminal B:
/*
COMMIT;
*/


-- ============================================================================
-- SCENARIO 2: SAVEPOINT & PARTIAL ROLLBACK DEMONSTRATION
-- ============================================================================
-- WHAT: Creates a savepoint before an experimental charge, then rolls back to that savepoint.
-- WHY: Demonstrates fine-grained error recovery without aborting the entire parent transaction.

START TRANSACTION;

-- Step 1: Record initial ride note update
UPDATE RIDE_POST 
SET notes = 'Updated notes before savepoint demo' 
WHERE ride_id = 2;

-- Step 2: Establish a named savepoint
SAVEPOINT sp_before_fare_change;

-- Step 3: Experimental fare increase
UPDATE RIDE_POST 
SET estimated_fare = 999.00 
WHERE ride_id = 2;

-- Verify the fare was temporarily changed in this transaction
SELECT ride_id, estimated_fare, notes FROM RIDE_POST WHERE ride_id = 2;

-- Step 4: Undo only the experimental fare change back to the savepoint
ROLLBACK TO SAVEPOINT sp_before_fare_change;

-- Step 5: Verify that notes remain updated, but fare was reverted!
SELECT ride_id, estimated_fare, notes FROM RIDE_POST WHERE ride_id = 2;

-- Step 6: Commit the remaining valid work
COMMIT;


-- ============================================================================
-- SCENARIO 3: TRANSACTION ISOLATION LEVELS (REPEATABLE READ VS READ COMMITTED)
-- ============================================================================
-- WHAT: Explains and tests MySQL default REPEATABLE READ vs READ COMMITTED.
-- WHY: Shows how repeatable reads guarantee snapshot consistency throughout a transaction.

-- Demonstration in REPEATABLE READ (Default):
/*
-- Session 1:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT AVG(estimated_fare) FROM RIDE_POST WHERE status = 'OPEN'; -- e.g., returns 55.00

-- Session 2 (Concurrent):
START TRANSACTION;
INSERT INTO RIDE_POST (driver_id, vehicle_id, pickup_location_id, destination_location_id, departure_time, status, seats_offered, seats_available, estimated_fare)
VALUES (1, 1, 1, 3, DATE_ADD(NOW(), INTERVAL 1 DAY), 'OPEN', 3, 3, 200.00);
COMMIT;

-- Session 1 (Re-runs the exact same query):
SELECT AVG(estimated_fare) FROM RIDE_POST WHERE status = 'OPEN';
-- In REPEATABLE READ: Output is STILL 55.00 (Consistent Read Snapshot, non-repeatable read prevented!).

COMMIT;
-- After commit, Session 1 sees the new average.
*/


-- ============================================================================
-- SCENARIO 4: DEADLOCK DETECTION AND AUTOMATIC RESOLUTION
-- ============================================================================
-- WHAT: Two transactions acquire locks in reverse order, creating a cyclic dependency.
-- WHY: Proves MySQL InnoDB deadlock engine detects circular waits and rolls back the cheaper transaction.

/*
-- Terminal 1 (Transaction 1):
START TRANSACTION;
UPDATE RIDE_POST SET notes = 'T1 locking Ride 1' WHERE ride_id = 1;

-- Terminal 2 (Transaction 2):
START TRANSACTION;
UPDATE RIDE_POST SET notes = 'T2 locking Ride 2' WHERE ride_id = 2;

-- Terminal 1: Now tries to update Ride 2 (Blocks waiting for T2 lock):
UPDATE RIDE_POST SET notes = 'T1 wants Ride 2' WHERE ride_id = 2;

-- Terminal 2: Now tries to update Ride 1 (Deadlock cycle created!):
UPDATE RIDE_POST SET notes = 'T2 wants Ride 1' WHERE ride_id = 1;

-- INNODB ENGINE RESPONSE:
-- MySQL immediately detects the cycle and outputs:
-- ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
-- One transaction is automatically chosen as victim and rolled back, while the other completes!
*/
