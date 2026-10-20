-- =============================================================
-- 10_setup_grants.sql - CLI-only password bootstrap privilege
-- Create pt_setup manually as documented in docs/SETUP.md first.
-- =============================================================
USE pharmatrace360;
GRANT EXECUTE ON PROCEDURE pharmatrace360.sp_set_password TO 'pt_setup'@'localhost';
SELECT 'CLI password setup permission granted to pt_setup.' AS status;
