# PharmaTrace 360 — Project Context & Rules

> **This file is the single source of truth for every task in this project.**
> Read it before writing any code, SQL, or documentation.

---

## Project Overview

**PROJECT:** PharmaTrace 360 – Smart Pharmaceutical Manufacturing, Quality
Assurance & Drug Authentication System.

**Course:** 2nd-Year B.Tech DBMS Project.
**Tone:** Keep all explanations beginner-friendly.

---

## Technology Stack

| Layer    | Technology                                                             |
|----------|------------------------------------------------------------------------|
| Database | MySQL 8 installed directly on Windows. PHP is run separately via the built-in server. (Project at `E:\DBMS\PharmaTrace360`) |
| Backend  | PHP                                                                    |
| Frontend | HTML, CSS, Bootstrap, JavaScript                                       |

---

## Goal

One shared database that traces a medicine through its entire lifecycle:

```
Raw Material → Batch → Quality Test → QR Code → Public Scan → Recall
```

---

## Users & Roles (exactly 2 login roles — do not add more)

The `Roles` table in the database contains **exactly 2 rows**: `Admin/Regulator` and `Manufacturer`.

| Role / User       | System Role in `Roles` Table | Access                                     | Logs In? |
|-------------------|------------------------------|--------------------------------------------|----------|
| Admin / Regulator | `Admin/Regulator` (role_id 1)| Full access: dashboard, recalls, audit log | YES      |
| Manufacturer      | `Manufacturer` (role_id 2)   | Manage batches, raw materials, QA results  | YES      |
| Public Visitor    | *None (no database account)* | Scan QR codes only — **no login required** | NO — QR scan only |

### Roles and Permissions Enforcement

Permissions are strictly enforced at **two independent layers**:
1. **Database Layer (MySQL Least Privilege):**
   - Public uses `pt_public` (EXECUTE on `sp_verify_scan`, SELECT on `v_demo_codes` only).
   - Staff application uses `pt_app` (EXECUTE on business procedures, SELECT on views only, NO direct table access).
   - Stored procedures enforce authorization: `fn_user_can_manage_batch` restricts test/approve/reject actions to the batch's owning manufacturer; `sp_issue_recall` restricts recalls to active `Admin/Regulator` users.
2. **Web Layer (PHP Security Guard):**
   - Session authentication with HTTP-only and SameSite cookies.
   - `requireRole()` route guard prevents unauthorized URL navigation.
   - Per-form CSRF tokens prevent request forgery.
   - 30-minute idle session timeout.

| Role | Database User | Allowed Database Operations | Web Portal Capabilities |
|---|---|---|---|
| **Public** | `pt_public` | `sp_verify_scan`, `v_demo_codes` | Anonymous drug verification via QR code |
| **Manufacturer** | `pt_app` | `sp_record_delivery`, `sp_create_batch`, `sp_add_batch_material`, `sp_record_test`, `sp_approve_batch`, `sp_reject_batch`, `sp_change_password`, `v_batch_overview`, `v_batch_traceability`, `v_batch_tests`, `v_batch_qr_codes`, `v_form_suppliers`, `v_form_ingredients`, `v_form_medicines`, `v_form_factories`, `v_my_deliveries`, `v_batch_timeline` | View company batches, view traceability & tests, record raw deliveries, create pending batches, link materials, record QA tests, approve/reject batches, view vertical batch lifecycle timeline, change password |
| **Admin** | `pt_app` | `sp_issue_recall`, `sp_log_event`, `sp_login_lookup`, `sp_set_password`, `sp_change_password`, `v_dashboard`, `v_batch_status_counts`, `v_batch_overview`, `v_suspicious_codes`, `v_recent_audit`, `v_recall_list`, `v_batch_timeline` | KPI dashboard (Recalls KPI card links to `/app/recalls.php`), all-batch monitoring, high-frequency scan alerts, immutable audit log, emergency recall with impact assessment, recall list at `/app/recalls.php` (totals + post-recall scans), vertical batch lifecycle timeline in batch detail, change password |

> **Important notes:**
> - The `Roles` table has **exactly 2 rows** (`Admin/Regulator` and `Manufacturer`). There is **no 3rd role**.
> - **Suppliers** are database records (`Suppliers` table), NOT login users.
> - The **Public** never logs in; they scan QR codes anonymously via the public web page.

---

## Core Features (implement only these — do not add extras)

1. **Raw Material Linkage** — Every batch is linked to the raw materials
   and suppliers used to make it.
