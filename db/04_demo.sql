-- =============================================================
-- 04_demo.sql - Demonstration Script
-- PharmaTrace 360 - MySQL 8.0+
-- Runs AFTER 01_schema.sql, 02_seed.sql and 03_logic.sql.
-- Do NOT store passwords or credentials in this file.
-- =============================================================
-- HOW TO RUN (from your own Command Prompt):
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < "E:\DBMS\PharmaTrace360\db\04_demo.sql"
-- =============================================================

USE pharmatrace360;

-- =============================================================
-- STEP 0: Verdict for one code per Approved batch
-- Lists batch number, status, expiry date and fn_qr_verdict
-- for one code from each Approved batch.
-- =============================================================

SELECT '--- Verdict for one code per Approved batch ---' AS step;
SELECT
    pb.batch_number,
    pb.status,
    pb.expiry_date,
    fn_qr_verdict(MIN(qr.code)) AS verdict
FROM Production_Batches pb
JOIN QR_Codes qr ON qr.batch_id = pb.batch_id
WHERE pb.status = 'Approved'
GROUP BY pb.batch_id, pb.batch_number, pb.status, pb.expiry_date
ORDER BY pb.batch_number;

-- =============================================================
-- STEP 1: SELECT * from each view
-- Shows that all views return meaningful data from the seed.
-- =============================================================

-- 1a. Batch overview: one row per batch with QR count
SELECT '--- v_batch_overview ---' AS step;
SELECT * FROM v_batch_overview;

-- 1b. Batch traceability: supply-chain lineage per batch
SELECT '--- v_batch_traceability ---' AS step;
SELECT * FROM v_batch_traceability;

-- 1c. Suspicious codes: codes scanned more than 5 times
SELECT '--- v_suspicious_codes ---' AS step;
SELECT * FROM v_suspicious_codes;

-- 1d. Dashboard: single KPI row
SELECT '--- v_dashboard ---' AS step;
SELECT * FROM v_dashboard;

-- 1e. Batch status counts: batch count per status
SELECT '--- v_batch_status_counts ---' AS step;
SELECT * FROM v_batch_status_counts;


-- =============================================================
-- STEP 2: sp_verify_scan - four different verdicts
-- Each call inserts a Scan_Log row and returns the public-
-- facing result sets (medicine info, uses, side effects,
-- avoid-with list).
-- =============================================================

-- 2a. Genuine: pick a code from an Approved, in-date batch
--     BT-2026-002 is Approved and expires 2028-02-10 (future).
SELECT '--- sp_verify_scan: Genuine (Approved, in-date) ---' AS step;
CALL sp_verify_scan(
    (SELECT code FROM QR_Codes
     WHERE batch_id = (SELECT batch_id FROM Production_Batches
                       WHERE batch_number = 'BT-2026-002')
     LIMIT 1)
);

-- 2b. Expired: pick a code from the expired batch BT-2024-007
--     (expiry_date 2026-02-28, which is in the past).
SELECT '--- sp_verify_scan: Expired (past expiry) ---' AS step;
CALL sp_verify_scan(
    (SELECT code FROM QR_Codes
     WHERE batch_id = (SELECT batch_id FROM Production_Batches
                       WHERE batch_number = 'BT-2024-007')
     LIMIT 1)
);

-- 2c. Recalled: pick a code from the recalled batch BT-2026-012
SELECT '--- sp_verify_scan: Recalled ---' AS step;
CALL sp_verify_scan(
    (SELECT code FROM QR_Codes
     WHERE batch_id = (SELECT batch_id FROM Production_Batches
                       WHERE batch_number = 'BT-2026-012')
     LIMIT 1)
);

-- 2d. Suspicious: made-up code that does not exist anywhere
SELECT '--- sp_verify_scan: Suspicious (unknown code) ---' AS step;
CALL sp_verify_scan('TOTALLY-FAKE-CODE-XYZ');


-- =============================================================
-- STEP 3: sp_approve_batch - failure then success
-- Demonstrates that the BEFORE UPDATE trigger rejects
-- batches without a Pass test, and then succeeds once a
-- Pass test is recorded.
-- =============================================================

