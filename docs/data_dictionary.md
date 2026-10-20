# PharmaTrace 360 — Data Dictionary

> Source: `db/01_schema.sql`. Columns listed in schema order.
> Key: `PK` = primary key · `FK` = foreign key · `UQ` = unique index · `CK` = check constraint

---

## 1. Roles

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| role_id | TINYINT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a role. |
| role_name | VARCHAR(30) | No | UQ `uq_roles_name` | | Human-readable role label, e.g. `Admin/Regulator`, `Manufacturer`. |

---

## 2. Manufacturers

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| manufacturer_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a manufacturing company. |
| company_name | VARCHAR(120) | No | | | Legal name of the pharmaceutical manufacturer. |
| registration_no | VARCHAR(60) | No | UQ `uq_mfr_reg` | | Government drug-licence registration number (must be unique). |
| contact_email | VARCHAR(120) | Yes | | | Primary contact email address. |
| contact_phone | VARCHAR(20) | Yes | | | Contact phone number. |
| address | TEXT | Yes | | | Full mailing address. |

---

## 3. Factories

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| factory_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a production facility. |
| manufacturer_id | INT UNSIGNED | No | FK `fk_factory_mfr` | ON DELETE RESTRICT, ON UPDATE CASCADE | The company that owns this factory. |
| factory_name | VARCHAR(120) | No | | | Name of the factory or plant. |
| location | VARCHAR(200) | Yes | | | City/state/country of the factory. |
| license_no | VARCHAR(60) | Yes | | | Factory-level manufacturing licence number. |

---

## 4. Users

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| user_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a staff user. |
| full_name | VARCHAR(120) | No | | | Display name for the user. |
| email | VARCHAR(120) | No | UQ `uq_users_email` | | Login email address (must be unique). |
| password_hash | VARCHAR(255) | No | | | bcrypt hash produced by PHP `password_hash()`. Never a plaintext password. |
| role_id | TINYINT UNSIGNED | No | FK `fk_users_role` | ON DELETE RESTRICT, ON UPDATE CASCADE | Links to Roles: determines Admin/Regulator or Manufacturer access. |
| manufacturer_id | INT UNSIGNED | Yes | FK `fk_users_mfr` | ON DELETE RESTRICT, ON UPDATE CASCADE | NULL for Admin/Regulator; set for Manufacturer users. Enforced by `trg_users_bi/bu`. |
| is_active | TINYINT(1) | No | | DEFAULT 1 | Soft-delete flag: 0 = deactivated, 1 = active. Users are deactivated, never deleted. |
| created_at | DATETIME | No | | DEFAULT CURRENT_TIMESTAMP | When the account was created. |

---

## 5. Suppliers

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| supplier_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a raw material supplier. |
| supplier_name | VARCHAR(120) | No | | | Trading name of the supplier company. |
| contact_email | VARCHAR(120) | Yes | | | Supplier contact email. |
| contact_phone | VARCHAR(20) | Yes | | | Supplier contact phone. |
| address | TEXT | Yes | | | Supplier mailing address. |

---

## 6. Ingredients

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| ingredient_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a raw material / active pharmaceutical ingredient. |
| ingredient_name | VARCHAR(120) | No | UQ `uq_ingredient_name` | | INN or IUPAC name of the substance (must be unique per substance). |
| cas_number | VARCHAR(30) | Yes | | | Chemical Abstracts Service registry number (optional). |

---

## 7. Material_Deliveries

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| delivery_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for an inbound delivery event. |
| supplier_id | INT UNSIGNED | No | FK `fk_delivery_supplier` | ON DELETE RESTRICT, ON UPDATE CASCADE | The supplier who delivered this material. |
| ingredient_id | INT UNSIGNED | No | FK `fk_delivery_ingredient` | ON DELETE RESTRICT, ON UPDATE CASCADE | The raw material delivered. |
| manufacturer_id | INT UNSIGNED | No | FK `fk_delivery_mfr` | ON DELETE RESTRICT, ON UPDATE CASCADE | The manufacturer who received the delivery. |
| quantity_kg | DECIMAL(10,3) | No | | CK `chk_delivery_qty` (>0) | Net weight of the delivery in kilograms. |
| received_date | DATE | No | | | Date the delivery was accepted at the factory. |
| certificate_number | VARCHAR(60) | Yes | | Uniqueness enforced by `sp_record_delivery` only | Certificate of Analysis (CoA) document number. |