2. **QA Testing** — Record quality-assurance tests; a batch is marked
   Approved or Rejected based on results.
3. **QR Code Issuance** — QR codes are generated and assigned only to
   Approved batches.
4. **Scan Verification** — Every scan is stored; unknown QR codes are
   flagged; codes scanned suspiciously often are flagged as suspicious.
5. **Batch Recall** — One action recalls a batch and immediately shows
   everything it affects (linked records, distributed units, etc.).
6. **Audit Log** — A history table records all important actions
   (who did what and when).
7. **Dashboard** — One simple overview showing:
   - Batches by status (Approved / Rejected / Recalled / Pending)
   - Failed QA tests
   - Suspicious scans
   - Active recalls

---

## Public Scan Result Page

> **Status: Built** (`web/public/index.php`, styles in `web/public/assets/style.css`, backend in `web/includes/db.php`).
> The page accepts code input via text box or URL parameter `?code=...` and calls strictly `CALL sp_verify_scan(?)`.
> It handles multiple result sets via `nextRowset()` and `closeCursor()`.
> When `DEMO_MODE` is true, displays one sample code each for Genuine, Expired, and Recalled batches via a single read-only query.
> For known codes, displays the full public drug safety sheet; for unknown codes, displays only the verdict and advisory note.

When a member of the public scans a QR code, show ONLY the following:

| Field               | Example value                                                         |
|---------------------|-----------------------------------------------------------------------|
| Verdict             | Genuine / Expired / Recalled / Not Approved / Suspicious             |
| Medicine name       | Paracetamol                                                           |
| Strength & form     | 500 mg Tablet                                                         |
| Manufacturer        | Sun Pharma Ltd.                                                       |
| Batch number        | BT-2026-001                                                           |
| Manufacturing date  | 2026-01-15                                                            |
| Expiry date         | 2028-01-15                                                            |
| Storage conditions  | Store below 30 C, away from light                                     |
| Active ingredients  | Paracetamol 500 mg                                                    |
| Uses                | Fever, mild to moderate pain                                          |
| When to avoid       | Liver disease, alcohol use                                            |
| Side effects        | Nausea, rash (rare)                                                   |
| **Avoid taking together with** | Nimesulide; Oxyphenbutazone (drug interactions only)      |
| Advisory note       | **"Demo data - general information only, ask a doctor or pharmacist."** |

> The warnings section on the public scan screen is titled **"Avoid taking together
> with"** and lists drug interactions only.
> The advisory note **"Demo data - general information only, ask a doctor or
> pharmacist."** must always appear on every public scan result page.

### NEVER show to the public:
- Full chemical formulas or manufacturing processes
- Supplier names or contact details
- Internal QA test values or batch costs
- Any internal system IDs or confidential records

---

## Data Policy

| Data type                                                         | Source              |
|-------------------------------------------------------------------|---------------------|
| Medicines, manufacturers, ingredients, uses, side effects         | Real Kaggle datasets|
| Suppliers, deliveries, batches, QA results, QR codes, scans       | Simulated demo data |

- ~15 medicines are sufficient for the demo.
- **Never modify** any file inside `data/raw/`.
  All cleaning and transformation goes into `data/clean/`.

---

## DATA RULES

1. Any value typed in by hand (not sourced from the Kaggle CSV files) **must be
   listed in `docs/data_overrides.md`** with its reason.
2. **Never delete or overwrite** files in `data/raw/`. Treat that folder as
   read-only at all times.
3. **Do not commit `data/raw/` to version control.** Add `data/raw/` to
   `.gitignore` so raw CSV files are never pushed to a repository.

---

## SECURITY RULES

1. **Password hashing:** PHP must hash every password with `password_hash()` and
   verify it with `password_verify()`. Never store plain-text passwords.
2. **Prepared statements:** Use PDO prepared statements for **every** database
   query. Never concatenate user input directly into SQL strings.
3. **No database errors to users:** Catch all database exceptions in PHP and
   show only a generic error message to the user. Never expose SQL error text,
   table names, or stack traces in the browser.
4. **Credential safety:** Never write database passwords (or any credentials)
   into any file in this project — not in `.php`, `.sql`, `.env`, `.md`, or
   any other file. Never ask the user to paste a password into the chat.
   Never generate or run SQL that requires the database password to be supplied
   inline. When a script or SQL file must be executed, provide the **exact
   command** for the user to run themselves in their own Command Prompt —
   do not execute it on their behalf.
