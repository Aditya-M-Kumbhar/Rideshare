-- ============================================================================
-- 08_transactions_demo.sql: ACID Transactions & Concurrency Control
-- Demonstrates Concepts from Database System Concepts (Chapter 4):
--   1. ACID Properties: START TRANSACTION, COMMIT, ROLLBACK
--   2. Pessimistic Concurrency Control: SELECT ... FOR UPDATE
--   3. Partial Rollback: SAVEPOINT and ROLLBACK TO SAVEPOINT
--   4. Deadlock Detection & Resolution
-- ============================================================================

USE campuspool;

-- ============================================================================
-- SCENARIO 1: PESSIMISTIC ROW LOCKING (SELECT ... FOR UPDATE)
-- Prevents race conditions when two riders attempt to book the last seat.
-- ============================================================================
-- Terminal A (Session 1):
-- START TRANSACTION;
-- SELECT ride_id, seats_available FROM RIDE_POST WHERE ride_id = 1 FOR UPDATE;
-- UPDATE RIDE_POST SET seats_available = seats_available - 1 WHERE ride_id = 1;
-- (Leave Session 1 open without committing)

-- Terminal B (Session 2 concurrently):
-- START TRANSACTION;
-- SELECT ride_id, seats_available FROM RIDE_POST WHERE ride_id = 1 FOR UPDATE;
-- (Session 2 immediately BLOCKS waiting for Session 1 lock)

-- Terminal A:
-- COMMIT; -- Session 2 instantly unblocks with accurate seat count!

-- ============================================================================
-- SCENARIO 2: SAVEPOINT & PARTIAL ROLLBACK (Silberschatz ACID Mechanics)
-- Allows undoing a sub-operation without discarding the entire transaction.
-- ============================================================================
START TRANSACTION;

-- Step 1: Update ride note
UPDATE RIDE_POST SET notes = 'Notes updated before savepoint' WHERE ride_id = 2;

-- Step 2: Set Savepoint
SAVEPOINT sp_before_fare_change;

-- Step 3: Experimental invalid fare change
UPDATE RIDE_POST SET estimated_fare = 9999.00 WHERE ride_id = 2;

-- Step 4: Undo only the experimental fare update
ROLLBACK TO SAVEPOINT sp_before_fare_change;

-- Step 5: Commit the transaction (note update is preserved, fare is reverted)
COMMIT;

-- Verify results:
SELECT ride_id, estimated_fare, notes FROM RIDE_POST WHERE ride_id = 2;

-- ============================================================================
-- SCENARIO 3: DEADLOCK DETECTION
-- Two transactions acquiring locks in reverse order create a circular wait.
-- ============================================================================
-- Terminal 1:
-- START TRANSACTION;
-- UPDATE RIDE_POST SET notes = 'T1 locks Ride 1' WHERE ride_id = 1;

-- Terminal 2:
-- START TRANSACTION;
-- UPDATE RIDE_POST SET notes = 'T2 locks Ride 2' WHERE ride_id = 2;

-- Terminal 1 (requests Ride 2, blocks):
-- UPDATE RIDE_POST SET notes = 'T1 requests Ride 2' WHERE ride_id = 2;

-- Terminal 2 (requests Ride 1, deadlock cycle created!):
-- UPDATE RIDE_POST SET notes = 'T2 requests Ride 1' WHERE ride_id = 1;

-- INNODB ENGINE RESULT:
-- ERROR 1213 (40001): Deadlock found when trying to get lock; InnoDB rolls back victim!
