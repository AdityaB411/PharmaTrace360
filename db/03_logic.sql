-- =============================================================
-- 03_logic.sql - Views, Functions, Triggers & Procedures
-- PharmaTrace 360 - MySQL 8.0+
-- Runs AFTER 01_schema.sql and 02_seed.sql.
-- Do NOT store passwords or credentials in this file.
-- =============================================================
-- HOW TO RUN (from your own Command Prompt):
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < "E:\DBMS\PharmaTrace360\db\03_logic.sql"
-- =============================================================

USE pharmatrace360;

-- =============================================================
-- VIEWS
-- Views are virtual tables - they don't store data, they store
-- a SELECT query that runs every time the view is read.
-- =============================================================

-- -------------------------------------------------------
-- v_batch_overview
-- Purpose: One-stop summary of every batch with its
--          medicine, manufacturer, factory, status,
--          dates and how many QR codes were issued.
-- Demonstrates: Multi-table JOINs, LEFT JOIN, aggregate
--               COUNT, GROUP BY.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_overview AS
SELECT
    pb.batch_number,
    m.brand_name        AS medicine,
    mfr.company_name    AS manufacturer,
    mfr.manufacturer_id,
    f.factory_name      AS factory,
    pb.status,
    pb.manufacture_date,
    pb.expiry_date,
    COUNT(qr.qr_id)     AS qr_count
FROM Production_Batches pb
JOIN Medicines     m   ON m.medicine_id      = pb.medicine_id
JOIN Factories     f   ON f.factory_id       = pb.factory_id
JOIN Manufacturers mfr ON mfr.manufacturer_id = f.manufacturer_id
LEFT JOIN QR_Codes qr  ON qr.batch_id       = pb.batch_id
GROUP BY pb.batch_id, pb.batch_number, m.brand_name,
         mfr.company_name, mfr.manufacturer_id, f.factory_name,
         pb.status, pb.manufacture_date, pb.expiry_date;

-- -------------------------------------------------------
-- v_batch_traceability
-- Purpose: Full supply-chain trace - which materials
--          (deliveries, suppliers, certificates) went
--          into each batch.
-- Demonstrates: Five-table JOIN, many-to-many resolution
--               through Batch_Materials.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_traceability AS
SELECT
    pb.batch_number,
    m.brand_name        AS medicine,
    ing.ingredient_name AS material,
    s.supplier_name     AS supplier,
    md.certificate_number,
    md.quantity_kg      AS delivered_kg,
    bm.quantity_used_kg AS used_kg,
    md.received_date
FROM Production_Batches  pb
JOIN Medicines           m   ON m.medicine_id     = pb.medicine_id
JOIN Batch_Materials     bm  ON bm.batch_id       = pb.batch_id
JOIN Material_Deliveries md  ON md.delivery_id    = bm.delivery_id
JOIN Ingredients         ing ON ing.ingredient_id  = md.ingredient_id
JOIN Suppliers           s   ON s.supplier_id      = md.supplier_id;

-- -------------------------------------------------------
-- v_suspicious_codes
-- Purpose: Flag QR codes that have been scanned more
--          than 5 times - a sign of counterfeiting.
-- Demonstrates: GROUP BY, HAVING, MIN/MAX aggregates.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_suspicious_codes AS
SELECT
    sl.scanned_code,
    COUNT(*)            AS scan_count,
    MIN(sl.scanned_at)  AS first_scan,
    MAX(sl.scanned_at)  AS last_scan
FROM Scan_Log sl
GROUP BY sl.scanned_code
HAVING COUNT(*) > 5;

-- -------------------------------------------------------
-- v_dashboard
-- Purpose: A single row with four KPI numbers for the
--          admin dashboard.
-- Demonstrates: Conditional aggregation with SUM(CASE).
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
    (SELECT COUNT(*) FROM Production_Batches
     WHERE status = 'Approved')           AS approved_batches,
    (SELECT COUNT(*) FROM Quality_Test_Reports
     WHERE result = 'Fail')               AS failed_tests,
    (SELECT COUNT(*) FROM Scan_Log
     WHERE verdict = 'Suspicious')        AS suspicious_scans,
    (SELECT COUNT(*) FROM Product_Recalls)
                                          AS recalls;

-- -------------------------------------------------------
-- v_batch_status_counts
-- Purpose: Batch counts grouped by status - feeds the
--          dashboard bar/pie chart.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_status_counts AS
SELECT
    pb.status,
    COUNT(*) AS batch_count
FROM Production_Batches pb
GROUP BY pb.status;


-- =============================================================
-- FUNCTIONS
-- Deterministic helper functions used by procedures and views.
-- Each function is declared with READS SQL DATA because it
-- only reads tables, never modifies them.
-- =============================================================

-- -------------------------------------------------------
-- fn_recent_scan_count
-- Returns the number of times a code was scanned in the
-- last p_hours hours.
-- Demonstrates: Scalar function, date arithmetic.
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fn_recent_scan_count;
DELIMITER //
CREATE FUNCTION fn_recent_scan_count(
    p_code  VARCHAR(64),
    p_hours INT
)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT DEFAULT 0;
    SELECT COUNT(*) INTO v_count
    FROM Scan_Log
    WHERE scanned_code = p_code
      AND scanned_at >= NOW() - INTERVAL p_hours HOUR;
    RETURN v_count;
END //
DELIMITER ;

-- -------------------------------------------------------
-- fn_qr_verdict
-- Evaluates a scanned code and returns one of:
--   Genuine | Expired | Recalled | Not approved | Suspicious
--
-- Check order (first match wins):
--   1. Unknown code (not in QR_Codes)     -> Suspicious
--   2. Batch status = 'Recalled'          -> Recalled
--   3. Batch status != 'Approved'         -> Not approved
--   4. expiry_date < CURDATE()            -> Expired
--   5. >10 scans in last 48 h             -> Suspicious
--      -- Threshold: 10 scans / 48 hours
--   6. Otherwise                          -> Genuine
--
-- Demonstrates: Control flow (IF), function composition.
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fn_qr_verdict;
DELIMITER //
CREATE FUNCTION fn_qr_verdict(
    p_code VARCHAR(64)
)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_batch_id     INT UNSIGNED;
    DECLARE v_status       VARCHAR(10);
    DECLARE v_expiry       DATE;
    DECLARE v_recent       INT;

    -- Step 1: look up the QR code
    SELECT qr.batch_id, pb.status, pb.expiry_date
    INTO v_batch_id, v_status, v_expiry
    FROM QR_Codes qr
    JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
    WHERE qr.code = p_code
    LIMIT 1;

    -- Unknown code -> Suspicious
    IF v_batch_id IS NULL THEN
        RETURN 'Suspicious';
    END IF;

    -- Recalled batch -> Recalled
    IF v_status = 'Recalled' THEN
        RETURN 'Recalled';
    END IF;

    -- Not Approved -> Not approved
    IF v_status != 'Approved' THEN
        RETURN 'Not approved';
    END IF;

    -- Expired -> Expired
    IF v_expiry < CURDATE() THEN
        RETURN 'Expired';
    END IF;

    -- Suspicious scan frequency
    -- Threshold: more than 10 scans in the last 48 hours
    SET v_recent = fn_recent_scan_count(p_code, 48);
    IF v_recent > 10 THEN
        RETURN 'Suspicious';
    END IF;

    -- All checks passed
    RETURN 'Genuine';