-- 3a. First, INSERT a Pending batch that has NO test at all
--     (we use BT-2026-008 which IS Pending but already has a
--      Pass test; instead we create a brand-new Pending batch
--      with no tests).
--     Actually BT-2026-008 is Pending with a Pass test, and
--     BT-2026-009 is Pending with a Pass test too.
--     To demonstrate the failure, we need a batch with no Pass
--     as the latest test. Let's add a Fail test for BT-2026-009
--     to make its latest test a Fail, then try to approve it.

-- Record a Fail test for BT-2026-009 so the latest test is Fail
SELECT '--- Step 3a: Add a Fail test to BT-2026-009 to make latest = Fail ---' AS step;
INSERT INTO Quality_Test_Reports (batch_id, tested_by, test_date,
    purity_pct, dissolution_pct, weight_variation_pct, result, remarks)
VALUES (
    (SELECT batch_id FROM Production_Batches WHERE batch_number = 'BT-2026-009'),
    (SELECT user_id FROM Users WHERE email = 'vikram.mfr@demo.test'),
    '2026-09-25', 86.00, 74.50, 4.80, 'Fail',
    'Re-test failed: dissolution below threshold.'
);

-- Try to approve BT-2026-009 - MUST FAIL because latest test is Fail
SELECT '--- Step 3b: sp_approve_batch on BT-2026-009 (should FAIL - latest test is Fail) ---' AS step;
-- We wrap this in a simple error-catching block using a handler
-- so the demo script continues even after the expected error.

-- MySQL does not support TRY/CATCH in scripts, so we use a
-- short procedure to catch the error and display the message.
DELIMITER //
CREATE PROCEDURE _demo_try_approve_fail()
BEGIN
    DECLARE v_msg TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        SELECT CONCAT('EXPECTED ERROR: ', v_msg) AS error_result;
    END;
    CALL sp_approve_batch('BT-2026-009',
        (SELECT user_id FROM Users WHERE email = 'priya.admin@demo.test'), 5);
END //
DELIMITER ;

CALL _demo_try_approve_fail();
DROP PROCEDURE _demo_try_approve_fail;

-- 3c. Now record a Pass test for BT-2026-009 (making latest = Pass)
SELECT '--- Step 3c: Record a Pass test for BT-2026-009 ---' AS step;
INSERT INTO Quality_Test_Reports (batch_id, tested_by, test_date,
    purity_pct, dissolution_pct, weight_variation_pct, result, remarks)
VALUES (
    (SELECT batch_id FROM Production_Batches WHERE batch_number = 'BT-2026-009'),
    (SELECT user_id FROM Users WHERE email = 'vikram.mfr@demo.test'),
    '2026-09-30', 98.70, 93.20, 1.90, 'Pass',
    'Re-test passed all parameters.'
);

-- 3d. Approve BT-2026-009 with 5 packs - MUST SUCCEED and create 5 QR codes
SELECT '--- Step 3d: sp_approve_batch on BT-2026-009 (should SUCCEED) ---' AS step;
CALL sp_approve_batch('BT-2026-009',
    (SELECT user_id FROM Users WHERE email = 'priya.admin@demo.test'), 5);

-- Verify 5 QR codes were created
SELECT '--- Verify: QR codes for BT-2026-009 ---' AS step;
SELECT code, issued_at
FROM QR_Codes
WHERE batch_id = (SELECT batch_id FROM Production_Batches
                  WHERE batch_number = 'BT-2026-009');


-- =============================================================
-- STEP 4: sp_issue_recall on the newly approved batch
-- Recalls BT-2026-009 and shows the impact result.
-- =============================================================

SELECT '--- Step 4: sp_issue_recall on BT-2026-009 ---' AS step;
CALL sp_issue_recall('BT-2026-009',
    'Demo recall: contamination detected in stability study.',
    (SELECT user_id FROM Users WHERE email = 'priya.admin@demo.test'));


-- =============================================================
-- STEP 5: Commented-out lines that should FAIL
-- Each line is labelled with the expected error.
-- =============================================================

-- should FAIL: inserting a QR code for a Rejected batch (BT-2026-010)
-- INSERT INTO QR_Codes (code, batch_id)
-- VALUES ('PT360-SHOULD-FAIL01',
--     (SELECT batch_id FROM Production_Batches WHERE batch_number = 'BT-2026-010'));
-- Expected error: QR codes can only be issued for Approved batches.