5. **Local configuration & connection boundary:** Never connect to the database,
   never ask for a password, and never open or edit `web/config.local.php`. If a
   task requires a new setting, tell the user the exact line and key/value so
   they can add it themselves.

---

## DBMS Concepts to Demonstrate

- ER Diagram
- Keys & Constraints (PK, FK, UNIQUE, NOT NULL, CHECK)
- Normalization (1NF through BCNF)
- Joins (INNER, LEFT, multi-table)
- Aggregates (COUNT, SUM, AVG)
- Subqueries (correlated and non-correlated)
- Views (at least 2: e.g. vw_batch_status, vw_public_scan)
- Stored Procedures (at least 2: e.g. sp_recall_batch, sp_issue_qr)
- Functions (at least 1: e.g. fn_batch_verdict)
- Triggers (at least 2: e.g. auto audit log, auto flag suspicious scan)
- Transactions (START TRANSACTION / COMMIT / ROLLBACK for recall)
- Indexing (with explanation of why each index is added)

---

## Relationship Summary

| Type | Count | Examples |
|---|---|---|
| **1-to-Many** | 16 | Roles→Users, Manufacturers→Factories, Batch→QR_Codes (one code per pack), etc. |
| **Many-to-Many** | 2 | Medicines↔Ingredients via `Drug_Formulations`; Batches↔Deliveries via `Batch_Materials` |
| **1-to-1** | 1 | Batch↔Recall (`UNIQUE batch_id` on `Product_Recalls`) |

---

## Rules Enforced by Triggers

The following business rules are **not expressible as plain CHECK constraints** and
are strictly enforced by MySQL triggers in `db/03_logic.sql`:

1. **User Role Integrity (`trg_users_bi`, `trg_users_bu`):**  
   - Manufacturer role requires a non-NULL `manufacturer_id`.  
   - Admin/Regulator role requires `manufacturer_id` to be NULL.

2. **Batch Factory & Medicine Ownership (`trg_batches_bi`, `trg_batches_bu`):**  
   - A batch's medicine and factory must belong to the exact same manufacturer.

3. **Raw Material Delivery Linkage & Inventory (`trg_batch_materials_bi`):**  
   - A batch may only use deliveries received by its own manufacturer.  
   - The delivery's ingredient must match an active ingredient in the medicine formulation (`Drug_Formulations`).  
   - The batch must have status `'Pending'` when materials are added.  
   - The delivery's received date must be on or before the batch's manufacture date.  
   - The total quantity used across all batches from that delivery (including the new link) must not exceed `Material_Deliveries.quantity_kg`.

4. **Batch Materials Lifecycle Lock (`trg_batch_materials_bu`, `trg_batch_materials_bd`):**  
   - Updating or deleting rows from `Batch_Materials` is blocked unless the parent batch status is `'Pending'`.

5. **Batch Approval Prerequisites (`trg_batches_bu`):**  
   - Transitioning status to `'Approved'` requires the most recent quality test report to be `'Pass'`.  
   - Transitioning status to `'Approved'` requires at least one raw material row linked in `Batch_Materials`.

6. **Recall Integrity & Immutability (`trg_batches_bu`):**  
   - Setting status to `'Recalled'` requires an existing row in `Product_Recalls`.  
   - A `'Recalled'` batch is immutable and cannot transition to any other status.

7. **QR Code Generation Gate (`trg_qr_codes_bi`):**  
   - Serialized QR codes can only be inserted for batches with status `'Approved'`.

8. **Append-Only Audit Log (`trg_audit_logs_bu`, `trg_audit_logs_bd`):**  
   - UPDATE and DELETE statements on `Audit_Logs` are blocked with `'Audit log is append-only.'`.

9. **Automated Audit Logging (AFTER Triggers):**  
   - Status changes on `Production_Batches` log `STATUS_<STATUS>` (`trg_batches_au`).  
   - New recalls on `Product_Recalls` log `INSERT_RECALL` (`trg_recalls_ai`).  
   - New QA tests on `Quality_Test_Reports` log `INSERT_QA_TEST` (`trg_qtr_ai`).  
   - New deliveries on `Material_Deliveries` log `DELIVERY_RECORDED` (`trg_deliveries_ai`).  
   - New batches on `Production_Batches` log `BATCH_CREATED` (`trg_batches_ai`).  
   - Material linkages on `Batch_Materials` log `MATERIAL_LINKED` (`trg_batch_materials_ai`).  
   - All after-insert triggers attribute events to `@app_user_id`.

---

## Stored Procedures & Views Catalog