END //
DELIMITER ;


-- =============================================================
-- TRIGGERS
-- Triggers enforce business rules that cannot be expressed as
-- simple CHECK constraints.  They fire automatically before or
-- after INSERT/UPDATE on the relevant table.
--
-- SIGNAL SQLSTATE '45000' raises a user-defined error with a
-- clear message so the application (or demo script) can show
-- exactly what went wrong.
-- =============================================================

-- -------------------------------------------------------
-- trg_users_bi - Users BEFORE INSERT
-- Rule: Manufacturer role -> manufacturer_id required.
--       Admin/Regulator  -> manufacturer_id must be NULL.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_users_bi;
DELIMITER //
CREATE TRIGGER trg_users_bi
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
    DECLARE v_role_name VARCHAR(30);
    SELECT role_name INTO v_role_name
    FROM Roles WHERE role_id = NEW.role_id;

    IF v_role_name = 'Manufacturer' AND NEW.manufacturer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacturer users must have a manufacturer_id.';
    END IF;

    IF v_role_name = 'Admin/Regulator' AND NEW.manufacturer_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admin/Regulator users must NOT have a manufacturer_id.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_users_bu - Users BEFORE UPDATE
-- Same rules as BEFORE INSERT.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_users_bu;
DELIMITER //
CREATE TRIGGER trg_users_bu
BEFORE UPDATE ON Users
FOR EACH ROW
BEGIN
    DECLARE v_role_name VARCHAR(30);
    SELECT role_name INTO v_role_name
    FROM Roles WHERE role_id = NEW.role_id;

    IF v_role_name = 'Manufacturer' AND NEW.manufacturer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacturer users must have a manufacturer_id.';
    END IF;

    IF v_role_name = 'Admin/Regulator' AND NEW.manufacturer_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admin/Regulator users must NOT have a manufacturer_id.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batch_materials_bi - Batch_Materials BEFORE INSERT
-- Rule 1: The delivery's manufacturer must own the
--         batch's factory.
-- Rule 2: The delivery's ingredient must be part of the
--         batch's medicine (via Drug_Formulations).
-- Rule 3: The batch must be 'Pending'.
-- Rule 4: Total quantity used from this delivery, including
--         the new row, must not exceed delivery quantity.
-- Rule 5: Delivery's received date must be on or before
--         the batch's manufacture date.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batch_materials_bi;
DELIMITER //
CREATE TRIGGER trg_batch_materials_bi
BEFORE INSERT ON Batch_Materials
FOR EACH ROW
BEGIN
    DECLARE v_delivery_mfr  INT UNSIGNED;
    DECLARE v_factory_mfr   INT UNSIGNED;
    DECLARE v_delivery_ing  INT UNSIGNED;
    DECLARE v_medicine_id   INT UNSIGNED;
    DECLARE v_ing_match     INT DEFAULT 0;
    DECLARE v_batch_status  VARCHAR(10);
    DECLARE v_mfg_date      DATE;
    DECLARE v_deliv_date    DATE;
    DECLARE v_deliv_qty     DECIMAL(10,3);
    DECLARE v_total_used_kg DECIMAL(10,3) DEFAULT 0.000;

    -- Look up delivery details
    SELECT manufacturer_id, ingredient_id, quantity_kg, received_date
    INTO v_delivery_mfr, v_delivery_ing, v_deliv_qty, v_deliv_date
    FROM Material_Deliveries
    WHERE delivery_id = NEW.delivery_id;

    -- Look up batch details
    SELECT f.manufacturer_id, pb.medicine_id, pb.status, pb.manufacture_date
    INTO v_factory_mfr, v_medicine_id, v_batch_status, v_mfg_date
    FROM Production_Batches pb
    JOIN Factories f ON f.factory_id = pb.factory_id
    WHERE pb.batch_id = NEW.batch_id;

    -- Rule 3: batch must be Pending
    IF v_batch_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be added to Pending batches.';
    END IF;

    -- Rule 1: delivery manufacturer must match factory owner
    IF v_delivery_mfr != v_factory_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery manufacturer does not own the batch factory. A batch may only use deliveries received by its own manufacturer.';
    END IF;

    -- Rule 2: ingredient must be in the medicine's Drug_Formulations
    SELECT COUNT(*) INTO v_ing_match
    FROM Drug_Formulations
    WHERE medicine_id   = v_medicine_id
      AND ingredient_id = v_delivery_ing;

    IF v_ing_match = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery ingredient is not part of the batch medicine formulation.';
    END IF;

    -- Rule 5: delivery received date must be on or before batch manufacture date
    IF v_deliv_date > v_mfg_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery received date cannot be after the batch manufacture date.';
    END IF;

    -- Rule 4: total quantity used must not exceed delivery quantity
    SELECT COALESCE(SUM(quantity_used_kg), 0) INTO v_total_used_kg
    FROM Batch_Materials
    WHERE delivery_id = NEW.delivery_id;

    IF (v_total_used_kg + NEW.quantity_used_kg) > v_deliv_qty THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total quantity used exceeds the delivered quantity.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batch_materials_bu - Batch_Materials BEFORE UPDATE
-- Rule: block modifications unless the batch is 'Pending'.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batch_materials_bu;
DELIMITER //
CREATE TRIGGER trg_batch_materials_bu
BEFORE UPDATE ON Batch_Materials
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = OLD.batch_id;

    IF v_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be modified for Pending batches.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batch_materials_bd - Batch_Materials BEFORE DELETE
-- Rule: block deletion unless the batch is 'Pending'.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batch_materials_bd;
DELIMITER //
CREATE TRIGGER trg_batch_materials_bd
BEFORE DELETE ON Batch_Materials
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = OLD.batch_id;

    IF v_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be deleted from Pending batches.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_qr_codes_bi - QR_Codes BEFORE INSERT
