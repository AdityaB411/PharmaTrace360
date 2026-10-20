# PharmaTrace 360 — Changes from the Original Plan

> **Audience:** 2nd-Year B.Tech DBMS Students, Evaluators, and Developers.  
> **Purpose:** Explains why and how the database design evolved from an initial 15-table draft into a normalized, robust 17-table schema, how the 15 system modules are mapped to database objects, and why specific technologies and features were deliberately omitted.

---

## 1. Evolution of the Database Tables (15 Planned → 17 Final)

During the initial conceptual phase, a flat 15-table design was proposed. As we applied formal relational database normalization rules (1NF, 2NF, 3NF, BCNF) and analyzed real-world pharmaceutical workflow requirements, three significant architectural changes were made:
1. `Raw_Materials` was split into **`Ingredients`** and **`Material_Deliveries`**.
2. **`Medicine_Info`** was added to eliminate repeating groups from `Medicines` (1NF).
3. **`Batch_Materials`** was added to model the Many-to-Many consumption relationship between batches and material deliveries (2NF).
4. `Product_Authentication` was renamed and restructured into **`Scan_Log`** to support logging unknown counterfeit codes without foreign key failure.

### Table Comparison & Rationales

| # | Original Planned Table | Final Table in Schema | Change Type | Reason for the Architectural Change |
|:---:|---|---|:---:|---|
| 1 | `Roles` | `Roles` | Kept | Stores core system roles (`Admin/Regulator` and `Manufacturer`). Unchanged. |
| 2 | `Users` | `Users` | Kept | Stores authenticated system user accounts with hashed credentials. Unchanged. |
| 3 | `Manufacturers` | `Manufacturers` | Kept | Master catalog of licensed pharmaceutical manufacturing companies. Unchanged. |
| 4 | `Factories` | `Factories` | Kept | Manufacturing plants owned by manufacturers (1-to-many). Unchanged. |
| 5 | `Suppliers` | `Suppliers` | Kept | Verified third-party raw material chemical suppliers. Unchanged. |
| 6 | `Raw_Materials` | **`Ingredients`** *(Part 1)* | **Split** | The original table conflated the abstract chemical molecule (e.g. Paracetamol, CAS number) with physical delivery shipments. `Ingredients` now acts as the pure chemical dictionary. |
| 7 | *(Implicit Inventory)* | **`Material_Deliveries`** *(Part 2)* | **Added** | Represents actual shipments received from suppliers. Stores supplier, manufacturer, quantity in kg, date received, and Certificate of Analysis (`certificate_number`). This avoids repeating chemical definitions on every shipment (3NF). |
| 8 | `Medicines` | `Medicines` | Refined | Contains core medicine metadata (brand name, dosage form, pack size, therapeutic class, storage instructions). Multi-valued fields were extracted to satisfy 1NF. |
| 9 | `Drug_Formulations` | `Drug_Formulations` | Kept | Junction table resolving the Many-to-Many relationship between `Medicines` and `Ingredients` (storing `strength` and `is_active`). |
| 10 | *(Embedded columns in Medicines)* | **`Medicine_Info`** | **Added** | In the original plan, uses, side effects, and contraindicated drugs were comma-separated strings inside `Medicines`. Normalization (1NF) strictly requires atomic attributes. `Medicine_Info` stores one fact per row (`info_type`: `'use'`, `'side_effect'`, `'avoid_with'`). |
| 11 | `Production_Batches` | `Production_Batches` | Kept | Manufacturing batch records (batch number, factory, quantity, manufacture and expiry dates, status). |
| 12 | *(Implicit Batch Link)* | **`Batch_Materials`** | **Added** | In reality, one batch can consume materials from multiple supplier deliveries, and one delivery can be used across multiple batches (Many-to-Many). `Batch_Materials` acts as the junction table with `quantity_used_kg`, enabling true forward and backward genealogical traceability. |
| 13 | `Quality_Test_Reports` | `Quality_Test_Reports` | Kept | Laboratory QC assay reports recording purity %, dissolution %, weight variation %, and Pass/Fail result. |
| 14 | `QR_Codes` | `QR_Codes` | Kept | Unique serialization codes assigned to individual packages of approved batches (`PT360-...`). |
| 15 | `Product_Authentication` | **`Scan_Log`** | **Renamed & Redesigned** | The original name implied a one-time validation check. It is actually an append-only audit log of consumer verification events. Crucially, `scanned_code` is a plain `VARCHAR` and `qr_id` is a nullable foreign key. This allows the system to record scans of **fake / unknown codes** without throwing a Foreign Key constraint violation. |
| 16 | `Product_Recalls` | `Product_Recalls` | Kept | 1-to-1 extension on `Production_Batches` (`UNIQUE batch_id`) recording regulatory recall orders, reasons, and dates. |
| 17 | `Audit_Logs` | `Audit_Logs` | Kept | Immutable security audit trail populated automatically by database `AFTER` triggers (`trg_batches_au`, `trg_recalls_ai`, `trg_qtr_ai`). |

---

## 2. Mapping the 15 Conceptual Modules to Database Objects

A common question is: *"Where did the 15 software modules go?"*  
In modern DBMS architecture, business logic is implemented close to the data using tables, relational constraints, stored procedures, functions, triggers, and views.

