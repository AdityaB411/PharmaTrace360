-- =============================================================
-- PharmaTrace 360 - Database Schema
-- MySQL 8.0+  (uses CHECK constraints, native JSON optional)
-- Run this file to create / recreate the full database.
-- Do NOT store passwords or credentials in this file.
-- =============================================================
-- HOW TO RUN (from your own Command Prompt):
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < "E:\DBMS\PharmaTrace360\db\01_schema.sql"
--
-- VERIFY afterwards (inside the mysql prompt):
--   USE pharmatrace360;
--   SHOW TABLES;
--   SHOW INDEX FROM Scan_Log;
-- =============================================================

-- Drop and recreate the database so this file is fully re-runnable
DROP DATABASE IF EXISTS pharmatrace360;
CREATE DATABASE pharmatrace360
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pharmatrace360;

-- -------------------------------------------------------
-- 1. Roles
--    Exactly 2 rows will be inserted by the seed script:
--    'Admin/Regulator' and 'Manufacturer'.
--    The Public does NOT log in and has no row here.
-- -------------------------------------------------------
CREATE TABLE Roles (
    role_id   TINYINT      UNSIGNED NOT NULL AUTO_INCREMENT,
    role_name VARCHAR(30)  NOT NULL,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_roles_name (role_name)
);

-- -------------------------------------------------------
-- 2. Manufacturers
--    A company that produces medicines.
-- -------------------------------------------------------
CREATE TABLE Manufacturers (
    manufacturer_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    company_name      VARCHAR(120) NOT NULL,
    registration_no   VARCHAR(60)  NOT NULL,
    contact_email     VARCHAR(120),
    contact_phone     VARCHAR(20),
    address           TEXT,
    PRIMARY KEY (manufacturer_id),
    UNIQUE KEY uq_mfr_reg (registration_no)
);