-- should FAIL: a Batch_Materials row from another manufacturer's delivery
-- (BT-2026-001 belongs to Cipla; delivery COA-2024-0002 belongs to Alkem)
-- INSERT INTO Batch_Materials (batch_id, delivery_id, quantity_used_kg)
-- VALUES (
--     (SELECT batch_id FROM Production_Batches WHERE batch_number = 'BT-2026-001'),
--     (SELECT delivery_id FROM Material_Deliveries WHERE certificate_number = 'COA-2024-0002'),
--     5.000);
-- Expected error: Delivery manufacturer does not own the batch factory.

-- should FAIL: a manufacturer user with no manufacturer_id
-- INSERT INTO Users (full_name, email, password_hash, role_id, manufacturer_id)
-- VALUES ('Test User', 'test.fail@demo.test', '!',
--     (SELECT role_id FROM Roles WHERE role_name = 'Manufacturer'), NULL);
-- Expected error: Manufacturer users must have a manufacturer_id.

-- should FAIL: inserting a batch where medicine and factory belong to different manufacturers
-- (Actiflu 500mg Tablet is made by Cipla Ltd, but Alkem Plant 1 belongs to Alkem Laboratories Ltd)
-- INSERT INTO Production_Batches (batch_number, medicine_id, factory_id, quantity_units, manufacture_date, expiry_date, status)
-- VALUES ('BT-FAIL-MFR-01',
--     (SELECT medicine_id FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' LIMIT 1),
--     (SELECT factory_id FROM Factories WHERE factory_name = 'Alkem Plant 1' LIMIT 1),
--     1000, '2026-01-01', '2028-01-01', 'Pending');
-- Expected error: Medicine and factory belong to different manufacturers


-- =============================================================
-- STEP 6: Advanced query examples
-- =============================================================

-- 6a. JOIN across 4 tables:
--     Show every QR code with its batch, medicine and manufacturer.
SELECT '--- Step 6a: JOIN across 4 tables ---' AS step;
SELECT
    qr.code        AS qr_code,
    pb.batch_number,
    m.brand_name   AS medicine,
    mfr.company_name AS manufacturer
FROM QR_Codes qr
JOIN Production_Batches pb  ON pb.batch_id         = qr.batch_id
JOIN Medicines          m   ON m.medicine_id        = pb.medicine_id
JOIN Manufacturers      mfr ON mfr.manufacturer_id  = m.manufacturer_id
ORDER BY pb.batch_number, qr.code
LIMIT 20;

-- 6b. GROUP BY with HAVING:
--     Manufacturers with more than 1 approved batch.
SELECT '--- Step 6b: GROUP BY with HAVING ---' AS step;
SELECT
    mfr.company_name    AS manufacturer,
    COUNT(pb.batch_id)  AS approved_count
FROM Production_Batches pb
JOIN Factories     f   ON f.factory_id       = pb.factory_id
JOIN Manufacturers mfr ON mfr.manufacturer_id = f.manufacturer_id
WHERE pb.status = 'Approved'
GROUP BY mfr.manufacturer_id, mfr.company_name
HAVING COUNT(pb.batch_id) > 1;

-- 6c. Subquery:
--     Medicines that have at least one batch in Recalled status.
SELECT '--- Step 6c: Subquery ---' AS step;
SELECT brand_name, dosage_form
FROM Medicines
WHERE medicine_id IN (
    SELECT medicine_id
    FROM Production_Batches
    WHERE status = 'Recalled'
);

-- 6d. EXPLAIN SELECT on QR_Codes by code - shows the UNIQUE index
SELECT '--- Step 6d: EXPLAIN on QR_Codes by code ---' AS step;
EXPLAIN SELECT * FROM QR_Codes WHERE code = 'PT360-20515ECBE7F2';

-- 6e. EXPLAIN SELECT on Scan_Log by scanned_code - shows idx_scan_code_time
SELECT '--- Step 6e: EXPLAIN on Scan_Log by scanned_code ---' AS step;
EXPLAIN SELECT * FROM Scan_Log WHERE scanned_code = 'PT360-20515ECBE7F2';


-- =============================================================
-- STEP 7: 10 newest Audit_Logs rows
-- =============================================================

SELECT '--- 10 newest Audit_Logs rows ---' AS step;
SELECT log_id, user_id, action, table_name, record_id, details
FROM Audit_Logs
ORDER BY log_id DESC
LIMIT 10;

-- =============================================================
-- End of 04_demo.sql
-- All steps above should execute without errors (except the
-- intentional error in Step 3b which is caught and displayed).
-- =============================================================