-- Rule: Only Approved batches may receive QR codes.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_qr_codes_bi;
DELIMITER //
CREATE TRIGGER trg_qr_codes_bi
BEFORE INSERT ON QR_Codes
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = NEW.batch_id;

    IF v_status != 'Approved' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'QR codes can only be issued for Approved batches.';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batches_bi - Production_Batches BEFORE INSERT
-- Rule: The medicine's manufacturer_id must equal the
--       factory's manufacturer_id.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batches_bi;
DELIMITER //
CREATE TRIGGER trg_batches_bi
BEFORE INSERT ON Production_Batches
FOR EACH ROW
BEGIN
    DECLARE v_med_mfr INT UNSIGNED;
    DECLARE v_fac_mfr INT UNSIGNED;

    -- Look up manufacturer of the medicine
    SELECT manufacturer_id INTO v_med_mfr
    FROM Medicines
    WHERE medicine_id = NEW.medicine_id;

    -- Look up manufacturer of the factory
    SELECT manufacturer_id INTO v_fac_mfr
    FROM Factories
    WHERE factory_id = NEW.factory_id;

    -- Enforce matching manufacturers
    IF v_med_mfr != v_fac_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine and factory belong to different manufacturers';
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batches_bu - Production_Batches BEFORE UPDATE
-- Rule M: Medicine and factory must belong to the same
--         manufacturer.
-- Rule A: Changing status to 'Approved' requires the most
--         recent Quality_Test_Reports row (latest test_date,
--         then report_id) to be 'Pass' AND at least one
--         Batch_Materials row linked.
-- Rule B: Changing status to 'Recalled' requires a
--         Product_Recalls row for the batch.
-- Rule C: A Recalled batch cannot change status.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batches_bu;
DELIMITER //
CREATE TRIGGER trg_batches_bu
BEFORE UPDATE ON Production_Batches
FOR EACH ROW
BEGIN
    DECLARE v_med_mfr       INT UNSIGNED;
    DECLARE v_fac_mfr       INT UNSIGNED;
    DECLARE v_latest_result VARCHAR(4);
    DECLARE v_recall_count  INT DEFAULT 0;
    DECLARE v_mat_count     INT DEFAULT 0;

    -- Rule M: medicine and factory must belong to the same manufacturer
    SELECT manufacturer_id INTO v_med_mfr
    FROM Medicines
    WHERE medicine_id = NEW.medicine_id;

    SELECT manufacturer_id INTO v_fac_mfr
    FROM Factories
    WHERE factory_id = NEW.factory_id;

    IF v_med_mfr != v_fac_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine and factory belong to different manufacturers';
    END IF;

    -- Rule C: recalled batch is immutable
    IF OLD.status = 'Recalled' AND NEW.status != 'Recalled' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A recalled batch cannot change status.';
    END IF;

    -- Rule A: approval requires latest test = Pass AND at least one material linked
    IF NEW.status = 'Approved' AND OLD.status != 'Approved' THEN
        SELECT result INTO v_latest_result
        FROM Quality_Test_Reports
        WHERE batch_id = NEW.batch_id
        ORDER BY test_date DESC, report_id DESC
        LIMIT 1;

        IF v_latest_result IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: no quality test reports found.';
        END IF;

        IF v_latest_result != 'Pass' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: the most recent quality test did not Pass.';
        END IF;

        -- Must have at least one Batch_Materials row
        SELECT COUNT(*) INTO v_mat_count
        FROM Batch_Materials
        WHERE batch_id = NEW.batch_id;

        IF v_mat_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: at least one raw material must be linked.';
        END IF;
    END IF;

    -- Rule B: recall requires a Product_Recalls row
    IF NEW.status = 'Recalled' AND OLD.status != 'Recalled' THEN
        SELECT COUNT(*) INTO v_recall_count
        FROM Product_Recalls
        WHERE batch_id = NEW.batch_id;

        IF v_recall_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot set status to Recalled: no Product_Recalls row exists for this batch.';
        END IF;
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_audit_logs_bu - Audit_Logs BEFORE UPDATE
-- Rule: Audit log is append-only.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_logs_bu;
DELIMITER //
CREATE TRIGGER trg_audit_logs_bu
BEFORE UPDATE ON Audit_Logs
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Audit log is append-only.';
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_audit_logs_bd - Audit_Logs BEFORE DELETE
-- Rule: Audit log is append-only.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_logs_bd;
DELIMITER //
CREATE TRIGGER trg_audit_logs_bd
BEFORE DELETE ON Audit_Logs
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Audit log is append-only.';
END //
DELIMITER ;

-- =============================================================
-- AFTER TRIGGERS - Audit Log entries
-- These write ALL audit entries so that procedures never
-- duplicate them.  The session variable @app_user_id carries
-- the acting user's id (set by procedures; may be NULL for
-- system actions).
-- =============================================================

-- -------------------------------------------------------
-- trg_batches_au - AFTER UPDATE on Production_Batches
-- Logs every status change.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batches_au;
DELIMITER //
CREATE TRIGGER trg_batches_au
AFTER UPDATE ON Production_Batches
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (
            @app_user_id,
            CONCAT('STATUS_', UPPER(NEW.status)),
            'Production_Batches',
            NEW.batch_id,
            CONCAT('Batch ', NEW.batch_number, ' status changed from ',
                   OLD.status, ' to ', NEW.status, '.')
        );
    END IF;
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_recalls_ai - AFTER INSERT on Product_Recalls
-- Logs every new recall.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_recalls_ai;
DELIMITER //
CREATE TRIGGER trg_recalls_ai
AFTER INSERT ON Product_Recalls
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'INSERT_RECALL',
        'Product_Recalls',
        NEW.recall_id,
        CONCAT('Recall created for batch_id ', NEW.batch_id,
               '. Reason: ', LEFT(NEW.reason, 200))
    );
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_qtr_ai - AFTER INSERT on Quality_Test_Reports
-- Logs every new test report.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_qtr_ai;
DELIMITER //
CREATE TRIGGER trg_qtr_ai
AFTER INSERT ON Quality_Test_Reports
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'INSERT_QA_TEST',
        'Quality_Test_Reports',
        NEW.report_id,
        CONCAT('QA test for batch_id ', NEW.batch_id,
               ' - result: ', NEW.result, '.')
    );
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_deliveries_ai - AFTER INSERT on Material_Deliveries
-- Logs every newly recorded delivery.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_deliveries_ai;
DELIMITER //
CREATE TRIGGER trg_deliveries_ai
AFTER INSERT ON Material_Deliveries
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'DELIVERY_RECORDED',
        'Material_Deliveries',
        NEW.delivery_id,
        CONCAT('Delivery recorded: ', NEW.quantity_kg, ' kg received under certificate ',
               COALESCE(NEW.certificate_number, 'N/A'), '.')
    );
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batches_ai - AFTER INSERT on Production_Batches
-- Logs every newly created production batch.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batches_ai;
DELIMITER //
CREATE TRIGGER trg_batches_ai
AFTER INSERT ON Production_Batches
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'BATCH_CREATED',
        'Production_Batches',
        NEW.batch_id,
        CONCAT('Batch ', NEW.batch_number, ' created with quantity ', NEW.quantity_units, '.')
    );
