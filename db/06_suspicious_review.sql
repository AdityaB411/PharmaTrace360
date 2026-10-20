-- =============================================================
-- 06_suspicious_review.sql - Migration: Suspicious Scans Review Status
-- PharmaTrace 360 - MySQL 8.0+
-- Adds review_status to Scan_Log, updates v_suspicious_codes,
-- adds stored procedure sp_update_suspicious_review, and grants execution to pt_app.
--
-- Do NOT store passwords or credentials in this file.
-- =============================================================
-- HOW TO RUN (from your own Command Prompt):
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < "E:\DBMS\PharmaTrace360\db\06_suspicious_review.sql"
-- =============================================================

USE pharmatrace360;

-- -------------------------------------------------------------
-- 1. SCHEMA CHANGE: Add review_status to Scan_Log
--    Allowed values: 'New', 'Reviewed', 'Blocked'
--    Default: 'New'
-- -------------------------------------------------------------
ALTER TABLE Scan_Log
    ADD COLUMN review_status ENUM('New', 'Reviewed', 'Blocked') NOT NULL DEFAULT 'New';

CREATE INDEX idx_scan_review_status ON Scan_Log (review_status);

-- -------------------------------------------------------------
-- 2. VIEW UPDATE: v_suspicious_codes
--    Exposes the latest review_status alongside aggregated scan metrics.
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_suspicious_codes AS
SELECT
    sl.scanned_code,
    COUNT(*)            AS scan_count,
    MIN(sl.scanned_at)  AS first_scan,
    MAX(sl.scanned_at)  AS last_scan,
    (
        SELECT sl2.review_status
        FROM Scan_Log sl2
        WHERE sl2.scanned_code = sl.scanned_code
        ORDER BY sl2.scanned_at DESC, sl2.scan_id DESC
        LIMIT 1
    )                   AS review_status
FROM Scan_Log sl
GROUP BY sl.scanned_code
HAVING COUNT(*) > 5;

-- -------------------------------------------------------------
-- 3. STORED PROCEDURE: sp_update_suspicious_review
--    Allows Admin/Regulator to change the review_status of a scanned code.
--    Enforces least privilege, input validation, and audit logging.
-- -------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_update_suspicious_review;
DELIMITER //
CREATE PROCEDURE sp_update_suspicious_review(
    IN p_code    VARCHAR(64),
    IN p_status  VARCHAR(20),
    IN p_user_id INT UNSIGNED
)
BEGIN
    DECLARE v_user_active TINYINT DEFAULT 0;
    DECLARE v_user_role   VARCHAR(30) DEFAULT '';
    DECLARE v_count       INT DEFAULT 0;
    DECLARE v_err_msg     TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    -- Permission check: caller must be an active Admin/Regulator user
    SELECT u.is_active, r.role_name
    INTO v_user_active, v_user_role
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Admin/Regulator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: only active Admin/Regulator users can review suspicious codes.';
    END IF;

    -- Validate input status
    IF p_status NOT IN ('New', 'Reviewed', 'Blocked') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid review status. Allowed values: New, Reviewed, Blocked.';
    END IF;

    -- Verify that the code exists in Scan_Log
    SELECT COUNT(*) INTO v_count
    FROM Scan_Log
    WHERE scanned_code = p_code;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No scan records found for the specified code.';
    END IF;

    -- Perform atomic update and record audit entry
    START TRANSACTION;

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

-- -------------------------------------------------------------
-- 4. GRANTS: Least-privilege permissions for pt_app
-- -------------------------------------------------------------
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_update_suspicious_review TO 'pt_app'@'localhost';
GRANT SELECT  ON pharmatrace360.v_suspicious_codes                    TO 'pt_app'@'localhost';

FLUSH PRIVILEGES;

SELECT 'Migration 06_suspicious_review.sql successfully applied.' AS status;
