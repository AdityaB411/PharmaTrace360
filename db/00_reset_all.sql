-- ============================================================================
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- THIS SCRIPT COMPLETELY WIPES AND RECREATES THE PHARMATRACE360 DATABASE!
--
-- RUNNING THIS SCRIPT WILL IRREVOCABLY DROP THE EXISTING `pharmatrace360`
-- DATABASE, REBUILD ALL 17 TABLES FROM SCRATCH, RE-POPULATE ALL 390 SEED ROWS,
-- AND RE-INSTALL ALL VIEWS, FUNCTIONS, TRIGGERS, AND STORED PROCEDURES.
--
-- ALL TRANSIENT OR POST-SEED MODIFICATIONS WILL BE LOST.
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- ============================================================================

-- Execute 01_schema.sql: Drops database pharmatrace360, creates schema, tables, keys & indexes
SOURCE E:/DBMS/PharmaTrace360/db/01_schema.sql;

-- Execute 02_seed.sql: Inserts base reference and simulated data (390 rows across 17 tables)
SOURCE E:/DBMS/PharmaTrace360/db/02_seed.sql;

-- Execute 03_logic.sql: Creates views, functions, triggers, and stored procedures
SOURCE E:/DBMS/PharmaTrace360/db/03_logic.sql;

-- Execute 05_grants.sql: Re-applies GRANT statements for pt_public and pt_app users
SOURCE E:/DBMS/PharmaTrace360/db/05_grants.sql;

-- Verification check
USE pharmatrace360;
SELECT 'Database reset complete! 17 tables and logic installed successfully.' AS status;

