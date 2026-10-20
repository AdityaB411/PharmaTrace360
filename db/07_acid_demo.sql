-- =============================================================
-- 07_acid_demo.sql - ACID Properties Two-Terminal Walkthrough
-- PharmaTrace 360 - MySQL 8.0+
-- =============================================================
-- PURPOSE: Demonstrate all four ACID properties with concrete
-- SQL steps that leave the database completely unchanged.
--
-- HOW TO USE:
-- Open TWO separate MySQL client windows (two terminal tabs).
-- Label them SESSION A and SESSION B.
-- Follow the steps in each session in the order shown.
-- Comments prefixed "[A]" run in SESSION A.
-- Comments prefixed "[B]" run in SESSION B.
-- Comments prefixed "[NOTE]" explain the concept; do not run.
--
-- The walkthrough ends with a ROLLBACK or a satisfied verification
-- so NO permanent changes are made to the demo dataset.
-- =============================================================

USE pharmatrace360;

-- =============================================================
-- PROPERTY 1: ATOMICITY
-- "All or nothing" - if any step in a transaction fails, all
-- prior steps in that transaction are undone automatically.
--
-- Demo: start a transaction, make a change, then ROLLBACK to
-- prove the change was never committed.
-- Run all steps in ONE terminal (SESSION A only).
-- =============================================================

SELECT '=== PROPERTY 1: ATOMICITY ===' AS property;

-- [A] Step 1: Check the current status of batch BT-2026-009.
--             Record this value; it should be 'Pending'.
SELECT batch_number, status
FROM Production_Batches
WHERE batch_number = 'BT-2026-009';

-- [A] Step 2: Start a transaction and make a change.
START TRANSACTION;

-- [A] Step 3: Simulate "approve" without going through the
--             procedure (the trigger will enforce business rules,
--             but we want to show the rollback, so we use a
--             batch that is already in a state the trigger accepts
--             -- here we just change a description field to prove
--             rollback.  We update a Batch_Materials row count
--             inside the transaction to demonstrate the concept).
--
--             NOTE: In a real scenario this UPDATE would trigger
--             trg_batches_bu and might fail if rules are not met.
--             To keep the demo neutral, we update a safe column
--             like quantity_units on a Pending batch temporarily.
UPDATE Production_Batches
SET quantity_units = 99999
WHERE batch_number = 'BT-2026-009';

-- [A] Step 4: Verify the change is visible WITHIN this session.
SELECT batch_number, quantity_units, status
FROM Production_Batches
WHERE batch_number = 'BT-2026-009';
-- Expected: quantity_units = 99999 (visible in this session only).

-- [A] Step 5: ROLLBACK - undo everything since START TRANSACTION.
ROLLBACK;

-- [A] Step 6: Verify the row is unchanged after rollback.
SELECT batch_number, quantity_units, status
FROM Production_Batches
WHERE batch_number = 'BT-2026-009';
-- Expected: quantity_units restored to original value.

-- [NOTE] ATOMICITY CONCLUSION:
-- The UPDATE inside the transaction was never committed.
-- ROLLBACK undoes ALL statements in the transaction as one unit.
-- Even if the server crashed between UPDATE and ROLLBACK,
-- InnoDB's redo/undo log would recover the original data.


-- =============================================================
-- PROPERTY 2: CONSISTENCY
-- The database must remain in a valid state before and after
-- every transaction. Constraint violations abort the transaction.
--
-- Demo: attempt to insert a Batch_Materials row that violates
-- the CHECK constraint (quantity_used_kg <= 0).
-- The INSERT fails; the database stays consistent.
-- =============================================================

SELECT '=== PROPERTY 2: CONSISTENCY ===' AS property;

-- [A] Step 1: Start a transaction.
START TRANSACTION;

-- [A] Step 2: Attempt an INSERT that violates chk_bm_qty (qty > 0).
--             Expected: MySQL signals constraint violation error.
--             The transaction is implicitly in an error state.
-- (Run with -f or catch the error; the statement itself will fail)
INSERT INTO Batch_Materials (batch_id, delivery_id, quantity_used_kg)
VALUES (
    (SELECT batch_id FROM Production_Batches WHERE batch_number = 'BT-2026-009'),
    (SELECT delivery_id FROM Material_Deliveries WHERE certificate_number = 'COA-2024-0009'),
    -5.000   -- INVALID: violates CHECK (quantity_used_kg > 0)
);
-- Expected error: Check constraint 'chk_bm_qty' is violated.

-- [A] Step 3: Roll back the failed transaction to keep the DB clean.
ROLLBACK;

-- [NOTE] CONSISTENCY CONCLUSION:
-- The CHECK constraint chk_bm_qty (quantity_used_kg > 0) on
-- Batch_Materials [01_schema.sql:262] fired before the row was
-- written. The database rejected the change and stayed consistent.
-- Business rule: "You cannot link a negative quantity of material
-- to a batch" is enforced at the database layer, independent of
-- the application.


-- =============================================================
-- PROPERTY 3: ISOLATION
-- Concurrent transactions must not see each other's uncommitted
-- changes. One session's update is invisible to another session
-- until it commits.
--
-- Demo: Session A locks a batch row with FOR UPDATE (simulating
-- sp_approve_batch). Session B tries to update the same row
-- and must wait (or times out).
--
-- !! Open TWO terminal windows. Run [A] steps in window A,
--    [B] steps in window B, in the exact order shown. !!
-- =============================================================