---

## 8. Medicines

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| medicine_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a branded medicine product. |
| brand_name | VARCHAR(160) | No | UQ `uq_medicine_brand` (with manufacturer_id) | | Registered brand name of the product. |
| manufacturer_id | INT UNSIGNED | No | FK `fk_medicine_mfr` | ON DELETE RESTRICT, ON UPDATE CASCADE | The manufacturer who owns this brand. |
| dosage_form | VARCHAR(60) | No | | | Pharmaceutical form: Tablet, Syrup, Injection, etc. |
| pack_size | VARCHAR(80) | Yes | | | Packaging description, e.g. "Strip of 10 tablets". |
| therapeutic_class | VARCHAR(80) | Yes | | | ATC therapeutic classification, e.g. "ANTI INFECTIVES". |
| habit_forming | TINYINT(1) | No | | DEFAULT 0 | 1 if the medicine is classified as habit-forming / controlled. |
| storage_note | TEXT | Yes | | | Storage instructions shown to the consumer. |
| source_note | TEXT | Yes | | | Internal data provenance note. |

---

## 9. Drug_Formulations

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| medicine_id | INT UNSIGNED | No | PK, FK `fk_df_medicine` | ON DELETE CASCADE, ON UPDATE CASCADE | The medicine this formulation row belongs to. |
| ingredient_id | INT UNSIGNED | No | PK, FK `fk_df_ingredient` | ON DELETE RESTRICT, ON UPDATE CASCADE | The active ingredient in this formulation. |
| strength | VARCHAR(30) | No | | | Concentration/strength label, e.g. "500mg", "5mg/5ml". |
| is_active | TINYINT(1) | No | | DEFAULT 1 | 1 = active ingredient; 0 = inactive/excipient. |

---

## 10. Medicine_Info

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| info_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for one information row. |
| medicine_id | INT UNSIGNED | No | FK `fk_info_medicine` | ON DELETE CASCADE, ON UPDATE CASCADE | The medicine this info item belongs to. |
| info_type | ENUM('use','side_effect','avoid_with') | No | | | Category of information. |
| info_text | TEXT | No | | | The information text shown to consumers at scan time. |

---

## 11. Production_Batches

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| batch_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a production batch. |
| batch_number | VARCHAR(40) | No | UQ `uq_batch_number` | | Human-readable batch identifier, e.g. "BT-2026-001". |
| medicine_id | INT UNSIGNED | No | FK `fk_batch_medicine` | ON DELETE RESTRICT, ON UPDATE CASCADE | The medicine produced in this batch. |
| factory_id | INT UNSIGNED | No | FK `fk_batch_factory` | ON DELETE RESTRICT, ON UPDATE CASCADE | The factory where this batch was produced. |
| quantity_units | INT UNSIGNED | No | | CK `chk_batch_qty` (>0) | Number of packs/units produced. |
| manufacture_date | DATE | No | | | Date of manufacture. |
| expiry_date | DATE | No | | CK `chk_batch_dates` (expiry>mfg) | Expiry date; must be after manufacture_date. |
| status | ENUM('Pending','Approved','Rejected','Recalled') | No | | DEFAULT 'Pending' | Current lifecycle state. State transitions are enforced by `trg_batches_bu`. |

---

## 12. Batch_Materials

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| batch_id | INT UNSIGNED | No | PK, FK `fk_bm_batch` | ON DELETE CASCADE, ON UPDATE CASCADE | The batch that consumed this material. |
| delivery_id | INT UNSIGNED | No | PK, FK `fk_bm_delivery` | ON DELETE RESTRICT, ON UPDATE CASCADE | The delivery from which the material was drawn. |
| quantity_used_kg | DECIMAL(10,3) | No | | CK `chk_bm_qty` (>0) | Mass consumed from this delivery for this batch. Total must not exceed delivery quantity (enforced by `trg_batch_materials_bi`). |

