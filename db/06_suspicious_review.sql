-- =============================================================
-- 06_suspicious_review.sql - Persistent suspicious-code review status
-- MySQL 8.0+. Safe to re-run; does not drop or reseed project data.
-- =============================================================
USE pharmatrace360;

SET @has_review_status = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Scan_Log'
      AND COLUMN_NAME = 'review_status'
);
SET @ddl = IF(@has_review_status = 0,
    'ALTER TABLE Scan_Log ADD COLUMN review_status ENUM(''New'', ''Reviewed'', ''Blocked'') NOT NULL DEFAULT ''New''',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_review_index = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Scan_Log'
      AND INDEX_NAME = 'idx_scan_review_status'
);
SET @ddl = IF(@has_review_index = 0,
    'CREATE INDEX idx_scan_review_status ON Scan_Log (review_status)',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Review status is a code-level analyst decision. A new scan has default
-- status New but must not erase a previous Reviewed/Blocked decision.
CREATE OR REPLACE VIEW v_suspicious_codes AS
SELECT
    sl.scanned_code,
    COUNT(*) AS scan_count,
    MIN(sl.scanned_at) AS first_scan,
    MAX(sl.scanned_at) AS last_scan,
    COALESCE((
        SELECT sl2.review_status
        FROM Scan_Log sl2
        WHERE sl2.scanned_code = sl.scanned_code
          AND sl2.review_status <> 'New'
        ORDER BY sl2.scanned_at DESC, sl2.scan_id DESC
        LIMIT 1
    ), 'New') AS review_status
FROM Scan_Log sl
WHERE sl.scanned_at >= NOW() - INTERVAL 48 HOUR
GROUP BY sl.scanned_code
HAVING COUNT(*) > 10;

DROP PROCEDURE IF EXISTS sp_update_suspicious_review;
DELIMITER //
CREATE PROCEDURE sp_update_suspicious_review(
    IN p_code    VARCHAR(64),
    IN p_status  VARCHAR(20),
    IN p_user_id INT UNSIGNED
)
BEGIN
    DECLARE v_user_active TINYINT DEFAULT 0;
    DECLARE v_user_role VARCHAR(30) DEFAULT '';
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_err_msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    SELECT u.is_active, r.role_name
    INTO v_user_active, v_user_role
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Admin/Regulator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: only active Admin/Regulator users can review suspicious codes.';
    END IF;

    IF p_status IS NULL OR p_status NOT IN ('New', 'Reviewed', 'Blocked') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid review status. Allowed values: New, Reviewed, Blocked.';
    END IF;

    IF p_code IS NULL OR TRIM(p_code) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Scanned code is required.';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM Scan_Log
    WHERE scanned_code = p_code;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No scan records found for the specified code.';
    END IF;

    START TRANSACTION;

        -- Update every event for this code so an explicit reset to New is
        -- distinguishable from a newly inserted scan's default New status.
        UPDATE Scan_Log
        SET review_status = p_status
        WHERE scanned_code = p_code;

        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (
            p_user_id,
            'REVIEW_SUSPICIOUS_CODE',
            'Scan_Log',
            NULL,
            CONCAT('Suspicious code ', p_code, ' review status changed to ', p_status, '.')
        );

    COMMIT;

    SELECT CONCAT('Code ', p_code, ' review status updated to ', p_status, '.') AS result;
END //
DELIMITER ;

GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_update_suspicious_review TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_suspicious_codes TO 'pt_app'@'localhost';

FLUSH PRIVILEGES;
SELECT 'Migration 06_suspicious_review.sql successfully applied.' AS status;
