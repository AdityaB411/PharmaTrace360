-- =============================================================
-- 05_grants.sql - GRANT statements for PharmaTrace 360
-- MySQL 8.0+
-- =============================================================
-- These users are created ONCE by hand with CREATE USER.
-- This file is re-applied after every reset (00_reset_all.sql).
--
-- CREATE USER commands (run manually, one time only):
--   CREATE USER 'pt_public'@'localhost' IDENTIFIED BY '...';
--   CREATE USER 'pt_app'@'localhost'    IDENTIFIED BY '...';
--
-- This file contains ONLY GRANT statements. No passwords,
-- no CREATE USER, and no credentials of any kind.
-- =============================================================

USE pharmatrace360;

-- -------------------------------------------------------
-- Apply least-privilege grants directly.
-- No REVOKE statements are used because new accounts only
-- possess USAGE on *.*, which would trigger ERROR 1141 if
-- database-level privileges were not previously granted.
-- -------------------------------------------------------

-- -------------------------------------------------------
-- pt_public@localhost
-- Used by the anonymous public scan page.
-- Can only execute sp_verify_scan and read v_demo_codes.
-- -------------------------------------------------------
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_verify_scan TO 'pt_public'@'localhost';
GRANT SELECT  ON pharmatrace360.v_demo_codes             TO 'pt_public'@'localhost';

-- -------------------------------------------------------
-- pt_app@localhost
-- Used by authenticated (logged-in) pages.
-- Can execute business procedures and read views.
-- No direct table access.
-- -------------------------------------------------------

-- Procedures
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_record_test        TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_approve_batch      TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_reject_batch       TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_issue_recall       TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_log_event          TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_login_lookup       TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_set_password       TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_record_delivery    TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_create_batch        TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_add_batch_material  TO 'pt_app'@'localhost';
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_change_password     TO 'pt_app'@'localhost';

-- Views
GRANT SELECT ON pharmatrace360.v_batch_overview       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_batch_traceability   TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_suspicious_codes     TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_dashboard            TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_batch_status_counts  TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_batch_tests          TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_recent_audit         TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_batch_qr_codes       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_form_suppliers       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_form_ingredients     TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_form_medicines       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_form_factories       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_my_deliveries        TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_batch_timeline       TO 'pt_app'@'localhost';
GRANT SELECT ON pharmatrace360.v_recall_list          TO 'pt_app'@'localhost';

FLUSH PRIVILEGES;

SELECT 'Grants applied for pt_public and pt_app.' AS status;