END //
DELIMITER ;

-- -------------------------------------------------------
-- trg_batch_materials_ai - AFTER INSERT on Batch_Materials
-- Logs every material link to a batch.
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_batch_materials_ai;
DELIMITER //
CREATE TRIGGER trg_batch_materials_ai
AFTER INSERT ON Batch_Materials
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'MATERIAL_LINKED',
        'Batch_Materials',
        NEW.batch_id,
        CONCAT('Material from delivery_id ', NEW.delivery_id, ' linked to batch_id ',
               NEW.batch_id, ' (', NEW.quantity_used_kg, ' kg used).')
    );
END //
DELIMITER ;


-- =============================================================
-- ADDITIONAL FUNCTIONS
-- =============================================================

-- -------------------------------------------------------
-- fn_user_can_manage_batch
-- Returns 1 only if:
--   1. The user is active (is_active = 1).
--   2. The user has the Manufacturer role.
--   3. The user's manufacturer_id equals the manufacturer
--      that owns the batch's factory.
-- Otherwise returns 0.
-- Used by sp_record_test, sp_approve_batch, sp_reject_batch.
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fn_user_can_manage_batch;
DELIMITER //
CREATE FUNCTION fn_user_can_manage_batch(
    p_user_id      INT UNSIGNED,
    p_batch_number VARCHAR(40)
)
RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_user_mfr      INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_mfr     INT UNSIGNED DEFAULT NULL;

    -- Look up the user
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_user_mfr
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 THEN RETURN 0; END IF;
    IF v_user_role != 'Manufacturer' THEN RETURN 0; END IF;
    IF v_user_mfr IS NULL THEN RETURN 0; END IF;

    -- Look up the batch's factory's manufacturer
    SELECT f.manufacturer_id INTO v_batch_mfr
    FROM Production_Batches pb
    JOIN Factories f ON f.factory_id = pb.factory_id
    WHERE pb.batch_number = p_batch_number;

    IF v_batch_mfr IS NULL THEN RETURN 0; END IF;
    IF v_user_mfr != v_batch_mfr THEN RETURN 0; END IF;

    RETURN 1;
END //
DELIMITER ;


-- =============================================================
-- STORED PROCEDURES
-- Procedures encapsulate multi-step business operations.
-- They use TRANSACTIONs to ensure atomicity and call the
-- functions/triggers defined above.
-- =============================================================

-- -------------------------------------------------------
-- sp_verify_scan
-- Called when the public scans a QR code.
-- 1. Computes verdict via fn_qr_verdict.
-- 2. Inserts into Scan_Log (qr_id NULL if unknown).
-- 3. Returns result sets:
--    a) Main info (verdict, medicine, manufacturer, etc.)
--    b) Uses
--    c) Side effects
--    d) "Avoid taking together with"
--    For unknown codes, only the verdict row is returned.
-- Never exposes suppliers, test values or costs.
--
-- Demonstrates: Stored procedure, multiple result sets,
--               function calls, INSERT + SELECT.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_verify_scan;
DELIMITER //
CREATE PROCEDURE sp_verify_scan(
    IN p_code VARCHAR(64)
)
BEGIN
    DECLARE v_verdict    VARCHAR(20);
    DECLARE v_qr_id     INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_id  INT UNSIGNED DEFAULT NULL;
    DECLARE v_med_id    INT UNSIGNED DEFAULT NULL;

    -- 1. Compute verdict
    SET v_verdict = fn_qr_verdict(p_code);

    -- 2. Look up qr_id (NULL if unknown)
    SELECT qr_id, batch_id
    INTO v_qr_id, v_batch_id
    FROM QR_Codes
    WHERE code = p_code
    LIMIT 1;

    IF v_batch_id IS NOT NULL THEN
        SELECT medicine_id INTO v_med_id
        FROM Production_Batches
        WHERE batch_id = v_batch_id;
    END IF;

    -- 3. Log the scan
    INSERT INTO Scan_Log (scanned_code, qr_id, scanned_at, verdict)
    VALUES (p_code, v_qr_id, NOW(), v_verdict);

    -- 4. Return results
    IF v_qr_id IS NULL THEN
        -- Unknown code: return only the verdict
        SELECT v_verdict AS verdict,
               'Demo data - general information only, ask a doctor or pharmacist.' AS advisory;
    ELSE
        -- Result set 1: main medicine info
        SELECT
            v_verdict           AS verdict,
            m.brand_name        AS medicine_name,
            df.strength,
            ing.ingredient_name AS ingredient,
            mfr.company_name    AS manufacturer,
            pb.batch_number,
            pb.manufacture_date,
            pb.expiry_date,
            m.storage_note,
            pr.reason           AS recall_reason,
            pr.recall_date      AS recall_date,
            'Demo data - general information only, ask a doctor or pharmacist.' AS advisory
        FROM Production_Batches pb
        JOIN Medicines          m   ON m.medicine_id       = pb.medicine_id
        JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
        JOIN Drug_Formulations  df  ON df.medicine_id      = m.medicine_id
        JOIN Ingredients        ing ON ing.ingredient_id   = df.ingredient_id
        LEFT JOIN Product_Recalls pr ON pr.batch_id        = pb.batch_id
        WHERE pb.batch_id = v_batch_id;

        -- Result set 2: uses
        SELECT info_text AS `use`
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'use';

        -- Result set 3: side effects
        SELECT info_text AS side_effect
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'side_effect';

        -- Result set 4: avoid taking together with
        SELECT info_text AS avoid_taking_together_with
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'avoid_with';
    END IF;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_record_test