| # | Conceptual Module | Where It Lives in PharmaTrace 360 | Implementation Details |
|:---:|---|---|---|
| 1 | **User & Role Management** | `Roles`, `Users`, `trg_users_bi`, `trg_users_bu` | Enforces role-based separation: Manufacturer users must link to a company; Admins must not. |
| 2 | **Manufacturer Management** | `Manufacturers` table | Enforces unique registration numbers (`uq_mfr_reg`) and maintains corporate contacts. |
| 3 | **Factory Operations** | `Factories` table | Foreign key links to parent manufacturer; tracks facility licenses. |
| 4 | **Supplier Management** | `Suppliers` table | Maintains vendor contact information and addresses. |
| 5 | **Raw Material Catalog** | `Ingredients` table | Standardized active pharmaceutical ingredients (APIs) and CAS registry numbers. |
| 6 | **Intake & Procurement** | `Material_Deliveries` table | Tracks received raw materials, supplier lots, delivery dates, and analytical test certificates. |
| 7 | **Drug Master & Formulations** | `Medicines`, `Drug_Formulations`, `Medicine_Info` | Relational formulation engine; provides structured uses, side effects, and drug interaction warnings. |
| 8 | **Manufacturing Management** | `Production_Batches`, `sp_approve_batch` | Manages batch lifecycles (Pending → Approved / Rejected / Recalled); controls pack quantities. |
| 9 | **Batch Traceability (Genealogy)** | `Batch_Materials`, `v_batch_traceability`, `trg_batch_materials_bi` | Full supply chain trace linking every finished batch back to deliveries, suppliers, and COA numbers. Trigger ensures factories only consume ingredients received by their parent manufacturer. |
| 10 | **Quality Assurance & Testing** | `Quality_Test_Reports`, `trg_qtr_ai`, `trg_batches_bu` | Records laboratory tests. Trigger `trg_batches_bu` guarantees a batch **cannot** be approved unless its latest QA test is a verified `Pass`. |
| 11 | **Serialization & QR Issuance** | `QR_Codes`, `trg_qr_codes_bi`, `sp_approve_batch` | Procedural loop generates secure 12-character hex QR codes (`MD5(UUID())`) strictly for approved batches. |
| 12 | **Public Drug Verification** | `sp_verify_scan`, `web/public/index.php` | Consumer portal; takes a code, returns 4 structured result sets (verdict, uses, side effects, contraindications) without exposing confidential supplier or cost data. |
| 13 | **Counterfeit & Fraud Detection** | `fn_qr_verdict`, `fn_recent_scan_count`, `v_suspicious_codes`, `Scan_Log` | Flags unissued codes, expired medicines, recalled batches, and detects duplicate/cloned codes scanned >10 times in 48 hours. |
| 14 | **Batch Recall Management** | `Product_Recalls`, `sp_issue_recall`, `trg_recalls_ai` | Executes atomic ACID transaction: registers recall, switches batch status, and immediately returns full impact report (affected packs, deliveries, supplier contacts, total scans). |
| 15 | **Reporting & Executive Dashboard** | `v_dashboard`, `v_batch_overview`, `v_batch_status_counts`, `Audit_Logs` | Aggregated views feed KPI cards (approved batches, failed tests, suspicious scans, active recalls) and status distribution charts. |

---

## 3. What Was Deliberately Left Out (To Stay Lean & Focused)

In software engineering, deciding what **not** to build is just as important as deciding what to build. For an academic and enterprise DBMS demonstration, several common industry features were intentionally omitted:

1. **No Blockchain / Distributed Ledger (DLT):**
   - *Future scope:* Blockchain-based tamper evidence is a potential future enhancement. For this project, a relational database with immutable audit logs, triggers, and hashing provides equivalent guarantees with simpler setup and native SQL reporting.

2. **No Heavy Frontend / Fullstack Frameworks (React, Next.js, Angular, Node.js):**
   - *Why omitted:* Introducing large JavaScript frameworks brings thousands of `npm` dependencies, build tooling overhead, and hydration lag. PharmaTrace 360 uses clean, native **PHP 8 + Vanilla HTML/CSS + Bootstrap CDN**. This keeps the application immediately runnable on any standard environment without complex compilation steps.

3. **No Heavy ORM (Object-Relational Mapping):**
   - *Why omitted:* Heavy ORMs (such as Doctrine or Hibernate) hide SQL syntax and often generate inefficient, un-optimized queries. Because this is a database-first project, all data interactions use clean **PDO prepared statements** calling MySQL 8 stored procedures and views directly, demonstrating mastery of raw SQL.

4. **No Microservices / Distributed Message Queues (Kafka / RabbitMQ):**
   - *Why omitted:* PharmaTrace 360 leverages MySQL's native ACID engine (`START TRANSACTION`, `COMMIT`, `ROLLBACK`), guaranteeing data consistency for critical operations like batch approvals and recalls.

5. **No IoT Temperature / GPS Sensor Ingestion:**
   - *Future scope:* IoT sensor ingestion (e.g. cold-chain temperature monitoring, GPS tracking) and AI-based counterfeit detection are potential future enhancements that would complement the existing traceability data.

6. **No Financial / Billing / ERP Accounting Modules:**
   - *Why omitted:* Purchase orders, invoicing, excise taxes, and customer billing would add unnecessary tables without contributing to the core goal of pharmaceutical safety, quality assurance, and anti-counterfeiting.
