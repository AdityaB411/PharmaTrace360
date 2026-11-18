# PharmaTrace 360 — Logic Overview

> **Audience:** Beginners (2nd-year B.Tech DBMS students).
> This document explains every view, function, trigger and procedure in
> `db/03_logic.sql` and shows which DBMS concept each one demonstrates.

---

## Views

A **view** is a saved `SELECT` query. It behaves like a virtual table — no
data is stored separately; MySQL runs the underlying query each time you
`SELECT * FROM the_view`.

### v_batch_overview

| What it shows | One row per batch: batch number, medicine name, manufacturer, factory, status, manufacture/expiry dates, and how many QR codes were issued. |
|---|---|
| **Key concept** | **Multi-table JOINs** (4 tables) and **LEFT JOIN** (to include batches with zero QR codes). **GROUP BY** with **COUNT** aggregate. |
| **Why it exists** | Gives the admin a quick summary without writing a long JOIN every time. |

### v_batch_traceability

| What it shows | Every batch linked to its raw materials, the supplier who delivered each material, and the Certificate of Analysis number. |
|---|---|
| **Key concept** | **Five-table JOIN**, including resolution of the **many-to-many** relationship between batches and deliveries through the `Batch_Materials` junction table. |
| **Why it exists** | Full supply-chain trace — essential for recall investigations. |

### v_suspicious_codes

| What it shows | QR codes scanned **more than 10 times in the rolling 48-hour window**, with the recent scan count and first/last timestamps in that window. |
|---|---|
| **Key concept** | Time-window filtering, **GROUP BY** with **HAVING**, and **MIN/MAX** aggregates. |
| **Why it exists** | High-frequency scans may indicate a copied code. Analyst review status is separate from the public verification verdict. |

### v_dashboard

| What it shows | **One row** with four numbers: approved batches, failed tests, suspicious scans, and active recalls. |
|---|---|
| **Key concept** | **Scalar subqueries** — each column is an independent `SELECT COUNT(*)`. |
| **Why it exists** | Powers the admin dashboard's KPI cards. |

### v_batch_status_counts

| What it shows | One row per status (`Pending`, `Approved`, `Rejected`, `Recalled`) with the count of batches in that status. |
|---|---|
| **Key concept** | **GROUP BY** aggregate. |
| **Why it exists** | Feeds the dashboard's status bar/pie chart. |

### v_demo_codes

| What it shows | One sample code each for `Genuine` (Approved, unexpired), `Expired` (Approved, past expiry), and `Recalled` batches. |
|---|---|
| **Key concept** | **UNION ALL** of bounded subqueries (`LIMIT 1`). |
| **Why it exists** | Powers sample buttons on the public verification portal without hardcoding or raw table access. |

### v_batch_tests

| What it shows | Quality test history for batches: batch number, test date, purity (%), dissolution (%), weight variation (%), result (`Pass`/`Fail`), and lab remarks. |
|---|---|
| **Key concept** | Two-table **INNER JOIN** between `Production_Batches` and `Quality_Test_Reports`. |
| **Why it exists** | Supplies the batch detail inspection page without granting direct SELECT on `Quality_Test_Reports`. |

### v_recent_audit

| What it shows | The 20 most recent immutable audit log records with user display names, action codes, affected tables, and details. |
|---|---|
| **Key concept** | **LEFT JOIN** with `Users`, **ORDER BY** timestamp/ID descending, and **LIMIT 20**. |
| **Why it exists** | Feeds the administrator audit trail dashboard. |

### v_batch_qr_codes

| What it shows | QR codes issued per batch with total scan count and last scan timestamp. |
|---|---|
| **Key concept** | LEFT JOIN with Scan_Log, GROUP BY aggregate. |
| **Why it exists** | Supplies QR code list on the batch detail page, filtered by manufacturer_id. |

### v_form_suppliers, v_form_ingredients, v_form_medicines, v_form_factories

| What they show | Sorted name lists for form dropdowns (suppliers, ingredients, medicines by manufacturer, factories by manufacturer). |
|---|---|
| **Key concept** | Simple ORDER BY views providing data for SELECT form elements. |
| **Why they exist** | Separate views for each entity type allow the application to populate dropdowns with one clean SELECT, filtered by manufacturer where needed. |

### v_my_deliveries