-- Records a quality test report for a Pending batch.
-- Permission: fn_user_can_manage_batch must return 1.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_test;
DELIMITER //
CREATE PROCEDURE sp_record_test(
    IN p_batch_number      VARCHAR(40),
    IN p_user_id           INT UNSIGNED,
    IN p_purity            DECIMAL(5,2),
    IN p_dissolution       DECIMAL(5,2),
    IN p_weight_variation  DECIMAL(5,2),
    IN p_result            VARCHAR(4),
    IN p_remarks           TEXT
)
BEGIN
    DECLARE v_batch_id INT UNSIGNED;
    DECLARE v_status   VARCHAR(10);
    DECLARE v_err_msg  TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    START TRANSACTION;

        -- Batch must be Pending; lock row
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tests can only be recorded for Pending batches.';
        END IF;

        SET @app_user_id = p_user_id;

        INSERT INTO Quality_Test_Reports
            (batch_id, tested_by, test_date, purity_pct, dissolution_pct,
             weight_variation_pct, result, remarks)
        VALUES
            (v_batch_id, p_user_id, CURDATE(), p_purity, p_dissolution,
             p_weight_variation, p_result, p_remarks);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Test recorded for batch ', p_batch_number,
                  '. Result: ', p_result, '.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_approve_batch