-- -------------------------------------------------------
-- 3. Factories
--    A Manufacturer owns one or more Factories (1-to-many).
-- -------------------------------------------------------
CREATE TABLE Factories (
    factory_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    manufacturer_id INT          UNSIGNED NOT NULL,
    factory_name    VARCHAR(120) NOT NULL,
    location        VARCHAR(200),
    license_no      VARCHAR(60),
    PRIMARY KEY (factory_id),
    CONSTRAINT fk_factory_mfr
        FOREIGN KEY (manufacturer_id)
        REFERENCES Manufacturers (manufacturer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 4. Users
--    Admin/Regulator: manufacturer_id = NULL
--    Manufacturer user: manufacturer_id = the company they belong to
-- -------------------------------------------------------
CREATE TABLE Users (
    user_id         INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(120) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,   -- bcrypt via PHP password_hash()
    role_id         TINYINT      UNSIGNED NOT NULL,
    manufacturer_id INT          UNSIGNED,   -- NULL for Admin/Regulator
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_email (email),
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id)
        REFERENCES Roles (role_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_users_mfr
        FOREIGN KEY (manufacturer_id)
        REFERENCES Manufacturers (manufacturer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 5. Suppliers
--    Companies that supply raw materials.
-- -------------------------------------------------------
CREATE TABLE Suppliers (
    supplier_id     INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_name   VARCHAR(120) NOT NULL,
    contact_email   VARCHAR(120),
    contact_phone   VARCHAR(20),
    address         TEXT,
    PRIMARY KEY (supplier_id)
);

-- -------------------------------------------------------
-- 6. Ingredients
--    Raw materials / active pharmaceutical ingredients.
--    Name must be unique (one row per substance).
-- -------------------------------------------------------
CREATE TABLE Ingredients (
    ingredient_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    ingredient_name VARCHAR(120) NOT NULL,
    cas_number      VARCHAR(30),             -- optional chemical identifier
    PRIMARY KEY (ingredient_id),
    UNIQUE KEY uq_ingredient_name (ingredient_name)
);

-- -------------------------------------------------------
-- 7. Material_Deliveries
--    A supplier delivers an ingredient to a manufacturer.
-- -------------------------------------------------------
CREATE TABLE Material_Deliveries (
    delivery_id          INT           UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_id          INT           UNSIGNED NOT NULL,
    ingredient_id        INT           UNSIGNED NOT NULL,
    manufacturer_id      INT           UNSIGNED NOT NULL,  -- who received it
    quantity_kg          DECIMAL(10,3) NOT NULL,
    received_date        DATE          NOT NULL,
    certificate_number   VARCHAR(60),
    PRIMARY KEY (delivery_id),
    UNIQUE KEY uq_delivery_certificate (certificate_number),
    CONSTRAINT chk_delivery_qty CHECK (quantity_kg > 0),
    CONSTRAINT fk_delivery_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES Suppliers (supplier_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_delivery_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES Ingredients (ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_delivery_mfr
        FOREIGN KEY (manufacturer_id)
        REFERENCES Manufacturers (manufacturer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 8. Medicines
--    One row per branded product.
--    Columns mirror data/clean/medicines_15.csv.
-- -------------------------------------------------------
CREATE TABLE Medicines (
    medicine_id       INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    brand_name        VARCHAR(160) NOT NULL,
    manufacturer_id   INT          UNSIGNED NOT NULL,
    dosage_form       VARCHAR(60)  NOT NULL,   -- e.g. Tablet, Syrup
    pack_size         VARCHAR(80),             -- e.g. strip of 10 tablets
    therapeutic_class VARCHAR(80),             -- e.g. ANTI INFECTIVES
    habit_forming     TINYINT(1)   NOT NULL DEFAULT 0,
    storage_note      TEXT,
    source_note       TEXT,
    PRIMARY KEY (medicine_id),
    UNIQUE KEY uq_medicine_brand (brand_name, manufacturer_id),
    CONSTRAINT fk_medicine_mfr
        FOREIGN KEY (manufacturer_id)
        REFERENCES Manufacturers (manufacturer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 9. Drug_Formulations
--    Many-to-many: Medicines <-> Ingredients
--    Stores active ingredients + strength only.
--    Composite PK (medicine_id, ingredient_id).
-- -------------------------------------------------------
CREATE TABLE Drug_Formulations (
    medicine_id     INT          UNSIGNED NOT NULL,
    ingredient_id   INT          UNSIGNED NOT NULL,
    strength        VARCHAR(30)  NOT NULL,    -- e.g. 500mg
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    PRIMARY KEY (medicine_id, ingredient_id),
    CONSTRAINT fk_df_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES Medicines (medicine_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_df_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES Ingredients (ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 10. Medicine_Info
--     One row per info item (use, side_effect, avoid_with).
--     Removes repeating groups from Medicines (enforces 1NF).
-- -------------------------------------------------------
CREATE TABLE Medicine_Info (
    info_id     INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    medicine_id INT          UNSIGNED NOT NULL,
    info_type   ENUM('use','side_effect','avoid_with') NOT NULL,
    info_text   TEXT         NOT NULL,
    PRIMARY KEY (info_id),
    CONSTRAINT fk_info_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES Medicines (medicine_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 11. Production_Batches
--     A Batch is manufactured at one Factory for one Medicine.
--     expiry_date must be after manufacture_date (CHECK).
-- -------------------------------------------------------
CREATE TABLE Production_Batches (
    batch_id         INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    batch_number     VARCHAR(40)  NOT NULL,
    medicine_id      INT          UNSIGNED NOT NULL,
    factory_id       INT          UNSIGNED NOT NULL,
    quantity_units   INT          UNSIGNED NOT NULL,
    manufacture_date DATE         NOT NULL,
    expiry_date      DATE         NOT NULL,
    status           ENUM('Pending','Approved','Rejected','Recalled')
                                  NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (batch_id),
    UNIQUE KEY uq_batch_number (batch_number),  -- also serves as the lookup index for batch_number
    CONSTRAINT chk_batch_qty   CHECK (quantity_units > 0),
    CONSTRAINT chk_batch_dates CHECK (expiry_date > manufacture_date),
    CONSTRAINT fk_batch_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES Medicines (medicine_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_batch_factory
        FOREIGN KEY (factory_id)
        REFERENCES Factories (factory_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 12. Batch_Materials
--     Links a Production_Batch to the specific
--     Material_Deliveries used. Composite PK.
-- -------------------------------------------------------
CREATE TABLE Batch_Materials (
    batch_id         INT           UNSIGNED NOT NULL,
    delivery_id      INT           UNSIGNED NOT NULL,
    quantity_used_kg DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (batch_id, delivery_id),
    CONSTRAINT chk_bm_qty CHECK (quantity_used_kg > 0),
    CONSTRAINT fk_bm_batch
        FOREIGN KEY (batch_id)
        REFERENCES Production_Batches (batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_bm_delivery
        FOREIGN KEY (delivery_id)
        REFERENCES Material_Deliveries (delivery_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 13. Quality_Test_Reports
--     Many reports per batch (re-tests allowed).
--     tested_by references a User.
-- -------------------------------------------------------
CREATE TABLE Quality_Test_Reports (
    report_id            INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    batch_id             INT          UNSIGNED NOT NULL,
    tested_by            INT          UNSIGNED NOT NULL,   -- user_id
    test_date            DATE         NOT NULL,
    purity_pct           DECIMAL(5,2),
    dissolution_pct      DECIMAL(5,2),
    weight_variation_pct DECIMAL(5,2),
    result               ENUM('Pass','Fail') NOT NULL,
    remarks              TEXT,
    PRIMARY KEY (report_id),
    KEY idx_qtr_batch_latest (batch_id, test_date, report_id),
    CONSTRAINT chk_purity       CHECK (purity_pct       IS NULL OR purity_pct       BETWEEN 0 AND 100),
    CONSTRAINT chk_dissolution  CHECK (dissolution_pct  IS NULL OR dissolution_pct  BETWEEN 0 AND 100),
    CONSTRAINT chk_weight_var   CHECK (weight_variation_pct IS NULL OR weight_variation_pct BETWEEN 0 AND 100),
    CONSTRAINT fk_qtr_batch
        FOREIGN KEY (batch_id)
        REFERENCES Production_Batches (batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_qtr_user
        FOREIGN KEY (tested_by)
        REFERENCES Users (user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 14. QR_Codes
--     One code per pack/unit - a batch has MANY QR codes (1-to-many).
--     Repeated scans of the same code are what the system flags as a
--     possible counterfeit copy.
--     code is a UUID or similar unique string.
-- -------------------------------------------------------
CREATE TABLE QR_Codes (
    qr_id     INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    code      VARCHAR(64)  NOT NULL,
    batch_id  INT          UNSIGNED NOT NULL,
    issued_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (qr_id),
    UNIQUE KEY uq_qr_code (code),  -- also serves as the lookup index for public scans
    CONSTRAINT fk_qr_batch
        FOREIGN KEY (batch_id)
        REFERENCES Production_Batches (batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 15. Scan_Log
--     Records every scan attempt.
--     scanned_code: plain text - unknown codes must still be stored.
--     qr_id: nullable FK - NULL when the code was not found.
-- -------------------------------------------------------
CREATE TABLE Scan_Log (
    scan_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    scanned_code VARCHAR(64)  NOT NULL,
    qr_id        INT          UNSIGNED,             -- NULL if code unknown
    scanned_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verdict      ENUM('Genuine','Expired','Recalled','Not approved','Suspicious')
                              NOT NULL,
    PRIMARY KEY (scan_id),
    CONSTRAINT fk_scan_qr
        FOREIGN KEY (qr_id)
        REFERENCES QR_Codes (qr_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Indexes for scan analysis queries
-- Composite index covers both code-lookup and time-range queries;
-- it also replaces a single-column idx_scan_code (leftmost prefix rule).
CREATE INDEX idx_scan_code_time ON Scan_Log (scanned_code, scanned_at);
CREATE INDEX idx_scan_at        ON Scan_Log (scanned_at);

-- -------------------------------------------------------
-- 16. Product_Recalls
--     One recall per batch (UNIQUE batch_id).
--     issued_by references a User.
-- -------------------------------------------------------
CREATE TABLE Product_Recalls (
    recall_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    batch_id    INT          UNSIGNED NOT NULL,
    reason      TEXT         NOT NULL,
    recall_date DATE         NOT NULL,
    issued_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issued_by   INT          UNSIGNED NOT NULL,   -- user_id
    PRIMARY KEY (recall_id),
    UNIQUE KEY uq_recall_batch (batch_id),
    CONSTRAINT fk_recall_batch
        FOREIGN KEY (batch_id)
        REFERENCES Production_Batches (batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_recall_user
        FOREIGN KEY (issued_by)
        REFERENCES Users (user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -------------------------------------------------------
-- 17. Audit_Logs
--     Append-only history of important actions.
--     user_id nullable: some events may be system-generated.
-- -------------------------------------------------------
CREATE TABLE Audit_Logs (
    log_id     BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    INT          UNSIGNED,            -- NULL = system action
    action     VARCHAR(60)  NOT NULL,            -- e.g. 'RECALL_BATCH'
    table_name VARCHAR(60)  NOT NULL,
    record_id  INT          UNSIGNED,            -- PK of the affected row
    details    TEXT,
    logged_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id),
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id)
        REFERENCES Users (user_id)
        ON DELETE RESTRICT  -- users are deactivated (is_active = 0), never deleted
        ON UPDATE CASCADE
);

-- =============================================================
-- End of 01_schema.sql
-- Run SHOW TABLES; and SHOW INDEX FROM Scan_Log; after loading
-- to verify all 17 tables and the correct indexes exist.
-- =============================================================