### Stored Procedures
- `sp_verify_scan(IN p_code)`: Public verification endpoint returning multi-result sets (medicine, uses, side effects, interactions) while redacting sensitive operational data.
- `sp_record_delivery(IN p_user_id, IN p_supplier_name, IN p_ingredient_name, IN p_quantity_kg, IN p_received_date, IN p_certificate_number)`: Validates active Manufacturer, creates raw material delivery within transaction, and sets `@app_user_id`.
- `sp_create_batch(IN p_user_id, IN p_batch_number, IN p_medicine_name, IN p_factory_name, IN p_quantity, IN p_manufacture_date, IN p_expiry_date)`: Validates active Manufacturer and ownership of medicine/factory, creates batch as `'Pending'`.
- `sp_add_batch_material(IN p_user_id, IN p_batch_number, IN p_certificate_number, IN p_quantity_used_kg)`: Authorizes manufacturer via `fn_user_can_manage_batch`, locks batch row (`FOR UPDATE`), and links delivery material.
- `sp_record_test(IN p_batch_number, IN p_user_id, IN p_purity, IN p_dissolution, IN p_weight_variation, IN p_result, IN p_remarks)`: Locks batch row (`FOR UPDATE`) and records QA report for Pending batch.
- `sp_approve_batch(IN p_batch_number, IN p_user_id, IN p_pack_count)`: Locks batch row (`FOR UPDATE`), approves batch, and atomically generates `p_pack_count` unique QR codes.
- `sp_reject_batch(IN p_batch_number, IN p_user_id)`: Locks batch row (`FOR UPDATE`) and rejects Pending batch if latest test is Fail.
- `sp_issue_recall(IN p_batch_number, IN p_reason, IN p_user_id)`: Authorizes active Admin/Regulator, locks batch row (`FOR UPDATE`), creates recall record, marks batch `'Recalled'`, and returns impact report.
- `sp_change_password(IN p_user_id, IN p_new_hash)`: Updates user bcrypt hash and logs `'PASSWORD_CHANGED'` audit event.
- `sp_log_event(IN p_user_id, IN p_action, IN p_details)`: Helper to record authentication events.
- `sp_login_lookup(IN p_email)`: Returns credentials and role for PHP authentication.
- `sp_set_password(IN p_email, IN p_hash)`: CLI utility procedure to set user password by email.

### Views
- `v_batch_overview`: Batch summary with medicine, manufacturer, factory, status, and QR count.
- `v_batch_traceability`: Upstream raw material and certificate traceability per batch.
- `v_suspicious_codes`: Aggregates codes scanned > 5 times to flag counterfeiting.
- `v_dashboard`: High-level system KPIs (approved batches, failed tests, suspicious scans, recalls).
- `v_batch_status_counts`: Distribution of batches across statuses.
- `v_demo_codes`: Sample codes for Genuine, Expired, and Recalled products.
- `v_batch_tests`: Test report history per batch.
- `v_recent_audit`: Last 20 system audit logs with user names.
- `v_batch_qr_codes`: QR codes issued per batch with scan frequency and timestamp.
- `v_form_suppliers`: Distinct supplier names for UI dropdowns.
- `v_form_ingredients`: Distinct ingredient names for UI dropdowns.
- `v_form_medicines`: Branded medicines filtered by manufacturer for UI dropdowns.
- `v_form_factories`: Factories filtered by manufacturer for UI dropdowns.
- `v_my_deliveries`: Delivery stock per manufacturer showing total, used, and remaining kg.
- `v_batch_timeline`: Unified chronological lifecycle timeline built across base tables and audit logs.
- `v_recall_list`: Regulatory recall register showing affected batches, medicines, issuer email, QR counts, and post-recall scan volume.

---

## Project Folder Structure

```
PharmaTrace360/
|-- data/
|   |-- raw/          <- Original Kaggle CSVs — READ ONLY, never edit, not in git
|   +-- clean/        <- Processed data ready for import
|-- db/               <- All SQL files
|-- web/              <- PHP + HTML/CSS/JS frontend
+-- docs/             <- ER diagrams, reports, CONTEXT.md, data_overrides.md
```

---

## Coding Rules

1. No extra features or tables — stick to the core features above.
2. Every .sql file must be complete and runnable on a fresh MySQL 8 installation on Windows.
3. Never modify `data/raw/` — use `data/clean/` for prepared data.
4. After every task, write a short summary of what was created or changed.
5. Add SQL comments explaining WHY, not just what.