-- Approves a batch and generates QR codes in one atomic
-- TRANSACTION.
-- Permission: fn_user_can_manage_batch must return 1.
-- On error: rolls back and re-signals.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_approve_batch;
DELIMITER //
CREATE PROCEDURE sp_approve_batch(
    IN p_batch_number VARCHAR(40),
    IN p_user_id      INT UNSIGNED,
    IN p_pack_count   INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id INT UNSIGNED;
    DECLARE v_status   VARCHAR(10);
    DECLARE v_i        INT DEFAULT 0;
    DECLARE v_code     VARCHAR(64);
    DECLARE v_err_msg  TEXT;

    -- Error handler: capture message, roll back, re-signal
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    -- Set audit user for AFTER triggers
    SET @app_user_id = p_user_id;

    START TRANSACTION;

        -- Look up and lock the batch
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        -- Update status (BEFORE UPDATE trigger checks latest test and materials)
        UPDATE Production_Batches
        SET status = 'Approved'
        WHERE batch_id = v_batch_id;

        -- Generate QR codes
        WHILE v_i < p_pack_count DO
            SET v_code = CONCAT('PT360-', UPPER(LEFT(MD5(UUID()), 12)));
            INSERT INTO QR_Codes (code, batch_id) VALUES (v_code, v_batch_id);
            SET v_i = v_i + 1;
        END WHILE;

    COMMIT;

    -- Reset session variable
    SET @app_user_id = NULL;

    -- Confirmation
    SELECT CONCAT('Batch ', p_batch_number, ' approved. ',
                  p_pack_count, ' QR codes created.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_reject_batch
-- Rejects a Pending batch whose latest test is Fail.
-- Permission: fn_user_can_manage_batch must return 1.
-- Uses a transaction with rollback on error.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_reject_batch;
DELIMITER //
CREATE PROCEDURE sp_reject_batch(
    IN p_batch_number VARCHAR(40),
    IN p_user_id      INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id      INT UNSIGNED;
    DECLARE v_status        VARCHAR(10);
    DECLARE v_latest_result VARCHAR(4);
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    START TRANSACTION;

        -- Look up and lock batch
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only Pending batches can be rejected.';
        END IF;

        -- Latest test must be Fail
        SELECT result INTO v_latest_result
        FROM Quality_Test_Reports
        WHERE batch_id = v_batch_id
        ORDER BY test_date DESC, report_id DESC
        LIMIT 1;

        IF v_latest_result IS NULL OR v_latest_result != 'Fail' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot reject batch: the most recent quality test is not Fail.';
        END IF;

        SET @app_user_id = p_user_id;

        UPDATE Production_Batches
        SET status = 'Rejected'
        WHERE batch_id = v_batch_id;

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Batch ', p_batch_number, ' rejected.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_issue_recall
-- Issues a recall for a batch in one atomic TRANSACTION.
-- Permission: user must be an active Admin/Regulator.
-- On error: rolls back and re-signals.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_issue_recall;
DELIMITER //
CREATE PROCEDURE sp_issue_recall(
    IN p_batch_number VARCHAR(40),
    IN p_reason       TEXT,
    IN p_user_id      INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id    INT UNSIGNED;
    DECLARE v_err_msg     TEXT;
    DECLARE v_user_active TINYINT DEFAULT 0;
    DECLARE v_user_role   VARCHAR(30) DEFAULT '';

    -- Error handler: capture message, roll back, re-signal
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check: user must be active Admin/Regulator
    SELECT u.is_active, r.role_name
    INTO v_user_active, v_user_role
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Admin/Regulator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: only active Admin/Regulator users can issue recalls.';
    END IF;

    -- Set audit user for AFTER triggers
    SET @app_user_id = p_user_id;

    START TRANSACTION;

        -- Look up and lock the batch
        SELECT batch_id INTO v_batch_id
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        -- Insert recall row FIRST (so the BEFORE UPDATE trigger can find it)
        INSERT INTO Product_Recalls (batch_id, reason, recall_date, issued_by)
        VALUES (v_batch_id, p_reason, CURDATE(), p_user_id);

        -- Set status to Recalled
        UPDATE Production_Batches
        SET status = 'Recalled'
        WHERE batch_id = v_batch_id;

    COMMIT;

    -- Reset session variable
    SET @app_user_id = NULL;

    -- Return impact report
    SELECT
        pb.batch_number,
        m.brand_name          AS medicine,
        s.supplier_name       AS supplier,
        md.certificate_number,
        (SELECT COUNT(*) FROM QR_Codes WHERE batch_id = v_batch_id)
                              AS qr_count,
        (SELECT COUNT(*) FROM Scan_Log sl
         JOIN QR_Codes qr ON qr.qr_id = sl.qr_id
         WHERE qr.batch_id = v_batch_id)
                              AS total_scans
    FROM Production_Batches  pb
    JOIN Medicines           m   ON m.medicine_id    = pb.medicine_id
    LEFT JOIN Batch_Materials bm ON bm.batch_id      = pb.batch_id
    LEFT JOIN Material_Deliveries md ON md.delivery_id = bm.delivery_id
    LEFT JOIN Suppliers      s   ON s.supplier_id    = md.supplier_id
    WHERE pb.batch_id = v_batch_id;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_log_event
-- Logs LOGIN, LOGOUT and LOGIN_FAILED events.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_log_event;
DELIMITER //
CREATE PROCEDURE sp_log_event(
    IN p_user_id INT UNSIGNED,
    IN p_action  VARCHAR(60),
    IN p_details TEXT
)
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (p_user_id, p_action, 'Users', p_user_id, p_details);
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_login_lookup
-- Returns the columns needed for PHP login verification.
-- Returns at most one row.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_login_lookup;
DELIMITER //
CREATE PROCEDURE sp_login_lookup(
    IN p_email VARCHAR(120)
)
BEGIN
    SELECT u.user_id, u.email, u.password_hash,
           r.role_name, u.manufacturer_id, u.is_active
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.email = p_email
    LIMIT 1;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_set_password
-- Updates the password hash for a user by email.
-- Called by the CLI tool only.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_set_password;
DELIMITER //
CREATE PROCEDURE sp_set_password(
    IN p_email VARCHAR(120),
    IN p_hash  VARCHAR(255)
)
BEGIN
    DECLARE v_found INT DEFAULT 0;

    SELECT COUNT(*) INTO v_found
    FROM Users WHERE email = p_email;

    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No user found with that email.';
    END IF;

    UPDATE Users
    SET password_hash = p_hash
    WHERE email = p_email;

    SELECT CONCAT('Password updated for ', p_email, '.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_record_delivery
-- Records a raw material delivery for an active manufacturer.
-- Checks: user must be active Manufacturer, quantity > 0,
-- received_date <= CURDATE(), certificate number unique and
-- non-empty, supplier and ingredient must exist.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_delivery;
DELIMITER //
CREATE PROCEDURE sp_record_delivery(
    IN p_user_id            INT UNSIGNED,
    IN p_supplier_name      VARCHAR(120),
    IN p_ingredient_name    VARCHAR(120),
    IN p_quantity_kg        DECIMAL(10,3),
    IN p_received_date      DATE,
    IN p_certificate_number VARCHAR(60)
)
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_mfr_id        INT UNSIGNED DEFAULT NULL;
    DECLARE v_supplier_id   INT UNSIGNED DEFAULT NULL;
    DECLARE v_ingredient_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_cert_count    INT DEFAULT 0;
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Validate user is active Manufacturer
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_mfr_id
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Manufacturer' OR v_mfr_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: user must be an active Manufacturer.';
    END IF;

    -- Validate quantity > 0
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery quantity must be greater than zero.';
    END IF;

    -- Validate received date not in future
    IF p_received_date IS NULL OR p_received_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Received date cannot be in the future.';
    END IF;

    -- Validate certificate number is new
    IF p_certificate_number IS NULL OR TRIM(p_certificate_number) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Certificate number cannot be empty.';
    END IF;

    SELECT COUNT(*) INTO v_cert_count
    FROM Material_Deliveries
    WHERE certificate_number = p_certificate_number;

    IF v_cert_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Certificate number already exists.';
    END IF;

    -- Validate supplier exists
    SELECT supplier_id INTO v_supplier_id
    FROM Suppliers
    WHERE supplier_name = p_supplier_name
    LIMIT 1;

    IF v_supplier_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Supplier does not exist.';
    END IF;

    -- Validate ingredient exists
    SELECT ingredient_id INTO v_ingredient_id
    FROM Ingredients
    WHERE ingredient_name = p_ingredient_name
    LIMIT 1;

    IF v_ingredient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingredient does not exist.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        INSERT INTO Material_Deliveries
            (supplier_id, ingredient_id, manufacturer_id, quantity_kg, received_date, certificate_number)
        VALUES
            (v_supplier_id, v_ingredient_id, v_mfr_id, p_quantity_kg, p_received_date, p_certificate_number);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Delivery recorded under certificate ', p_certificate_number, '.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_create_batch
-- Creates a new production batch with status 'Pending'.
-- Checks: active Manufacturer, medicine and factory belong to
-- user's manufacturer, manufacture date not in future,
-- expiry date > manufacture date, quantity > 0.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_batch;
DELIMITER //
CREATE PROCEDURE sp_create_batch(
    IN p_user_id          INT UNSIGNED,
    IN p_batch_number     VARCHAR(40),
    IN p_medicine_name    VARCHAR(160),
    IN p_factory_name     VARCHAR(120),
    IN p_quantity         INT UNSIGNED,
    IN p_manufacture_date DATE,
    IN p_expiry_date      DATE
)
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_mfr_id        INT UNSIGNED DEFAULT NULL;
    DECLARE v_medicine_id   INT UNSIGNED DEFAULT NULL;
    DECLARE v_factory_id    INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_count   INT DEFAULT 0;
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Validate user is active Manufacturer
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_mfr_id
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Manufacturer' OR v_mfr_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: user must be an active Manufacturer.';
    END IF;

    -- Validate batch number
    IF p_batch_number IS NULL OR TRIM(p_batch_number) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Batch number cannot be empty.';
    END IF;

    SELECT COUNT(*) INTO v_batch_count
    FROM Production_Batches
    WHERE batch_number = p_batch_number;

    IF v_batch_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Batch number already exists.';
    END IF;

    -- Validate quantity > 0
    IF p_quantity IS NULL OR p_quantity = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than zero.';
    END IF;

    -- Validate medicine belongs to user's manufacturer
    SELECT medicine_id INTO v_medicine_id
    FROM Medicines
    WHERE brand_name = p_medicine_name AND manufacturer_id = v_mfr_id
    LIMIT 1;

    IF v_medicine_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine not found or does not belong to the user manufacturer.';
    END IF;

    -- Validate factory belongs to user's manufacturer
    SELECT factory_id INTO v_factory_id
    FROM Factories
    WHERE factory_name = p_factory_name AND manufacturer_id = v_mfr_id
    LIMIT 1;

    IF v_factory_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Factory not found or does not belong to the user manufacturer.';
    END IF;

    -- Validate manufacture date not in future
    IF p_manufacture_date IS NULL OR p_manufacture_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacture date cannot be in the future.';
    END IF;

    -- Validate expiry date after manufacture date
    IF p_expiry_date IS NULL OR p_expiry_date <= p_manufacture_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date must be after manufacture date.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        INSERT INTO Production_Batches
            (batch_number, medicine_id, factory_id, quantity_units, manufacture_date, expiry_date, status)
        VALUES
            (p_batch_number, v_medicine_id, v_factory_id, p_quantity, p_manufacture_date, p_expiry_date, 'Pending');

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Batch ', p_batch_number, ' created.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_add_batch_material
-- Links raw material from a delivery to a Pending batch.
-- Permission: fn_user_can_manage_batch must return 1.
-- Batch must be Pending, locks batch row with FOR UPDATE.
-- Finds delivery by certificate number.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_batch_material;
DELIMITER //
CREATE PROCEDURE sp_add_batch_material(
    IN p_user_id            INT UNSIGNED,
    IN p_batch_number       VARCHAR(40),
    IN p_certificate_number VARCHAR(60),
    IN p_quantity_used_kg   DECIMAL(10,3)
)
BEGIN
    DECLARE v_batch_id     INT UNSIGNED DEFAULT NULL;
    DECLARE v_status       VARCHAR(10) DEFAULT '';
    DECLARE v_delivery_id  INT UNSIGNED DEFAULT NULL;
    DECLARE v_err_msg      TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    -- Validate quantity used > 0
    IF p_quantity_used_kg IS NULL OR p_quantity_used_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity used must be greater than zero.';
    END IF;

    -- Find delivery by certificate number
    SELECT delivery_id INTO v_delivery_id
    FROM Material_Deliveries
    WHERE certificate_number = p_certificate_number
    LIMIT 1;

    IF v_delivery_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery not found for the given certificate number.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        -- Lock batch row and verify status
        SELECT batch_id, status
        INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Materials can only be added to Pending batches.';
        END IF;

        INSERT INTO Batch_Materials (batch_id, delivery_id, quantity_used_kg)
        VALUES (v_batch_id, v_delivery_id, p_quantity_used_kg);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Material linked to batch ', p_batch_number, '.') AS result;
END //
DELIMITER ;


-- -------------------------------------------------------
-- sp_change_password
-- Updates password_hash for a given user and writes a
-- 'PASSWORD_CHANGED' audit row.
-- Checks: user must exist, hash length must be >= 60.
-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_change_password;
DELIMITER //
CREATE PROCEDURE sp_change_password(
    IN p_user_id  INT UNSIGNED,
    IN p_new_hash VARCHAR(255)
)
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_err_msg     TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Check user existence
    SELECT COUNT(*) INTO v_user_exists
    FROM Users
    WHERE user_id = p_user_id;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found.';
    END IF;

    -- Check hash validity / length (bcrypt hash is 60 chars)
    IF p_new_hash IS NULL OR CHAR_LENGTH(p_new_hash) < 60 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password hash is too short. Must be a valid bcrypt hash of at least 60 characters.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        UPDATE Users
        SET password_hash = p_new_hash
        WHERE user_id = p_user_id;

        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (p_user_id, 'PASSWORD_CHANGED', 'Users', p_user_id, 'Password changed successfully.');

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Password updated for user_id ', p_user_id, '.') AS result;
END //
DELIMITER ;


-- =============================================================
-- ADDITIONAL VIEWS (for the web application)
-- =============================================================

-- -------------------------------------------------------
-- v_demo_codes
-- One sample code each for Genuine (Approved, not expired),
-- Expired (Approved, past expiry) and Recalled batches.
-- Replaces the PHP getDemoCodes() inline query.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_demo_codes AS
SELECT demo_type, code, batch_number
FROM (
    SELECT 'Genuine' AS demo_type, qr.code, pb.batch_number
    FROM QR_Codes qr
    JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
    WHERE pb.status = 'Approved' AND pb.expiry_date >= CURDATE()
    ORDER BY pb.manufacture_date ASC
    LIMIT 1
) AS t_gen
UNION ALL
SELECT demo_type, code, batch_number
FROM (
    SELECT 'Expired' AS demo_type, qr.code, pb.batch_number
    FROM QR_Codes qr
    JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
    WHERE pb.status = 'Approved' AND pb.expiry_date < CURDATE()
    ORDER BY pb.expiry_date ASC
    LIMIT 1
) AS t_exp
UNION ALL
SELECT demo_type, code, batch_number
FROM (
    SELECT 'Recalled' AS demo_type, qr.code, pb.batch_number
    FROM QR_Codes qr
    JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
    WHERE pb.status = 'Recalled'
    ORDER BY pb.batch_id ASC
    LIMIT 1
) AS t_rec;

-- -------------------------------------------------------
-- v_batch_tests
-- Test history for a batch (used by the batch detail page).
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_tests AS
SELECT
    pb.batch_number,
    qtr.test_date,
    qtr.purity_pct       AS purity,
    qtr.dissolution_pct  AS dissolution,
    qtr.weight_variation_pct AS weight_variation,
    qtr.result,
    qtr.remarks
FROM Quality_Test_Reports qtr
JOIN Production_Batches pb ON pb.batch_id = qtr.batch_id;

-- -------------------------------------------------------
-- v_recent_audit
-- Last 20 audit log entries for the admin page.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_recent_audit AS
SELECT
    al.log_id,
    al.user_id,
    u.full_name    AS user_name,
    al.action,
    al.table_name,
    al.record_id,
    al.details,
    al.logged_at
FROM Audit_Logs al
LEFT JOIN Users u ON u.user_id = al.user_id
ORDER BY al.logged_at DESC, al.log_id DESC
LIMIT 20;

-- -------------------------------------------------------
-- v_batch_qr_codes
-- QR codes issued for each batch with scan count and last scan.
-- (batch_number, manufacturer_id, qr_code, issued_at, scan_count, last_scan)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_qr_codes AS
SELECT
    pb.batch_number,
    f.manufacturer_id,
    qr.code             AS qr_code,
    qr.issued_at,
    COUNT(sl.scan_id)   AS scan_count,
    MAX(sl.scanned_at)  AS last_scan
FROM QR_Codes qr
JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
JOIN Factories f          ON f.factory_id = pb.factory_id
LEFT JOIN Scan_Log sl     ON sl.qr_id = qr.qr_id
GROUP BY qr.qr_id, pb.batch_number, f.manufacturer_id, qr.code, qr.issued_at;

-- -------------------------------------------------------
-- v_form_suppliers
-- Supplier options for form dropdowns.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_form_suppliers AS
SELECT supplier_name
FROM Suppliers
ORDER BY supplier_name;

-- -------------------------------------------------------
-- v_form_ingredients
-- Ingredient options for form dropdowns.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_form_ingredients AS
SELECT ingredient_name
FROM Ingredients
ORDER BY ingredient_name;

-- -------------------------------------------------------
-- v_form_medicines
-- Medicine options filtered by manufacturer for forms.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_form_medicines AS
SELECT manufacturer_id, brand_name
FROM Medicines
ORDER BY brand_name;

-- -------------------------------------------------------
-- v_form_factories
-- Factory options filtered by manufacturer for forms.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_form_factories AS
SELECT manufacturer_id, factory_name
FROM Factories
ORDER BY factory_name;

-- -------------------------------------------------------
-- v_my_deliveries
-- Delivery inventory per manufacturer with used and remaining kg.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_my_deliveries AS
SELECT
    md.manufacturer_id,
    md.certificate_number,
    ing.ingredient_name,
    s.supplier_name,
    md.received_date,
    md.quantity_kg,
    COALESCE(SUM(bm.quantity_used_kg), 0) AS used_kg,
    (md.quantity_kg - COALESCE(SUM(bm.quantity_used_kg), 0)) AS remaining_kg
FROM Material_Deliveries md
JOIN Ingredients ing ON ing.ingredient_id = md.ingredient_id
JOIN Suppliers s ON s.supplier_id = md.supplier_id
LEFT JOIN Batch_Materials bm ON bm.delivery_id = md.delivery_id
GROUP BY md.delivery_id, md.manufacturer_id, md.certificate_number,
         ing.ingredient_name, s.supplier_name, md.received_date, md.quantity_kg;

-- -------------------------------------------------------
-- v_batch_timeline
-- Comprehensive batch lifecycle timeline built from base tables
-- so seeded batches have full history: manufactured, material received
-- and linked, QA tests, QR codes issued, audit status changes, and recalls.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_timeline AS
SELECT
    pb.batch_number,
    f.manufacturer_id,
    CAST(pb.manufacture_date AS DATETIME) AS event_time,
    CONVERT('BATCH_MANUFACTURED' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT('Batch manufactured with ', pb.quantity_units, ' units.') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Production_Batches pb
JOIN Factories f ON f.factory_id = pb.factory_id

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    CAST(md.received_date AS DATETIME) AS event_time,
    CONVERT('MATERIAL_RECEIVED' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT('Raw material ', ing.ingredient_name, ' (', md.quantity_kg, ' kg, Cert: ', COALESCE(md.certificate_number, 'N/A'), ') received from ', s.supplier_name, '.') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Batch_Materials bm
JOIN Production_Batches pb   ON pb.batch_id = bm.batch_id
JOIN Factories f             ON f.factory_id = pb.factory_id
JOIN Material_Deliveries md  ON md.delivery_id = bm.delivery_id
JOIN Ingredients ing         ON ing.ingredient_id = md.ingredient_id
JOIN Suppliers s             ON s.supplier_id = md.supplier_id

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    CAST(pb.manufacture_date AS DATETIME) AS event_time,
    CONVERT('MATERIAL_LINKED' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT('Linked ', bm.quantity_used_kg, ' kg of ', ing.ingredient_name, ' (Cert: ', COALESCE(md.certificate_number, 'N/A'), ') to batch.') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Batch_Materials bm
JOIN Production_Batches pb   ON pb.batch_id = bm.batch_id
JOIN Factories f             ON f.factory_id = pb.factory_id
JOIN Material_Deliveries md  ON md.delivery_id = bm.delivery_id
JOIN Ingredients ing         ON ing.ingredient_id = md.ingredient_id

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    CAST(qtr.test_date AS DATETIME) AS event_time,
    CONVERT('QA_TEST' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT('Quality test completed. Result: ', qtr.result, '. Purity: ', COALESCE(CONCAT(qtr.purity_pct, '%'), 'N/A'), ', Dissolution: ', COALESCE(CONCAT(qtr.dissolution_pct, '%'), 'N/A'), '.') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Quality_Test_Reports qtr
JOIN Production_Batches pb ON pb.batch_id = qtr.batch_id
JOIN Factories f           ON f.factory_id = pb.factory_id

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    MIN(qr.issued_at)   AS event_time,
    CONVERT('QR_ISSUED' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT(COUNT(qr.qr_id), ' serialized QR codes generated and issued.') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM QR_Codes qr
JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
JOIN Factories f           ON f.factory_id = pb.factory_id
GROUP BY pb.batch_id, pb.batch_number, f.manufacturer_id

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    al.logged_at  AS event_time,
    CONVERT(al.action USING utf8mb4) COLLATE utf8mb4_unicode_ci  AS event_type,
    CONVERT(al.details USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Audit_Logs al
JOIN Production_Batches pb ON pb.batch_id = al.record_id
JOIN Factories f           ON f.factory_id = pb.factory_id
WHERE al.table_name = 'Production_Batches'
  AND al.action LIKE 'STATUS_%'

UNION ALL

SELECT
    pb.batch_number,
    f.manufacturer_id,
    CAST(pr.recall_date AS DATETIME) AS event_time,
    CONVERT('RECALL_ISSUED' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS event_type,
    CONVERT(CONCAT('Batch recalled. Reason: ', pr.reason) USING utf8mb4) COLLATE utf8mb4_unicode_ci AS description
FROM Product_Recalls pr
JOIN Production_Batches pb ON pb.batch_id = pr.batch_id
JOIN Factories f           ON f.factory_id = pb.factory_id;

-- -------------------------------------------------------
-- v_recall_list
-- Summary list of all product recalls with batch, medicine,
-- manufacturer, contact email, QR count, total scans, and post-recall scans.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_recall_list AS
SELECT
    pr.recall_id,
    pb.batch_number,
    m.brand_name       AS medicine,
    mfr.company_name   AS manufacturer,
    pr.reason,
    pr.recall_date,
    u.email            AS issued_by_email,
    (SELECT COUNT(*) FROM QR_Codes qr WHERE qr.batch_id = pb.batch_id) AS qr_count,
    (SELECT COUNT(*)
     FROM Scan_Log sl
     JOIN QR_Codes qr ON qr.qr_id = sl.qr_id
     WHERE qr.batch_id = pb.batch_id) AS total_scans,
    (SELECT COUNT(*)
     FROM Scan_Log sl
     JOIN QR_Codes qr ON qr.qr_id = sl.qr_id
     WHERE qr.batch_id = pb.batch_id
       AND sl.scanned_at >= CAST(pr.recall_date AS DATETIME)) AS scans_after_recall
FROM Product_Recalls pr
JOIN Production_Batches pb ON pb.batch_id = pr.batch_id
JOIN Medicines m           ON m.medicine_id = pb.medicine_id
JOIN Factories f           ON f.factory_id = pb.factory_id
JOIN Manufacturers mfr     ON mfr.manufacturer_id = f.manufacturer_id
JOIN Users u               ON u.user_id = pr.issued_by;

-- =============================================================
-- End of 03_logic.sql
-- Run SHOW FUNCTION STATUS WHERE Db = 'pharmatrace360';
-- and SHOW PROCEDURE STATUS WHERE Db = 'pharmatrace360';
-- to verify everything was created.
-- =============================================================
