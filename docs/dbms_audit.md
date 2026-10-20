# PharmaTrace 360 — DBMS Audit Report

> **Type:** Read-only audit — no schema changes are applied here.
> **Evidence format:** `[file:line]` references the exact line in the SQL source.
> **Rating scale:** **Yes** / **No** / **Partly**

---

## A. Primary Keys and Foreign Keys

**Every table has a primary key: Yes**

| Table | PK Column(s) | Evidence |
|---|---|---|
| Roles | `role_id` | [01_schema.sql:33] |
| Manufacturers | `manufacturer_id` | [01_schema.sql:48] |
| Factories | `factory_id` | [01_schema.sql:62] |
| Users | `user_id` | [01_schema.sql:84] |
| Suppliers | `supplier_id` | [01_schema.sql:108] |
| Ingredients | `ingredient_id` | [01_schema.sql:120] |
| Material_Deliveries | `delivery_id` | [01_schema.sql:136] |
| Medicines | `medicine_id` | [01_schema.sql:170] |
| Drug_Formulations | `(medicine_id, ingredient_id)` composite | [01_schema.sql:190] |
| Medicine_Info | `info_id` | [01_schema.sql:213] |
| Production_Batches | `batch_id` | [01_schema.sql:236] |
| Batch_Materials | `(batch_id, delivery_id)` composite | [01_schema.sql:261] |
| Quality_Test_Reports | `report_id` | [01_schema.sql:290] |
| QR_Codes | `qr_id` | [01_schema.sql:318] |
| Scan_Log | `scan_id` | [01_schema.sql:340] |
| Product_Recalls | `recall_id` | [01_schema.sql:365] |
| Audit_Logs | `log_id` | [01_schema.sql:386] |

**Foreign Keys with ON DELETE / ON UPDATE rules:**

| Constraint | Child Table | Child Column | Parent Table | Parent Column | ON DELETE | ON UPDATE | Evidence |
|---|---|---|---|---|---|---|---|
| fk_factory_mfr | Factories | manufacturer_id | Manufacturers | manufacturer_id | RESTRICT | CASCADE | [01_schema.sql:63-67] |
| fk_users_role | Users | role_id | Roles | role_id | RESTRICT | CASCADE | [01_schema.sql:86-90] |
| fk_users_mfr | Users | manufacturer_id | Manufacturers | manufacturer_id | RESTRICT | CASCADE | [01_schema.sql:91-95] |
| fk_delivery_supplier | Material_Deliveries | supplier_id | Suppliers | supplier_id | RESTRICT | CASCADE | [01_schema.sql:138-142] |
| fk_delivery_ingredient | Material_Deliveries | ingredient_id | Ingredients | ingredient_id | RESTRICT | CASCADE | [01_schema.sql:143-147] |
| fk_delivery_mfr | Material_Deliveries | manufacturer_id | Manufacturers | manufacturer_id | RESTRICT | CASCADE | [01_schema.sql:148-152] |
| fk_medicine_mfr | Medicines | manufacturer_id | Manufacturers | manufacturer_id | RESTRICT | CASCADE | [01_schema.sql:172-176] |
| fk_df_medicine | Drug_Formulations | medicine_id | Medicines | medicine_id | **CASCADE** | CASCADE | [01_schema.sql:191-195] |
| fk_df_ingredient | Drug_Formulations | ingredient_id | Ingredients | ingredient_id | RESTRICT | CASCADE | [01_schema.sql:196-200] |
| fk_info_medicine | Medicine_Info | medicine_id | Medicines | medicine_id | **CASCADE** | CASCADE | [01_schema.sql:214-218] |
| fk_batch_medicine | Production_Batches | medicine_id | Medicines | medicine_id | RESTRICT | CASCADE | [01_schema.sql:240-244] |
| fk_batch_factory | Production_Batches | factory_id | Factories | factory_id | RESTRICT | CASCADE | [01_schema.sql:245-249] |
| fk_bm_batch | Batch_Materials | batch_id | Production_Batches | batch_id | **CASCADE** | CASCADE | [01_schema.sql:263-267] |
| fk_bm_delivery | Batch_Materials | delivery_id | Material_Deliveries | delivery_id | RESTRICT | CASCADE | [01_schema.sql:268-272] |
| fk_qtr_batch | Quality_Test_Reports | batch_id | Production_Batches | batch_id | **CASCADE** | CASCADE | [01_schema.sql:294-298] |
| fk_qtr_user | Quality_Test_Reports | tested_by | Users | user_id | RESTRICT | CASCADE | [01_schema.sql:299-303] |
| fk_qr_batch | QR_Codes | batch_id | Production_Batches | batch_id | RESTRICT | CASCADE | [01_schema.sql:320-324] |
| fk_scan_qr | Scan_Log | qr_id | QR_Codes | qr_id | **SET NULL** | CASCADE | [01_schema.sql:341-345] |
| fk_recall_batch | Product_Recalls | batch_id | Production_Batches | batch_id | RESTRICT | CASCADE | [01_schema.sql:367-371] |
| fk_recall_user | Product_Recalls | issued_by | Users | user_id | RESTRICT | CASCADE | [01_schema.sql:372-376] |
| fk_audit_user | Audit_Logs | user_id | Users | user_id | RESTRICT | CASCADE | [01_schema.sql:393-397] |

