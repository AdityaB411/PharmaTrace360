-- =============================================================
-- 08_feature_tests.sql - Feature & Integrity Test Suite
-- PharmaTrace 360 - MySQL 8.0+
-- =============================================================
-- HOW TO RUN (from your own Command Prompt):
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p -f < "E:\DBMS\PharmaTrace360\db\08_feature_tests.sql"
--
-- NOTE:
-- - The -f flag (force) is REQUIRED because negative tests deliberately
--   raise SIGNAL errors to verify database-level trigger & procedure enforcement.
-- - Procedures commit transactions internally, so tests cannot be rolled back.
-- - Every test record is prefixed with 'TEST-'.
-- - Running a full database reset (db/00_reset_all.sql) removes all test data
--   and restores the pristine demo dataset.
-- =============================================================

USE pharmatrace360;

SELECT '=====================================================' AS banner;
SELECT 'STARTING PHARMATRACE 360 FEATURE & INTEGRITY TESTS'   AS banner;
SELECT '=====================================================' AS banner;

-- =============================================================
-- PART 1: HAPPY PATH LIFECYCLE
-- Demonstrates:
-- 1. sp_record_delivery
-- 2. sp_create_batch
-- 3. sp_add_batch_material
-- 4. sp_record_test
-- 5. sp_approve_batch
-- 6. Verify QR code issuance count
-- 7. Verify inventory deduction in v_my_deliveries
-- 8. Verify chronological batch timeline in v_batch_timeline
-- =============================================================

-- 1. Record Delivery
SELECT '--- [HAPPY PATH 1] Record Delivery (sp_record_delivery) ---' AS test_step;
CALL sp_record_delivery(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    (SELECT supplier_name FROM Suppliers WHERE supplier_name = 'Greenleaf Chem Supplies'),
    (SELECT ingredient_name FROM Ingredients WHERE ingredient_name = 'Paracetamol'),
    100.000,
    CURDATE(),
    'TEST-COA-001'
);

-- 2. Create Batch
SELECT '--- [HAPPY PATH 2] Create Batch (sp_create_batch) ---' AS test_step;
CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-001',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Cipla Plant 1' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    500,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);

-- 3. Add Raw Material
SELECT '--- [HAPPY PATH 3] Add Batch Material (sp_add_batch_material) ---' AS test_step;
CALL sp_add_batch_material(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-001',
    'TEST-COA-001',
    25.000
);

-- 4. Record Quality Assurance Test (Pass)
SELECT '--- [HAPPY PATH 4] Record QA Test (sp_record_test) ---' AS test_step;
CALL sp_record_test(
    'TEST-BATCH-001',
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    99.40,
    95.80,
    1.20,
    'Pass',
    'QA passed all specifications.'
);

-- 5. Approve Batch and Issue Serialized QR Codes
SELECT '--- [HAPPY PATH 5] Approve Batch (sp_approve_batch) ---' AS test_step;
CALL sp_approve_batch(
    'TEST-BATCH-001',
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    5
);

-- 6. Verify QR Code Issuance
SELECT '--- [HAPPY PATH 6] Verify QR Code Issuance Count (Expected: 5) ---' AS test_step;
SELECT
    pb.batch_number,
    pb.status,
    COUNT(qr.qr_id) AS qr_count_issued
FROM Production_Batches pb
JOIN QR_Codes qr ON qr.batch_id = pb.batch_id
WHERE pb.batch_number = 'TEST-BATCH-001'
GROUP BY pb.batch_id, pb.batch_number, pb.status;

-- 7. Verify Live Delivery Inventory in v_my_deliveries
SELECT '--- [HAPPY PATH 7] Verify Delivery Balance in v_my_deliveries ---' AS test_step;
SELECT
    certificate_number,
    ingredient_name,
    supplier_name,
    quantity_kg,
    used_kg,
    remaining_kg
FROM v_my_deliveries
WHERE certificate_number = 'TEST-COA-001';

-- 8. Verify Complete Chronological Lifecycle in v_batch_timeline
SELECT '--- [HAPPY PATH 8] Verify Lifecycle Events in v_batch_timeline ---' AS test_step;
SELECT
    event_time,
    event_type,
    description
FROM v_batch_timeline
WHERE batch_number = 'TEST-BATCH-001'
ORDER BY event_time ASC;


-- =============================================================
-- PART 2: LABELLED FAILURE TESTS (Run with mysql -f)
-- =============================================================

-- Failure A: Over-using a delivery
-- TEST-COA-001 had 100.000 kg total. 25.000 kg was consumed by TEST-BATCH-001.
-- Remaining balance is 75.000 kg. Requesting 80.000 kg must be rejected.
SELECT '--- [FAILURE A] Over-using a delivery (Expected ERROR: Total quantity used exceeds the delivered quantity.) ---' AS test_step;
CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-OVERUSE',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Cipla Plant 1' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    200,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);

CALL sp_add_batch_material(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-OVERUSE',
    'TEST-COA-001',
    80.000
);


