-- =============================================================
-- 09_upgrade_existing.sql - Non-destructive schema/routine upgrade
-- Run from the repository root against an existing PharmaTrace360 DB.
-- DOES NOT drop or reseed the database.
-- =============================================================
USE pharmatrace360;

-- Fail before altering the schema if legacy certificate duplicates would make
-- the new uniqueness constraint impossible. No delivery rows are deleted.
DROP PROCEDURE IF EXISTS _pt_assert_unique_certificates;
DELIMITER //
CREATE PROCEDURE _pt_assert_unique_certificates()
BEGIN
    DECLARE v_duplicates INT DEFAULT 0;
    SELECT COUNT(*) INTO v_duplicates
    FROM (
        SELECT certificate_number
        FROM Material_Deliveries
        WHERE certificate_number IS NOT NULL
        GROUP BY certificate_number
        HAVING COUNT(*) > 1
    ) AS duplicate_certificates;

    IF v_duplicates > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Upgrade stopped: duplicate certificate numbers exist. Resolve them before retrying.';
    END IF;
END //
DELIMITER ;
CALL _pt_assert_unique_certificates();
DROP PROCEDURE _pt_assert_unique_certificates;

-- Add precise recall timestamp. Existing records only have a DATE, so use
-- midnight as the best available historical value; new records get real time.
SET @has_recall_issued_at = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Product_Recalls'
      AND COLUMN_NAME = 'issued_at'
);
SET @ddl = IF(@has_recall_issued_at = 0,
    'ALTER TABLE Product_Recalls ADD COLUMN issued_at DATETIME NULL AFTER recall_date',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE Product_Recalls
SET issued_at = CAST(recall_date AS DATETIME)
WHERE issued_at IS NULL;

ALTER TABLE Product_Recalls
    MODIFY COLUMN issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- These indexes improve the latest-QA lookup and prevent duplicate non-NULL
-- certificates. If a legacy database contains duplicate certificates, resolve
-- them before this index step; the CREATE UNIQUE INDEX will safely fail rather
-- than deleting or rewriting existing delivery records.
SET @has_cert_index = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Material_Deliveries'
      AND INDEX_NAME = 'uq_delivery_certificate'
);
SET @ddl = IF(@has_cert_index = 0,
    'CREATE UNIQUE INDEX uq_delivery_certificate ON Material_Deliveries (certificate_number)',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_qtr_index = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Quality_Test_Reports'
      AND INDEX_NAME = 'idx_qtr_batch_latest'
);
SET @ddl = IF(@has_qtr_index = 0,
    'CREATE INDEX idx_qtr_batch_latest ON Quality_Test_Reports (batch_id, test_date, report_id)',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Preserve QA and material history when deleting batches.
SET @bm_delete_rule = (
    SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Batch_Materials'
      AND CONSTRAINT_NAME = 'fk_bm_batch'
    LIMIT 1
);
SET @ddl = IF(@bm_delete_rule = 'CASCADE',
    'ALTER TABLE Batch_Materials DROP FOREIGN KEY fk_bm_batch, ADD CONSTRAINT fk_bm_batch FOREIGN KEY (batch_id) REFERENCES Production_Batches (batch_id) ON DELETE RESTRICT ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @qtr_delete_rule = (
    SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Quality_Test_Reports'
      AND CONSTRAINT_NAME = 'fk_qtr_batch'
    LIMIT 1
);
SET @ddl = IF(@qtr_delete_rule = 'CASCADE',
    'ALTER TABLE Quality_Test_Reports DROP FOREIGN KEY fk_qtr_batch, ADD CONSTRAINT fk_qtr_batch FOREIGN KEY (batch_id) REFERENCES Production_Batches (batch_id) ON DELETE RESTRICT ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Recreate routines/views/grants without dropping or reseeding any rows.
SOURCE db/03_logic.sql;
SOURCE db/06_suspicious_review.sql;
SOURCE db/05_grants.sql;

SELECT 'Non-destructive hardening upgrade completed.' AS status;