---

## B. UNIQUE and CHECK Constraints

**UNIQUE Constraints:**

| Table | Constraint Name | Column(s) | Evidence |
|---|---|---|---|
| Roles | `uq_roles_name` | `role_name` | [01_schema.sql:34] |
| Manufacturers | `uq_mfr_reg` | `registration_no` | [01_schema.sql:49] |
| Users | `uq_users_email` | `email` | [01_schema.sql:85] |
| Ingredients | `uq_ingredient_name` | `ingredient_name` | [01_schema.sql:121] |
| Medicines | `uq_medicine_brand` | `(brand_name, manufacturer_id)` | [01_schema.sql:171] |
| Production_Batches | `uq_batch_number` | `batch_number` | [01_schema.sql:237] |
| QR_Codes | `uq_qr_code` | `code` | [01_schema.sql:319] |
| Product_Recalls | `uq_recall_batch` | `batch_id` | [01_schema.sql:366] |

**CHECK Constraints:**

| Table | Constraint Name | Expression | Evidence |
|---|---|---|---|
| Material_Deliveries | `chk_delivery_qty` | `quantity_kg > 0` | [01_schema.sql:137] |
| Production_Batches | `chk_batch_qty` | `quantity_units > 0` | [01_schema.sql:238] |
| Production_Batches | `chk_batch_dates` | `expiry_date > manufacture_date` | [01_schema.sql:239] |
| Batch_Materials | `chk_bm_qty` | `quantity_used_kg > 0` | [01_schema.sql:262] |
| Quality_Test_Reports | `chk_purity` | `purity_pct IS NULL OR purity_pct BETWEEN 0 AND 100` | [01_schema.sql:291] |
| Quality_Test_Reports | `chk_dissolution` | `dissolution_pct IS NULL OR dissolution_pct BETWEEN 0 AND 100` | [01_schema.sql:292] |
| Quality_Test_Reports | `chk_weight_var` | `weight_variation_pct IS NULL OR weight_variation_pct BETWEEN 0 AND 100` | [01_schema.sql:293] |

---

## C. Index Supporting "Latest Quality Test per Batch"

**Is there an index on Quality_Test_Reports(batch_id, test_date, report_id)? No**

The query `ORDER BY test_date DESC, report_id DESC LIMIT 1` used in `trg_batches_bu`
[03_logic.sql:512-516] and `sp_reject_batch` [03_logic.sql:1076-1079] has no supporting
composite index. The only index on `Quality_Test_Reports` is the PK (`report_id`).
MySQL must perform a full scan of all test rows for a batch on every approval or rejection.

> **Impact:** Low at current dataset size; becomes significant under load with many test reports.

---

## D. Unique Key Preventing Duplicate Medicine_Info Rows

**Is there a unique key preventing duplicate Medicine_Info rows? No**