-- Failure B: Adding material to an approved batch
-- TEST-BATCH-001 is already 'Approved'. Modifying materials must be blocked.
SELECT '--- [FAILURE B] Adding material to an approved batch (Expected ERROR: Materials can only be added to Pending batches.) ---' AS test_step;
CALL sp_add_batch_material(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-001',
    'TEST-COA-001',
    10.000
);


-- Failure C: Approving a batch with no material
-- TEST-BATCH-NOMAT has a Pass QA test, but zero raw materials linked.
SELECT '--- [FAILURE C] Approving a batch with no material (Expected ERROR: Cannot approve batch: at least one raw material must be linked.) ---' AS test_step;
CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-NOMAT',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Cipla Plant 1' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    300,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);

CALL sp_record_test(
    'TEST-BATCH-NOMAT',
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    99.10,
    94.50,
    1.10,
    'Pass',
    'Tested before material linkage attempt.'
);

CALL sp_approve_batch(
    'TEST-BATCH-NOMAT',
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    5
);


-- Failure D1: Manufacturer using another company's medicine
-- Cipla user attempting to create a batch for Alkem's medicine (Nodimox).
SELECT '--- [FAILURE D1] Manufacturer using another company medicine (Expected ERROR: Medicine not found or does not belong to the user manufacturer.) ---' AS test_step;
CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-OTHER-MED',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Nodimox 500mg Tablet DT'),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Cipla Plant 1' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    100,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);


-- Failure D2: Manufacturer using another company's factory
-- Cipla user attempting to manufacture at Alkem's plant.
SELECT '--- [FAILURE D2] Manufacturer using another company factory (Expected ERROR: Factory not found or does not belong to the user manufacturer.) ---' AS test_step;
CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-OTHER-FAC',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Alkem Plant 1'),
    100,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);


-- Failure E: A delivery dated after the batch
-- Delivery received today cannot be used for a batch manufactured 10 days ago.
SELECT '--- [FAILURE E] Delivery dated after batch manufacture date (Expected ERROR: Delivery received date cannot be after the batch manufacture date.) ---' AS test_step;
CALL sp_record_delivery(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    (SELECT supplier_name FROM Suppliers WHERE supplier_name = 'Greenleaf Chem Supplies'),
    (SELECT ingredient_name FROM Ingredients WHERE ingredient_name = 'Paracetamol'),
    50.000,
    CURDATE(),
    'TEST-COA-TODAY'
);

CALL sp_create_batch(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-PAST',
    (SELECT brand_name FROM Medicines WHERE brand_name = 'Actiflu 500mg Tablet' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    (SELECT factory_name FROM Factories WHERE factory_name = 'Cipla Plant 1' AND manufacturer_id = (SELECT manufacturer_id FROM Users WHERE email = 'rahul.mfr@demo.test')),
    100,
    DATE_SUB(CURDATE(), INTERVAL 10 DAY),
    DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
);

CALL sp_add_batch_material(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'TEST-BATCH-PAST',
    'TEST-COA-TODAY',
    10.000
);


-- Failure F1: Updating an audit row
-- Audit_Logs is strictly append-only.
SELECT '--- [FAILURE F1] Updating an audit row (Expected ERROR: Audit log is append-only.) ---' AS test_step;
UPDATE Audit_Logs
SET action = 'TAMPERED'
WHERE log_id = (SELECT min_id FROM (SELECT MIN(log_id) AS min_id FROM Audit_Logs) AS t);


-- Failure F2: Deleting an audit row
-- Audit_Logs is strictly append-only.
SELECT '--- [FAILURE F2] Deleting an audit row (Expected ERROR: Audit log is append-only.) ---' AS test_step;
DELETE FROM Audit_Logs
WHERE log_id = (SELECT min_id FROM (SELECT MIN(log_id) AS min_id FROM Audit_Logs) AS t);


-- Failure G1: Password change for wrong user
-- Passing non-existent user_id.
SELECT '--- [FAILURE G1] Password change for wrong user (Expected ERROR: User not found.) ---' AS test_step;
CALL sp_change_password(
    999999,
    '$2y$10$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123'
);


-- Failure G2: Password change with short hash
-- Passing invalid/short hash string (< 60 chars).
SELECT '--- [FAILURE G2] Password change with short hash (Expected ERROR: Password hash is too short. Must be a valid bcrypt hash of at least 60 characters.) ---' AS test_step;
CALL sp_change_password(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    'too_short_hash'
);


-- Verification: Valid password change
SELECT '--- [VERIFY] Valid password change and audit log entry ---' AS test_step;
CALL sp_change_password(
    (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test'),
    '$2y$10$e8wF07x/kFqZ0B6h2e7OyeX6M5GvF9rD8a1b2c3d4e5f6g7h8i9jk'
);

SELECT
    log_id,
    user_id,
    action,
    table_name,
    record_id,
    details,
    logged_at
FROM Audit_Logs
WHERE action = 'PASSWORD_CHANGED'
  AND record_id = (SELECT user_id FROM Users WHERE email = 'rahul.mfr@demo.test')
ORDER BY log_id DESC
LIMIT 1;

SELECT '=====================================================' AS banner;
SELECT 'ALL PHARMATRACE 360 FEATURE TESTS COMPLETED'          AS banner;
SELECT '=====================================================' AS banner;