---

## 13. Quality_Test_Reports

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| report_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for one QA test report. |
| batch_id | INT UNSIGNED | No | FK `fk_qtr_batch` | ON DELETE CASCADE, ON UPDATE CASCADE | The batch that was tested. |
| tested_by | INT UNSIGNED | No | FK `fk_qtr_user` | ON DELETE RESTRICT, ON UPDATE CASCADE | The user (staff member) who recorded the test. |
| test_date | DATE | No | | | Date the test was performed. |
| purity_pct | DECIMAL(5,2) | Yes | | CK `chk_purity` (0-100 or NULL) | Active ingredient purity percentage. |
| dissolution_pct | DECIMAL(5,2) | Yes | | CK `chk_dissolution` (0-100 or NULL) | Dissolution test result percentage. |
| weight_variation_pct | DECIMAL(5,2) | Yes | | CK `chk_weight_var` (0-100 or NULL) | Weight variation test result percentage. |
| result | ENUM('Pass','Fail') | No | | | Overall test outcome. |
| remarks | TEXT | Yes | | | Lab technician notes. |

---

## 14. QR_Codes

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| qr_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a QR code record. |
| code | VARCHAR(64) | No | UQ `uq_qr_code` | | The unique QR code string, e.g. "PT360-ABCDEF123456". Generated by `sp_approve_batch`. |
| batch_id | INT UNSIGNED | No | FK `fk_qr_batch` | ON DELETE RESTRICT, ON UPDATE CASCADE | The approved batch this QR code belongs to. |
| issued_at | DATETIME | No | | DEFAULT CURRENT_TIMESTAMP | When the QR code was generated. |

---

## 15. Scan_Log

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| scan_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a scan event. |
| scanned_code | VARCHAR(64) | No | Indexed (idx_scan_code_time) | | The raw code string that was scanned. Stored even for unknown codes. |
| qr_id | INT UNSIGNED | Yes | FK `fk_scan_qr` | ON DELETE SET NULL, ON UPDATE CASCADE | Resolved QR code record. NULL if the code was not found. |
| scanned_at | DATETIME | No | Indexed (idx_scan_code_time, idx_scan_at) | DEFAULT CURRENT_TIMESTAMP | Timestamp of the scan. |
| verdict | ENUM('Genuine','Expired','Recalled','Not approved','Suspicious') | No | | | Snapshot of `fn_qr_verdict()` at scan time. Denormalised — may diverge from current status. |

---

## 16. Product_Recalls

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| recall_id | INT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for a recall event. |
| batch_id | INT UNSIGNED | No | UQ `uq_recall_batch`, FK `fk_recall_batch` | ON DELETE RESTRICT, ON UPDATE CASCADE | The recalled batch (one recall per batch maximum). |
| reason | TEXT | No | | | Official reason for the recall. |
| recall_date | DATE | No | | | Date the recall was issued. |
| issued_by | INT UNSIGNED | No | FK `fk_recall_user` | ON DELETE RESTRICT, ON UPDATE CASCADE | The Admin/Regulator user who issued the recall. |

---

## 17. Audit_Logs

| Column | Data Type | Nullable | Key | Constraint | Meaning |
|---|---|---|---|---|---|
| log_id | BIGINT UNSIGNED | No | PK, AUTO_INCREMENT | | Surrogate key for an audit entry (BIGINT for long-lived logs). |
| user_id | INT UNSIGNED | Yes | FK `fk_audit_user` | ON DELETE RESTRICT, ON UPDATE CASCADE | Acting user; NULL for system-generated events. |
| action | VARCHAR(60) | No | | | Event code, e.g. `LOGIN`, `STATUS_APPROVED`, `INSERT_RECALL`. |
| table_name | VARCHAR(60) | No | | | Name of the affected database table. |
| record_id | INT UNSIGNED | Yes | | | Primary key of the affected row (nullable for login events). |
| details | TEXT | Yes | | | Human-readable description of the event. |
| logged_at | DATETIME | No | | DEFAULT CURRENT_TIMESTAMP | When the event occurred. Append-only: UPDATE/DELETE blocked by `trg_audit_logs_bu/bd`. |