| What it shows | Delivery inventory per manufacturer with `quantity_kg`, `used_kg` (sum of Batch_Materials), and computed `remaining_kg`. |
|---|---|
| **Key concept** | LEFT JOIN + GROUP BY aggregate + computed column (remaining_kg = quantity_kg - used_kg). |
| **Why it exists** | Gives a live balance view of raw material inventory for the deliveries page. |

### v_batch_timeline

| What it shows | A chronological event log for each batch: manufactured, material received, material linked, QA test, QR codes issued, status changes, and recalls. |
|---|---|
| **Key concept** | **UNION ALL** of 7 subqueries, each representing one event type. |
| **Why it exists** | Powers the Batch Lifecycle History vertical timeline on the batch detail page. |

### v_recall_list

| What it shows | Summary of all product recalls with batch, medicine, manufacturer, contact, QR count, total scans, and post-recall scans. |
|---|---|
| **Key concept** | Multi-table JOIN with correlated scalar subqueries for per-recall scan counts. |
| **Why it exists** | Powers the Recall Monitor page (`/app/recalls.php`) for Admin/Regulator users. |

---

## Functions

A **function** takes parameters, executes SQL, and returns a single value.
All functions are declared `READS SQL DATA` because they only read tables
and never modify any data.

### fn_recent_scan_count(p_code, p_hours)

| What it does | Returns the number of times a particular code was scanned in the last `p_hours` hours. |
|---|---|
| **Key concept** | **Scalar function**, **date arithmetic** (`NOW() - INTERVAL`). |
| **Used by** | `fn_qr_verdict` — to detect suspiciously frequent scans. |

### fn_qr_verdict(p_code)

| What it does | Evaluates a scanned code and returns one of: `Genuine`, `Expired`, `Recalled`, `Not approved`, `Suspicious`. |
|---|---|
| **Check order** | 1. Unknown code → Suspicious · 2. Recalled batch → Recalled · 3. Not Approved → Not approved · 4. Past expiry → Expired · 5. >10 scans in 48 h → Suspicious · 6. Otherwise → Genuine |
| **Key concept** | **Control flow** (`IF` / `RETURN`), **function composition** (calls `fn_recent_scan_count`). |
| **Threshold** | 10 scans in 48 hours (configurable — see comment in the function body). |

### fn_user_can_manage_batch(p_user_id, p_batch_number)

| What it does | Returns `1` if and only if the user is active, holds the `Manufacturer` role, and their `manufacturer_id` matches the manufacturer that owns the batch's factory; otherwise returns `0`. |
|---|---|
| **Key concept** | **Multi-table permission lookup**, cross-table integrity check, boolean return (`TINYINT`). |
| **Used by** | `sp_record_test`, `sp_approve_batch`, and `sp_reject_batch` to enforce multi-tenant isolation at the database layer. |

---

## Triggers

A **trigger** is code that MySQL runs automatically **before** or **after**
an `INSERT` or `UPDATE`. Triggers enforce business rules that plain `CHECK`
constraints cannot express.

All validation triggers use `SIGNAL SQLSTATE '45000'` to raise a clear error
message if the rule is violated.

### trg_users_bi / trg_users_bu — Users BEFORE INSERT / UPDATE

| Rule | Manufacturer role → `manufacturer_id` must NOT be NULL. Admin/Regulator → `manufacturer_id` must be NULL. |
|---|---|
| **Key concept** | **BEFORE trigger**, **SIGNAL** for custom error messages. |

### trg_batch_materials_bi — Batch_Materials BEFORE INSERT

| Rule 1 | The delivery's manufacturer must own the batch's factory. |
| Rule 2 | The delivery's ingredient must be part of the batch's medicine formulation (`Drug_Formulations`). |
|---|---|
| **Key concept** | **Cross-table validation** inside a trigger — verifies data integrity across 3 tables. |

### trg_qr_codes_bi — QR_Codes BEFORE INSERT

| Rule | Only `Approved` batches may receive QR codes. |
|---|---|
| **Key concept** | **Status-gated insertion** — prevents QR generation for batches that haven't passed QA. |

### trg_batches_bu — Production_Batches BEFORE UPDATE

| Rule A | Setting status to `Approved` requires the most recent `Quality_Test_Reports` row (by `test_date DESC, report_id DESC`) to have result = `Pass`. |
| Rule B | Setting status to `Recalled` requires a `Product_Recalls` row for the batch. |
| Rule C | If `OLD.status = 'Recalled'` and `NEW.status` is different, an error is signaled ("A recalled batch cannot change status"). |
|---|---|
| **Key concept** | **Multi-rule BEFORE UPDATE trigger**, immutable state enforcement, **ORDER BY + LIMIT 1** to find the latest test. |

