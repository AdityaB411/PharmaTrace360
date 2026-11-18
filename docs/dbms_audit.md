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

**Is there an index on Quality_Test_Reports(batch_id, test_date, report_id)? Yes**

Composite index `idx_qtr_batch_latest (batch_id, test_date, report_id)` is defined in
`db/01_schema.sql` (and applied idempotently in `db/09_upgrade_existing.sql`), directly
supporting the `ORDER BY test_date DESC, report_id DESC LIMIT 1` lookup in `trg_batches_bu`
and `sp_reject_batch`.

---

## D. Unique Key Preventing Duplicate Medicine_Info Rows

**Is there a unique key preventing duplicate Medicine_Info rows? Yes**

`UNIQUE KEY uq_medicine_info_item (medicine_id, info_type, info_text(200))` in
`db/01_schema.sql` (and `db/09_upgrade_existing.sql`) prevents duplicate uses, side effects,
and drug-interaction entries per medicine while also indexing `WHERE medicine_id = ? AND info_type = ?`
lookups in `sp_verify_scan`.

---

## E. Charset and Collation of QR_Codes.code and Scan_Log.scanned_code

**Rating: Yes (documented design choice)**

The database uses `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`. `QR_Codes.code` and
`Scan_Log.scanned_code` inherit `utf8mb4_unicode_ci`, which is **intentional** so consumers
manually typing a QR code in lowercase still match uppercase issued codes (`PT360-...`) and
mixed-case visually confusable duplicates are rejected by `uq_qr_code`.

---

## F. Routines and Views Using SQL SECURITY DEFINER or INVOKER

**Rating: Yes (intentional `DEFINER` least-privilege model)**

MySQL defaults views, functions, and stored procedures to `SQL SECURITY DEFINER`. Because
`pt_public`, `pt_app`, and `pt_setup` intentionally have **zero direct base-table grants**,
`DEFINER` execution is required so callers can access only the vetted procedures and views
without exposing underlying tables.

---

## G. Routines That Lock Rows with FOR UPDATE

**Rating: Yes — five write procedures use FOR UPDATE inside transactions**

| Procedure | Row(s) Locked | Purpose |
|---|---|---|
| `sp_record_test` | `Production_Batches` | Serializes QA test submission and permission check on the batch |
| `sp_approve_batch` | `Production_Batches` | Prevents concurrent approval / duplicate QR issuance |
| `sp_reject_batch` | `Production_Batches` | Prevents race between reject and approve |
| `sp_issue_recall` | `Production_Batches` | Serializes recall creation and status flip |
| `sp_add_batch_material` | `Production_Batches` + `Material_Deliveries` | Prevents concurrent over-consumption of shared delivery stock |

All `fn_user_can_manage_batch` checks now run **inside** `START TRANSACTION` after acquiring
the `FOR UPDATE` row lock, closing the TOCTOU window.

---

## H. Is Audit_Logs Protected Against UPDATE and DELETE?

**Yes**

| Trigger | Event | Action |
|---|---|---|
| `trg_audit_logs_bu` | BEFORE UPDATE on Audit_Logs | SIGNAL '45000' "Audit log is append-only." |
| `trg_audit_logs_bd` | BEFORE DELETE on Audit_Logs | SIGNAL '45000' "Audit log is append-only." |

> **Limitation:** A user with `SUPER` privilege can drop the triggers. True tamper-evidence
> requires binary log immutability or an out-of-band audit sink.

---

## I. Can a Delivery Be Over-Used, or Received After the Batch Was Made?

**Rating: No (blocked by trigger + delivery-row `FOR UPDATE` lock)**

- **Over-use:** `sp_add_batch_material` locks the `Material_Deliveries` row (`FOR UPDATE`)
  before inserting, and `trg_batch_materials_bi` sums existing `quantity_used_kg` and raises
  `SIGNAL SQLSTATE '45000'` if `(total_used + NEW.quantity_used_kg) > quantity_kg`.
- **Received after manufacture:** `trg_batch_materials_bi` rejects any delivery where
  `received_date > manufacture_date`.

---

## J. ON DELETE CASCADE Relationships (Do Not Fire Triggers)

**Only two intentional master-data CASCADE paths remain:**

| Parent Table | Child Table | Constraint | Effect |
|---|---|---|---|
| Medicines | Drug_Formulations | `fk_df_medicine` | Deleting a Medicine removes its formulation rows |
| Medicines | Medicine_Info | `fk_info_medicine` | Deleting a Medicine removes its public info rows |

Both operational history constraints — `fk_bm_batch` (`Batch_Materials`) and `fk_qtr_batch`
(`Quality_Test_Reports`) — now enforce **`ON DELETE RESTRICT`** so batch traceability and
QA history cannot be silently deleted.

---

## K. Columns That Store Derived Data

| Column | Table | Derivation |
|---|---|---|
| `verdict` | Scan_Log | Snapshot of `fn_qr_verdict()` at scan time — intentional forensic record |
| `remaining_kg` | v_my_deliveries (view) | Computed: `quantity_kg - SUM(quantity_used_kg)` — not stored |
| `qr_count` | v_batch_overview (view) | Computed: `COUNT(qr.qr_id)` — not stored |

`Scan_Log.verdict` preserves what the consumer actually saw at scan time (e.g., `Genuine`)
even if the batch is later recalled.

---

## Prioritised Audit Resolution Summary

| Status | Item | Notes |
|---|---|---|
| **Done** | Composite index `(batch_id, test_date, report_id)` on `Quality_Test_Reports` | Added in `01_schema.sql` & `09_upgrade_existing.sql`. |
| **Done** | Unique index `(medicine_id, info_type, info_text(200))` on `Medicine_Info` | Prevents duplicate info rows and speeds up `sp_verify_scan`. |
| **Done** | Additional query-backed indexes (`uq_supplier_name`, `idx_batches_status_expiry`, `idx_scan_verdict`, `idx_audit_logged_at`, `idx_audit_table_record`) | Optimizes dashboard KPIs, timelines, recent audit, and supplier lookups. |
| **Done** | Lock batch + delivery rows (`FOR UPDATE`) before ownership/inventory checks | Closes TOCTOU windows in batch and material-link procedures. |
| **Done** | Replace `ON DELETE CASCADE` on `fk_bm_batch` and `fk_qtr_batch` with `ON DELETE RESTRICT` | Preserves QA and supply-chain traceability records. |
| **Done** | Add `UNIQUE (certificate_number)` on `Material_Deliveries` | Enforced at schema level, not only in `sp_record_delivery`. |
| **Intentional** | `SQL SECURITY DEFINER` on views/routines | Required for least-privilege (`pt_public`/`pt_app` have zero base-table grants). |
| **Intentional** | Case-insensitive `utf8mb4_unicode_ci` on QR codes | Allows case-insensitive manual entry while blocking mixed-case duplicates. |
| **Domain decision** | Multiple deliveries of the same ingredient per batch | Permitted by PK `(batch_id, delivery_id)` so a batch can draw from two CoA lots of the same API. |