`Medicine_Info` has only a PK on `info_id` [01_schema.sql:213]. There is no UNIQUE constraint
on `(medicine_id, info_type, info_text)`. Two identical rows with the same medicine, type, and
text can be inserted without error [01_schema.sql:208-219].

---

## E. Charset and Collation of QR_Codes.code and Scan_Log.scanned_code

**Rating: Partly**

The database is created with `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
[01_schema.sql:18-20]. Neither `QR_Codes.code` (VARCHAR(64)) [01_schema.sql:315] nor
`Scan_Log.scanned_code` (VARCHAR(64)) [01_schema.sql:335] override this at column level.
They therefore inherit `utf8mb4 / utf8mb4_unicode_ci`.

This is correct for multi-byte safety, but `utf8mb4_unicode_ci` is a **case-insensitive**
collation. The UNIQUE index `uq_qr_code` [01_schema.sql:319] will silently treat
`PT360-ABCDEF000001` and `pt360-abcdef000001` as duplicates — intentional but undocumented.

---

## F. Routines and Views Using SQL SECURITY DEFINER or INVOKER

**Rating: No — none explicitly declared**

No `CREATE VIEW`, `CREATE FUNCTION`, or `CREATE PROCEDURE` statement in `03_logic.sql`
contains a `SQL SECURITY` clause. MySQL defaults to `SQL SECURITY DEFINER` for all stored
routines and views when the clause is omitted. Every routine therefore executes with the
privileges of the creator account (typically `root` during setup).

> **Impact:** Callers (`pt_app`, `pt_public`) have no table grants, so the definer default
> enables the intended least-privilege model — but makes the security assumption implicit.

---

## G. Routines That Lock Rows with FOR UPDATE

**Rating: Yes — four procedures use FOR UPDATE**

| Procedure | Statement | Evidence |
|---|---|---|
| `sp_record_test` | `SELECT batch_id, status ... FOR UPDATE` on Production_Batches | [03_logic.sql:916-919] |
| `sp_approve_batch` | `SELECT batch_id, status ... FOR UPDATE` on Production_Batches | [03_logic.sql:991-994] |
| `sp_reject_batch` | `SELECT batch_id, status ... FOR UPDATE` on Production_Batches | [03_logic.sql:1059-1062] |
| `sp_issue_recall` | `SELECT batch_id ... FOR UPDATE` on Production_Batches | [03_logic.sql:1146-1149] |

All four locks are held inside `START TRANSACTION ... COMMIT` blocks. `fn_user_can_manage_batch`
is called **before** the transaction starts in `sp_record_test`, `sp_approve_batch`,
`sp_reject_batch`, and `sp_add_batch_material`, creating a brief TOCTOU window.
[03_logic.sql:908, 980, 1051, 1522]

---

## H. Is Audit_Logs Protected Against UPDATE and DELETE?

**Yes**

| Trigger | Event | Action | Evidence |
|---|---|---|---|
| `trg_audit_logs_bu` | BEFORE UPDATE on Audit_Logs | SIGNAL '45000' "Audit log is append-only." | [03_logic.sql:557-566] |
| `trg_audit_logs_bd` | BEFORE DELETE on Audit_Logs | SIGNAL '45000' "Audit log is append-only." | [03_logic.sql:568-581] |

> **Limitation:** A user with `SUPER` privilege can drop the triggers. True tamper-evidence
> requires binary log immutability or an out-of-band audit sink.

---

## I. Can a Delivery Be Over-Used, or Received After the Batch Was Made?

**Rating: No (both are blocked by trigger)**

**Over-use:** `trg_batch_materials_bi` [03_logic.sql:297-366] sums all existing
`quantity_used_kg` for the delivery and signals an error if
`(total_used + NEW.quantity_used_kg) > delivered quantity_kg` [03_logic.sql:357-364].

**Received after manufacture:** The same trigger checks `v_deliv_date > v_mfg_date` and
signals "Delivery received date cannot be after the batch manufacture date." [03_logic.sql:351-354].

> **Caveat — TOCTOU gap:** The aggregate sum is computed without a delivery-row lock.
> Two concurrent `sp_add_batch_material` calls on the same delivery could both read the same
> aggregate and both pass. The batch-row `FOR UPDATE` lock prevents concurrent approvals on the
> same batch but does not prevent two concurrent material-link calls for the same delivery.

---

## J. ON DELETE CASCADE Relationships (Do Not Fire Triggers)

**Yes — four CASCADE paths exist:**

| Parent Table | Child Table | Constraint | Effect | Evidence |
|---|---|---|---|---|
| Medicines | Drug_Formulations | `fk_df_medicine` | Deleting a Medicine silently deletes all ingredient formulations | [01_schema.sql:191-195] |
| Medicines | Medicine_Info | `fk_info_medicine` | Deleting a Medicine silently deletes all info rows | [01_schema.sql:214-218] |
| Production_Batches | Batch_Materials | `fk_bm_batch` | Deleting a batch silently removes all linked material rows | [01_schema.sql:263-267] |
| Production_Batches | Quality_Test_Reports | `fk_qtr_batch` | Deleting a batch silently removes all QA test reports | [01_schema.sql:294-298] |

> **Risk:** `trg_batch_materials_bd` (which blocks deletes for non-Pending batches) does **not**
> fire when `Production_Batches` itself is deleted via CASCADE. `fk_recall_batch` and `fk_qr_batch`
> both use RESTRICT, so batches with recalls or QR codes are protected — but a Pending batch with
> materials and no QR codes can be deleted, bypassing all triggers.

---

## K. Columns That Store Derived Data

| Column | Table | Derivation | Evidence |
|---|---|---|---|
| `verdict` | Scan_Log | Snapshot of `fn_qr_verdict()` at scan time — may diverge from current batch status | [01_schema.sql:338-339] |
| `remaining_kg` | v_my_deliveries (view) | Computed: `quantity_kg - SUM(quantity_used_kg)` — not stored | [03_logic.sql:1780] |
| `qr_count` | v_batch_overview (view) | Computed: `COUNT(qr.qr_id)` — not stored | [03_logic.sql:37] |

`Scan_Log.verdict` is the most significant: it preserves the verdict at scan time (e.g.,
"Genuine") even if the batch is subsequently recalled — intentional for forensic accuracy.

---

## Prioritised Suggested Fixes

> Recommendations only. **No changes are applied in this file.**

| Priority | Fix | Rationale |
|---|---|---|
| **P1 — High** | Add composite index `(batch_id, test_date, report_id)` on `Quality_Test_Reports` | Eliminates full-batch scan on every approval/rejection in `trg_batches_bu` and `sp_reject_batch`. |
| **P2 — High** | Add UNIQUE constraint `(medicine_id, info_type, info_text(200))` on `Medicine_Info` | Prevents duplicate use/side_effect/avoid_with rows from repeated seed runs or double form submission. |
| **P3 — Medium** | Move `fn_user_can_manage_batch` call inside the transaction, after `FOR UPDATE` | Closes the TOCTOU window in `sp_record_test`, `sp_approve_batch`, `sp_reject_batch`, `sp_add_batch_material`. |
| **P4 — Medium** | Add explicit `SQL SECURITY INVOKER` to `sp_verify_scan` and `v_demo_codes` | Makes the security model explicit; prevents privilege escalation if the definer gains broader rights. |
| **P5 — Medium** | Change `QR_Codes.code` and `Scan_Log.scanned_code` collation to `utf8mb4_bin` | Enforces exact-byte case-sensitive uniqueness on QR code strings. |
| **P6 — Low** | Replace `ON DELETE CASCADE` on `fk_bm_batch` and `fk_qtr_batch` with `ON DELETE RESTRICT` | Prevents silent loss of traceability data when a batch is deleted. |
| **P7 — Low** | Add UNIQUE constraint on `Material_Deliveries.certificate_number` | Certificate uniqueness is currently enforced only in `sp_record_delivery`; a direct INSERT bypasses it. |
| **P8 — Low** | Add `UNIQUE (batch_id, ingredient_id)` to `Batch_Materials` | Prevents linking the same ingredient twice from different deliveries for the same batch. |