### trg_batches_au — Production_Batches AFTER UPDATE

| What it does | Writes an `Audit_Logs` entry whenever a batch's status changes. |
|---|---|
| **Key concept** | **AFTER trigger for audit logging**, session variable `@app_user_id`. |

### trg_recalls_ai — Product_Recalls AFTER INSERT

| What it does | Writes an `Audit_Logs` entry whenever a new recall is created. |
|---|---|
| **Key concept** | **Automatic audit trail** — no procedure needs to manually insert the log. |

### trg_qtr_ai — Quality_Test_Reports AFTER INSERT

| What it does | Writes an `Audit_Logs` entry whenever a new QA test is recorded. |
|---|---|
| **Key concept** | **Event-driven logging** — captures every test regardless of which code path inserted it. |

> **Design decision:** All audit entries are written by AFTER triggers, never
> by procedures. This means the audit trail is guaranteed even if someone
> inserts rows directly in the mysql prompt.

### trg_deliveries_ai — Material_Deliveries AFTER INSERT

| What it does | Writes an `Audit_Logs` entry (`DELIVERY_RECORDED`) whenever a new material delivery is recorded. |
|---|---|
| **Key concept** | **AFTER INSERT trigger** — captures every delivery regardless of whether it was inserted via `sp_record_delivery` or directly. |

### trg_batches_ai — Production_Batches AFTER INSERT

| What it does | Writes a `BATCH_CREATED` audit entry whenever a new batch row is created. |
|---|---|
| **Key concept** | AFTER INSERT on the most central table in the schema, ensuring the batch lifecycle always has a creation event. |

### trg_batch_materials_bu / trg_batch_materials_bd — Batch_Materials BEFORE UPDATE / DELETE

| Rule | Blocks modifications and deletions on Batch_Materials rows unless the batch is `Pending`. |
|---|---|
| **Key concept** | **Immutable linkage** after batch approval: prevents post-approval alteration of the material traceability record. |

### trg_batch_materials_ai — Batch_Materials AFTER INSERT

| What it does | Writes a `MATERIAL_LINKED` audit entry whenever a raw material is linked to a batch. |
|---|---|
| **Key concept** | Automatically creates a supply-chain audit trail entry at the database layer. |

### trg_audit_logs_bu / trg_audit_logs_bd — Audit_Logs BEFORE UPDATE / DELETE

| Rule | Unconditionally signals error `'45000'` with message "Audit log is append-only." |
|---|---|
| **Key concept** | **Append-only enforcement** — Audit_Logs can only be grown, never altered or shrunk, regardless of what MySQL user executes the statement. |

---

## Stored Procedures

A **stored procedure** is a named block of SQL that you call with `CALL`.
Procedures can contain variables, loops, transactions and multiple result
sets.

### sp_verify_scan(p_code)

| What it does | Computes the verdict using `fn_qr_verdict`, logs the scan in `Scan_Log`, and returns the public-facing result. |
|---|---|
| **Returns** | Up to 4 result sets: ① main info (verdict, medicine, strength, ingredient, manufacturer, batch, dates, storage note, advisory) · ② uses · ③ side effects · ④ "avoid taking together with". For unknown codes, only the verdict is returned. |
| **Never exposes** | Supplier names, QA test values, or batch costs. |
| **Key concept** | **Stored procedure**, **multiple result sets**, **function call inside a procedure**. |

### sp_record_test(p_batch_number, p_user_id, p_purity, p_dissolution, p_weight_variation, p_result, p_remarks)

| What it does | Inserts a QA test report for a `Pending` batch. Requires `fn_user_can_manage_batch = 1`. Sets `tested_by = p_user_id` and `test_date = CURDATE()`. |
|---|---|
| **Key concept** | Permission-gated insertion, status validation, session-variable audit propagation (`@app_user_id`). |

### sp_approve_batch(p_batch_number, p_user_id, p_pack_count)

| What it does | In one atomic **TRANSACTION**: verifies `fn_user_can_manage_batch = 1`, changes batch status to `Approved` (trigger enforces latest test = `Pass`), and creates `p_pack_count` unique serialized QR codes (`PT360-` + 12 hex chars). |
|---|---|
| **On error** | Rolls back and re-raises the error with `SIGNAL`. |
| **Key concept** | **Transactions** (`START TRANSACTION / COMMIT / ROLLBACK`), **error handling** (`DECLARE EXIT HANDLER FOR SQLEXCEPTION`), **UUID/MD5** generation, **WHILE loop**. |