SELECT '=== PROPERTY 3: ISOLATION (Two-Terminal Interactive Guide) ===' AS property;

-- [A + B] First, check the current isolation level:
SELECT @@transaction_isolation;
-- Expected: REPEATABLE-READ (InnoDB default)

-- ---------------------------------------------------------------
-- [A] Step 1 in SESSION A:
-- ---------------------------------------------------------------
-- START TRANSACTION;
--
-- SELECT batch_id, batch_number, status
-- FROM Production_Batches
-- WHERE batch_number = 'BT-2026-009'
-- FOR UPDATE;
--
-- [NOTE] This locks the row exclusively. Session B cannot update
--        it until Session A commits or rolls back.
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- [B] Step 2 in SESSION B (while Session A holds the lock):
-- ---------------------------------------------------------------
-- SET innodb_lock_wait_timeout = 5;   -- Timeout after 5 seconds
--
-- UPDATE Production_Batches
-- SET quantity_units = 88888          -- This will WAIT or TIME OUT
-- WHERE batch_number = 'BT-2026-009';
--
-- Expected: ERROR 1205 (HY000): Lock wait timeout exceeded;
--           try restarting transaction
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- [A] Step 3 in SESSION A (after observing Session B waiting):
-- ---------------------------------------------------------------
-- ROLLBACK;   -- Releases the lock; leaves data unchanged.
-- ---------------------------------------------------------------

-- [NOTE] ISOLATION CONCLUSION:
-- InnoDB's REPEATABLE-READ isolation level combined with the
-- FOR UPDATE lock in sp_approve_batch [03_logic.sql:991-994]
-- means that when one session is approving a batch, no other
-- session can concurrently update that batch row.
-- Session B received a lock timeout, proving isolation is working.

-- Confirm the batch row is still unchanged:
SELECT batch_number, quantity_units, status
FROM Production_Batches
WHERE batch_number = 'BT-2026-009';


-- =============================================================
-- PROPERTY 4: DURABILITY
-- Once a transaction commits, the data persists even if the
-- server crashes immediately afterwards.
--
-- This property cannot be fully demonstrated with SQL queries
-- alone - it is guaranteed by the InnoDB storage engine
-- through its Write-Ahead Log (WAL / redo log).
--
-- The section below documents the durability guarantee and
-- shows how to verify it with a backup/restore test.
-- =============================================================

SELECT '=== PROPERTY 4: DURABILITY (Notes) ===' AS property;

-- [NOTE] HOW INNODB GUARANTEES DURABILITY:
-- 1. When a transaction COMMITs, InnoDB writes the redo log to
--    disk (fsync) BEFORE returning success to the client.
--    Setting: innodb_flush_log_at_trx_commit = 1 (default).
-- 2. Even if MySQL crashes immediately after COMMIT, the redo
--    log contains enough information to replay the transaction
--    on next startup.
-- 3. For full point-in-time recovery, enable binary logging:
--    SET GLOBAL log_bin = ON;   (requires server restart config)

-- [NOTE] BACKUP VERIFICATION PROCEDURE:
-- Step 1: Take a logical backup with mysqldump:
--   mysqldump -u root -p pharmatrace360 ^
--     > "E:\DBMS\PharmaTrace360\db\backup\pharmatrace360_backup.sql"
--
-- Step 2: Drop the database (test environment only!):
--   DROP DATABASE pharmatrace360;
--
-- Step 3: Restore from the backup:
--   mysql -u root -p < "E:\DBMS\PharmaTrace360\db\backup\pharmatrace360_backup.sql"
--
-- Step 4: Verify data integrity after restore:
--   USE pharmatrace360;
--   SELECT COUNT(*) FROM Production_Batches;   -- must match pre-drop count
--   SELECT COUNT(*) FROM QR_Codes;             -- must match pre-drop count
--   SELECT COUNT(*) FROM Audit_Logs;           -- audit trail must be intact

-- [NOTE] VERIFY innodb_flush_log_at_trx_commit SETTING:
SELECT @@innodb_flush_log_at_trx_commit;
-- Expected: 1 (full ACID durability - flush and sync on every commit)
-- Value 2 = flush to OS cache on commit (risk: 1-second data loss on crash)
-- Value 0 = flush once per second (risk: up to 1 second data loss)

SELECT @@log_bin;
-- Shows whether binary logging is enabled (1 = on, 0 = off).
-- Binary logging is required for point-in-time recovery.

-- =============================================================
-- ACID SUMMARY TABLE (for reference / report)
-- =============================================================
SELECT 'ACID Property' AS property, 'Demonstrated By' AS demonstrated_by
UNION ALL
SELECT 'Atomicity',    'START TRANSACTION + UPDATE + ROLLBACK - row unchanged'
UNION ALL
SELECT 'Consistency',  'CHECK chk_bm_qty rejects negative qty; transaction aborted'
UNION ALL
SELECT 'Isolation',    'Verified transaction isolation level; manual two-session lock-timeout test documented'
UNION ALL
SELECT 'Durability',   'Verified durability-related server settings; backup/restore procedure documented';

-- =============================================================
-- End of 07_acid_demo.sql
-- All data is left in its original state.
-- =============================================================