### sp_reject_batch(p_batch_number, p_user_id)

| What it does | In one atomic **TRANSACTION**: verifies `fn_user_can_manage_batch = 1`, ensures the batch is `Pending` and its latest test is `Fail`, then changes status to `Rejected`. |
|---|---|
| **On error** | Rolls back and re-raises the error with `SIGNAL`. |
| **Key concept** | Rule validation before state transition, atomic transaction rollback. |

### sp_issue_recall(p_batch_number, p_reason, p_user_id)

| What it does | In one atomic **TRANSACTION**: verifies user is an active `Admin/Regulator`, inserts a `Product_Recalls` row, updates batch status to `Recalled`, and returns the **recall impact report** (batch, medicine, supplier, certificate, QR count, total scans). |
|---|---|
| **On error** | Rolls back and re-raises the error. |
| **Key concept** | **Transactions**, **role verification**, **multi-table JOIN impact report**. |

### sp_log_event(p_user_id, p_action, p_details)

| What it does | Inserts an application-level security event into `Audit_Logs` (e.g., `LOGIN`, `LOGOUT`, `LOGIN_FAILED`). Passwords are never logged. |
|---|---|
| **Key concept** | Stored procedure encapsulating append-only security auditing. |

### sp_login_lookup(p_email)

| What it does | Looks up active credentials for authentication: returns `user_id`, `email`, `password_hash`, `role_name`, `manufacturer_id`, and `is_active`. |
|---|---|
| **Key concept** | Single-row lookup with exact least-privilege projection. |

### sp_set_password(p_email, p_hash)

| What it does | Updates `Users.password_hash` for a given email. Intended strictly for the offline administrative CLI tool (`web/tools/set_password.php`). |
|---|---|
| **Key concept** | Encapsulated credential updates via stored procedure. |

### sp_record_delivery(p_user_id, p_supplier_name, p_ingredient_name, p_quantity_kg, p_received_date, p_certificate_number)

| What it does | Validates user is an active Manufacturer, checks quantity > 0, received_date <= today, certificate is non-empty and unique, and that supplier and ingredient exist. Inserts into `Material_Deliveries`. |
|---|---|
| **Key concept** | **Full input validation** before INSERT, **TRANSACTION**, **audit propagation** via `@app_user_id`. |

### sp_create_batch(p_user_id, p_batch_number, p_medicine_name, p_factory_name, p_quantity, p_manufacture_date, p_expiry_date)

| What it does | Validates user is active Manufacturer, medicine and factory belong to their company, batch number is unique, manufacture_date not in future, expiry_date > manufacture_date, quantity > 0. Creates a `Pending` batch. |
|---|---|
| **Key concept** | **Multi-step validation** followed by a single INSERT in a transaction. `trg_batches_ai` auto-logs the creation. |

### sp_add_batch_material(p_user_id, p_batch_number, p_certificate_number, p_quantity_used_kg)

| What it does | Validates `fn_user_can_manage_batch = 1`, locates the delivery by certificate number, locks the batch row `FOR UPDATE`, verifies batch is `Pending`, then inserts into `Batch_Materials`. The `trg_batch_materials_bi` trigger enforces over-use and date rules. |
|---|---|
| **Key concept** | **Procedure + trigger co-operation**: procedure handles permission and locking; trigger handles quantity and date integrity. |

### sp_change_password(p_user_id, p_new_hash)

| What it does | Verifies user exists, validates hash length >= 60 chars (bcrypt), updates `Users.password_hash`, and writes a `PASSWORD_CHANGED` entry to `Audit_Logs` — all in one atomic transaction. |
|---|---|
| **Key concept** | **Credential update with mandatory audit trail** — the INSERT to Audit_Logs and the UPDATE to Users are atomic. |

---

## Roles and Permissions

Permissions are enforced at **two independent layers**:
1. **Database Layer (MySQL):** Least privilege via dedicated users (`pt_public`, `pt_app`), stored procedures, and MySQL `GRANT` statements. Users have zero direct access to underlying tables.
2. **Web Application Layer (PHP):** Session authentication, role guards (`requireRole()`), 30-minute idle timeouts, and per-form CSRF verification tokens.

| Role | MySQL User | Database Permissions | Web Capabilities & Enforcement |
|---|---|---|---|
| **Public Visitor** | `pt_public` | `EXECUTE` on `sp_verify_scan`<br>`SELECT` on `v_demo_codes` | Anonymous access to `index.php`. Can scan QR codes and view consumer drug information. No login credentials exist. |
| **Manufacturer** | `pt_app` | `EXECUTE` on `sp_record_test`, `sp_approve_batch`, `sp_reject_batch`<br>`SELECT` on views (`v_batch_overview`, `v_batch_traceability`, `v_batch_tests`) | Authenticates via `login.php`. Accesses `/app/batches.php` and `/app/batch_detail.php`. Filtered strictly to their company's batches (`fn_user_can_manage_batch` prevents cross-tenant actions). |
| **Admin / Regulator** | `pt_app` | `EXECUTE` on `sp_issue_recall`, `sp_log_event`, `sp_login_lookup`<br>`SELECT` on views (`v_dashboard`, `v_batch_status_counts`, `v_batch_overview`, `v_suspicious_codes`, `v_recent_audit`) | Authenticates via `login.php`. Accesses executive dashboard, system-wide batches, suspicious scan alerts, recent audit log, and emergency batch recalls. |

---

## DBMS Concepts Demonstrated

| Concept | Where it appears |
|---|---|
| **Views (16)** | `v_batch_overview`, `v_batch_traceability`, `v_suspicious_codes`, `v_dashboard`, `v_batch_status_counts`, `v_demo_codes`, `v_batch_tests`, `v_recent_audit`, `v_batch_qr_codes`, `v_form_suppliers`, `v_form_ingredients`, `v_form_medicines`, `v_form_factories`, `v_my_deliveries`, `v_batch_timeline`, `v_recall_list` |
| **Functions (3)** | `fn_recent_scan_count`, `fn_qr_verdict`, `fn_user_can_manage_batch` |
| **Stored Procedures (12)** | `sp_verify_scan`, `sp_approve_batch`, `sp_reject_batch`, `sp_record_test`, `sp_issue_recall`, `sp_log_event`, `sp_login_lookup`, `sp_set_password`, `sp_record_delivery`, `sp_create_batch`, `sp_add_batch_material`, `sp_change_password` |
| **Triggers (16)** | `trg_users_bi`, `trg_users_bu`, `trg_batch_materials_bi`, `trg_batch_materials_bu`, `trg_batch_materials_bd`, `trg_qr_codes_bi`, `trg_batches_bi`, `trg_batches_bu`, `trg_batches_au`, `trg_recalls_ai`, `trg_qtr_ai`, `trg_deliveries_ai`, `trg_batches_ai`, `trg_batch_materials_ai`, `trg_audit_logs_bu`, `trg_audit_logs_bd` |
| **Least Privilege / Grants** | Dedicated `pt_public` and `pt_app` MySQL accounts defined in `db/05_grants.sql` |
| **Transactions** | `sp_approve_batch`, `sp_reject_batch`, `sp_issue_recall`, `sp_record_delivery`, `sp_create_batch`, `sp_add_batch_material`, `sp_change_password` (`START TRANSACTION / COMMIT / ROLLBACK`) |
| **Indexing** | `idx_scan_code_time`, `idx_scan_at` on Scan_Log; UNIQUE indexes on `QR_Codes.code`, `Production_Batches.batch_number` |
| **Joins** | INNER JOIN, LEFT JOIN, multi-table (up to 7 tables in v_batch_timeline segments) |
| **Aggregates** | COUNT, MIN, MAX, SUM, COALESCE |
| **GROUP BY + HAVING** | `v_suspicious_codes`, `v_batch_overview`, `v_my_deliveries`, `v_batch_qr_codes` |
| **Subqueries** | `v_dashboard` (scalar), `v_demo_codes` (derived tables), `v_recall_list` (correlated scalars) |
| **Window Functions** | `db/06_queries.sql`: ROW_NUMBER, RANK, running SUM |
| **Error Handling** | `DECLARE EXIT HANDLER FOR SQLEXCEPTION`, `SIGNAL SQLSTATE '45000'` |
| **Audit Logging** | Append-only logging via AFTER triggers (`trg_batches_au`, `trg_recalls_ai`, `trg_qtr_ai`, `trg_deliveries_ai`, `trg_batches_ai`, `trg_batch_materials_ai`) and `sp_log_event` using `@app_user_id` |

