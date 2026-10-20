# PharmaTrace 360

PharmaTrace 360 is a database-backed pharmaceutical batch traceability and QR verification project. It demonstrates how a medicine can be traced from master data and raw-material delivery through manufacturing, quality checks, batch release, QR verification, suspicious-scan review, audit logging, and product recall.

> **Project scope:** academic/demo software. Operational records are synthetic, some medicine information is sourced from third-party datasets and overrides, and the project is not a clinical decision system or a production-certified anti-counterfeiting platform.

## Start here

- **Complete setup and operation commands:** [COMMANDS.md](COMMANDS.md)
- Fresh Windows installation guide: [docs/SETUP.md](docs/SETUP.md)
- Web frontend notes: [web/README.md](web/README.md)
- Schema dictionary: [docs/data_dictionary.md](docs/data_dictionary.md)
- Relationship diagram: [docs/er_diagram.md](docs/er_diagram.md)
- Relational schema and normalization notes: [docs/relational_schema.md](docs/relational_schema.md), [docs/normalization.md](docs/normalization.md), [docs/functional_dependencies.md](docs/functional_dependencies.md)
- SQL logic walkthrough: [docs/logic_overview.md](docs/logic_overview.md)
- Test matrix: [docs/test_cases.md](docs/test_cases.md)
- Database design review: [docs/dbms_audit.md](docs/dbms_audit.md)
- Known assumptions and limitations: [docs/known_limitations.md](docs/known_limitations.md)

## Contents

1. [What the system does](#what-the-system-does)
2. [Technology stack](#technology-stack)
3. [Architecture and request flows](#architecture-and-request-flows)
4. [Roles and permissions](#roles-and-permissions)
5. [End-to-end batch lifecycle](#end-to-end-batch-lifecycle)
6. [Public QR-verification logic](#public-qr-verification-logic)
7. [Database design](#database-design)
8. [Main database routines, views, and triggers](#main-database-routines-views-and-triggers)
9. [Application pages](#application-pages)
10. [Repository layout](#repository-layout)
11. [Installation and running](#installation-and-running)
12. [Testing](#testing)
13. [Data provenance and limitations](#data-provenance-and-limitations)
14. [Security notes](#security-notes)

## What the system does

PharmaTrace 360 brings the following workflows together:

- **Raw-material intake:** an active Manufacturer records a supplier delivery with an ingredient, quantity, received date, and unique Certificate of Analysis (CoA) number.
- **Batch creation:** an active Manufacturer creates a Pending production batch for a medicine and factory belonging to the same manufacturer.
- **Material allocation:** a delivery is linked to a Pending batch with a quantity used. Database triggers enforce manufacturer ownership, formulation compatibility, date constraints, and delivery quantity limits.
- **Quality assurance (QA):** the manufacturer records purity, dissolution, weight variation, result, and remarks. The project validates the input range and the stated Pass/Fail result; it does **not** derive a product-specific QA result from regulatory specifications.
- **Batch release:** a Pending batch can be approved only when its most recent QA report is Pass and at least one raw material is linked. Approval and QR generation occur in one transaction.
- **Rejected batches:** a Pending batch can be rejected when its latest QA report is Fail.
- **Public QR verification:** a scan asks the database for a current verdict, logs the attempt, and displays the available medicine/batch information.
- **Suspicious-scan triage:** an Admin/Regulator can inspect codes with high recent scan volume and assign New, Reviewed, or Blocked analyst-review status.
- **Recalls:** an active Admin/Regulator can issue a recall, causing the batch status to become Recalled. A recalled batch cannot transition back to another status.
- **Audit and traceability:** database triggers append audit events for important operations; views present batch, material, test, QR, scan, and recall information.

The system is designed around server-side validation: form validation improves usability, but stored procedures, triggers, foreign keys, unique indexes, and check constraints are the core database controls.

## Technology stack

| Component | Purpose |
|---|---|
| MySQL 8.0+ | 17-table relational database; keys, constraints, views, functions, triggers, transactions, stored procedures, grants |
| PHP 8.1+ | Public verification page and authenticated staff portal |
| PHP PDO MySQL extension | Parameterized database calls with exception handling |
| Python 3.10+ | Optional seed SQL and medicine CSV generation |
| HTML, CSS, Bootstrap assets, JavaScript | Responsive UI and client-side QR rendering |
| GitHub Actions | PHP syntax linting, Python compilation, MySQL setup and SQL regression checks |

The application includes local Bootstrap and QR-code JavaScript assets. Its documented local-development server is PHP's built-in server; that is convenient for coursework and testing, not a hardened production web server.

## Architecture and request flows

### Public verification

~~~text
Browser / phone camera
        |
        v
web/public/index.php
        |
        | PDO connection: pt_public
        v
sp_verify_scan(code)
        |
        +--> fn_qr_verdict(code)
        |       +--> QR_Codes
        |       +--> Production_Batches
        |       +--> Product_Recalls
        |       +--> prior Scan_Log events
        |
        +--> append Scan_Log event (known or unknown code)
        |
        +--> return verdict and allowed medicine information
        v
Public verification result
~~~

The public database account is intended to execute the verification procedure and read the demo-code view, rather than to have direct table access. Unknown attempted codes are also recorded, with a NULL QR foreign key where appropriate, so the system can observe unknown-code activity.

### Staff portal

~~~text
Staff browser
     |
     v
login.php --> sp_login_lookup(email) --> PHP password_verify()
     |
     v
Session + role guard
     |
     +--> sp_session_lookup(user_id) to re-check active account and role
     |
     v
Protected PHP pages
     |
     +--> pt_app connection --> business procedures and reporting views
     |
     +--> procedures / triggers --> transactional changes + Audit_Logs
~~~

Passwords are hashed with PHP's password-hashing functions. The CLI password bootstrap utility uses a separate pt_setup connection; it should never be configured for normal web requests.

## Roles and permissions

### Public visitor

Can submit a QR code for verification and see the public result. There is no public account or login. Public verification intentionally avoids exposing internal supplier deliveries, manufacturing costs, or QA records.

### Manufacturer

The demo Manufacturer accounts are associated with one manufacturer. They can manage only batches owned by that manufacturer's factory/company context and can:

- record raw-material deliveries;
- create Pending batches;
- link eligible deliveries to Pending batches;
- record QA reports;
- approve an eligible Pending batch or reject a Pending batch whose latest QA is Fail;
- view batches and print/display their QR codes;
- change their password.

Examples seeded in the demo:

| Login email | Role / company |
|---|---|
| rahul.mfr@demo.test | Manufacturer — Cipla Ltd |
| anjali.mfr@demo.test | Manufacturer — Alkem Laboratories Ltd |
| vikram.mfr@demo.test | Manufacturer — Alembic Pharmaceuticals Ltd |

### Admin/Regulator

The demo Admin/Regulator account is priya.admin@demo.test. It can view the cross-manufacturer dashboard, batches, audit records, suspicious scans, and recalls; issue recalls; and manage suspicious-code analyst-review status. The Admin/Regulator role is not a substitute for manufacturer-owned batch operations.

These are demo login emails only. Seeded accounts use disabled placeholder password hashes until passwords are set locally with the CLI tool described in [COMMANDS.md](COMMANDS.md).

## End-to-end batch lifecycle

### 1. Record a delivery

A manufacturer records a delivery from a pre-existing supplier for a pre-existing ingredient. The delivery has a positive quantity, a non-future received date, and a non-empty certificate number. The database enforces certificate uniqueness and the stored procedure confirms the supplied entities exist.

### 2. Create a batch

A manufacturer supplies a unique batch number, medicine, factory, quantity, manufacture date, and expiry date. The medicine and factory must belong to the same manufacturer; the caller must own the batch context; the manufacture date cannot be in the future; expiry must be after manufacture; and quantity must be positive. New batches begin as Pending.

### 3. Allocate raw material

A delivery can be linked to a batch only if the batch is Pending, the delivery belongs to the same manufacturer, the delivery ingredient is part of the medicine's formulation, and the allocation does not over-consume the delivery. The batch and delivery are locked in the allocation procedure to serialize concurrent allocations against the same delivery.

### 4. Record QA

An active Manufacturer who owns the batch records a test result for a Pending batch. The measurements must be present and within 0–100, and the result must be Pass or Fail with non-empty remarks. Those generic range checks are not a product-specific regulatory acceptance specification.

**Important distinction:** the database checks the submitted result label. It does not automatically calculate Pass/Fail from purity, dissolution, or weight variation. A real deployment would need approved, product-specific QA acceptance criteria.

### 5. Approve or reject

Approval requires all of the following:

- the batch exists and is currently Pending;
- the caller is an active Manufacturer authorized for that batch;
- the pack count is between 1 and 50, and does not exceed the batch's recorded production quantity;
- the latest QA report is Pass;
- at least one raw-material delivery is linked.

Approval and QR creation are transactional: if an operation fails, the status change and QR inserts are rolled back. Repeated approval of an Approved batch is rejected.

Rejection requires a Pending batch with a latest QA result of Fail. It does not silently convert a failed QA label into an approval or issue QR codes.

### 6. Verify or recall

The public site evaluates the QR code against the current database state. A recall is an Admin/Regulator operation that inserts a recall record and updates the batch to Recalled in one transaction. New scans on recalled batches show Recalled. The database retains prior scan verdicts as historical observations rather than rewriting history.

## Public QR-verification logic

The function fn_qr_verdict uses this precedence order:

1. **Unknown code → Suspicious.**
2. **Batch Recalled → Recalled.**
3. **Batch status is not Approved → Not approved.**
4. **Expiry date is in the past → Expired.**
5. **More than 10 scans during the preceding 48 hours → Suspicious.**
6. **Otherwise → Genuine.**

The exact order matters: a recalled batch is shown as Recalled even if it is expired, for example.

A scan invokes the stored procedure and creates a Scan_Log row. The current procedure computes the verdict from previously recorded scans before inserting the current scan. The suspicious-review view aggregates recorded scan events in its rolling time window; because of that execution order, the view can reflect a threshold crossing one recorded scan earlier than the public verdict on the next request. This is a demo velocity rule, not a validated fraud-detection model.

The code is an online lookup token, not a signed certificate. Runtime-generated tokens use cryptographically strong random bytes; deterministic seeded codes help make demo data repeatable. QR contents alone cannot be verified offline.

## Database design

The 17 base tables are grouped around users/master data, operational traceability, and security/history.

| Table | Responsibility |
|---|---|
| Roles | Available role names |
| Manufacturers | Manufacturer/company master data |
| Factories | Manufacturer-owned factories |
| Users | Staff accounts, password hashes, role, active status, manufacturer association |
| Suppliers | Supplier master data |
| Ingredients | Ingredient master data |
| Material_Deliveries | Incoming ingredient deliveries, supplier, quantity, date, certificate number, manufacturer |
| Medicines | Medicine master details |
| Drug_Formulations | Links medicines to their ingredients and strengths |
| Medicine_Info | Uses, side effects, avoid-with information, and related descriptive items |
| Production_Batches | Batch identity, medicine, factory, quantity, manufacture/expiry dates, status |
| Batch_Materials | Junction table linking batch to delivery, with quantity used |
| Quality_Test_Reports | One or more QA reports per batch |
| QR_Codes | Unique verification codes associated with batches |
| Scan_Log | Every verification attempt, time, verdict, matching QR where known, and analyst review status |
| Product_Recalls | Recall reason/date/timestamp/issuer for a batch |
| Audit_Logs | Append-oriented operational/security audit events |

### Relational design ideas demonstrated

- **Primary keys and foreign keys** protect entity identity and reference integrity.
- **Unique constraints** protect login emails, QR codes, delivery certificate numbers, batch numbers, and one-recall-per-batch semantics where defined by the schema.
- **Batch_Materials** models the many-to-many relationship between batches and deliveries.
- **Quality_Test_Reports** allows retests rather than overwriting prior QA evidence.
- **Scan_Log** deliberately preserves the verdict observed at scan time.
- **Views** encapsulate common joins and summary queries.
- **Transactions** keep multi-step actions atomic.
- **Triggers** enforce cross-table rules that cannot be expressed as simple column checks.
- **Audit events** support investigation and demonstration of traceable changes.

See [docs/data_dictionary.md](docs/data_dictionary.md) for nullable/key/type details, and [docs/normalization.md](docs/normalization.md) for normalization reasoning.

## Main database routines, views, and triggers

### Key stored procedures

| Routine | Purpose |
|---|---|
| sp_verify_scan | Calculates the current public verdict, logs the scan, returns medicine data when known |
| sp_record_delivery | Records an incoming raw-material delivery for an active Manufacturer |
| sp_create_batch | Creates an owned Pending batch with validated medicine/factory/date/quantity |
| sp_add_batch_material | Links a delivery to a Pending batch and locks the relevant inventory row |
| sp_record_test | Records QA inputs and result for a Pending batch |
| sp_approve_batch | Validates release conditions and issues QR codes in one transaction |
| sp_reject_batch | Rejects a Pending batch with a latest Fail report |
| sp_issue_recall | Creates a recall and marks the batch Recalled transactionally |
| sp_update_suspicious_review | Lets an active Admin/Regulator set the analyst status of a scanned code |
| sp_login_lookup | Returns login fields needed by PHP authentication |
| sp_session_lookup | Revalidates active-account status and current role for protected requests |
| sp_change_password | Stores a new password hash and adds a password-change audit event |
| sp_set_password | CLI bootstrap routine for setting a user's hash after seed setup |
| sp_log_event | Logs login/logout/authentication events |

### Important views

- v_batch_overview — batch-level overview and QR summary.
- v_batch_traceability — batch-to-material-to-delivery/supplier trace.
- v_suspicious_codes — high-frequency codes within the rolling 48-hour review window and review status.
- v_dashboard and v_batch_status_counts — administrative summaries.
- v_batch_tests — batch QA reports.
- v_recent_audit — recent audit activity.
- v_batch_qr_codes — QR code inventory for batches.
- v_form_suppliers, v_form_ingredients, v_form_medicines, v_form_factories — form-select data.
- v_my_deliveries — delivered, used, and remaining quantities for a manufacturer's inventory view.
- v_batch_timeline — lifecycle events for a batch.
- v_recall_list — recall summaries, QR counts, total scans, and scans at/after issued_at.
- v_demo_codes — representative seeded codes shown when demo mode is enabled.

### Trigger responsibilities

The triggers in db/03_logic.sql validate roles/company association, batch medicine/factory ownership, material allocation eligibility and balance, QR eligibility, batch approval/rejection/recall transitions, and audit logging. Audit triggers record status changes, deliveries, material links, QA reports, new batches, and recalls. Audit update/delete triggers reject ordinary UPDATE/DELETE attempts; this is not a claim of tamper-proof storage against a privileged database administrator.

## Application pages

| Path | Purpose / audience |
|---|---|
| / (web/public/index.php) | Public QR verification |
| /login.php | Staff login |
| /logout.php | CSRF-protected POST logout |
| /app/dashboard.php | Admin dashboard |
| /app/all_batches.php | Admin cross-company batch listing |
| /app/batches.php | Manufacturer batch listing |
| /app/batch_new.php | Manufacturer batch creation |
| /app/batch_detail.php | Batch detail, QA/material actions, lifecycle timeline |
| /app/deliveries.php | Manufacturer delivery entry and inventory |
| /app/qr_sheet.php | View/print QR code sheet |
| /app/suspicious.php | Admin high-frequency scan review |
| /app/audit.php | Admin audit log view |
| /app/recall.php | Admin recall issuance |
| /app/recalls.php | Admin recall reporting |
| /app/change_password.php | Logged-in user password change |

## Repository layout

~~~text
PharmaTrace360/
├── README.md                       # This overview
├── COMMANDS.md                     # Copy-paste operations / SQL cookbook
├── .github/workflows/ci.yml        # Automated checks
├── db/
│   ├── 00_reset_all.sql            # DESTRUCTIVE fresh-demo rebuild
│   ├── 01_schema.sql               # Database + 17 base tables/keys
│   ├── 02_seed.sql                 # Seeded master/demo records
│   ├── 03_logic.sql                # Views, functions, triggers, procedures
│   ├── 04_demo.sql                 # Stateful demo script
│   ├── 05_grants.sql               # pt_public + pt_app grants
│   ├── 06_queries.sql              # SELECT-only SQL demonstration queries
│   ├── 06_suspicious_review.sql    # Repeatable suspicious-review migration
│   ├── 07_acid_demo.sql            # Two-session ACID walkthrough
│   ├── 08_feature_tests.sql        # State-changing feature/regression tests
│   ├── 09_upgrade_existing.sql     # Non-destructive upgrade for existing DB
│   ├── 10_setup_grants.sql         # pt_setup password-bootstrap grant
│   └── build_seed.py               # Builds db/02_seed.sql from CSV
├── data/clean/
│   ├── medicines_15.csv            # Cleaned medicine dataset used by seed builder
│   └── build_medicines_15.py       # Optional raw-data-to-clean-CSV builder
├── docs/                           # Setup, model, audit, test, limitations docs
└── web/
    ├── config.sample.php           # Template; copy to ignored config.local.php
    ├── includes/                   # PDO, session/auth and layout helpers
    ├── public/                     # Public entry points and protected pages
    └── tools/set_password.php      # CLI-only initial password utility
~~~

The raw source CSVs used by data/clean/build_medicines_15.py are not bundled in the repository. Obtain them separately from their original source, verify that their licence/use is appropriate, and place them under data/raw with the filenames specified in the script before running that optional builder.

## Installation and running

For a complete, ordered, copy-paste walkthrough—including Windows paths, MySQL users, local configuration, demo passwords, SQL calls, backups, and testing—use **[COMMANDS.md](COMMANDS.md)**.

At a high level, a fresh local demo install requires:

1. Install MySQL 8.0+, PHP 8.1+ with pdo_mysql, and optionally Python 3.10+.
2. Create the MySQL accounts pt_public, pt_app, and pt_setup.
3. From the repository root, run db/00_reset_all.sql to create/reseed the demo database.
4. Run db/10_setup_grants.sql for the CLI-only pt_setup permission.
5. Copy web/config.sample.php to web/config.local.php and enter the local DB passwords.
6. Use php web/tools/set_password.php to set passwords for seeded accounts.
7. Start php -S localhost:8000 -t web/public and open http://localhost:8000.

**Do not run db/00_reset_all.sql on a database whose records you want to keep.** For an existing installation, back up first and review db/09_upgrade_existing.sql; it preserves rows but recreates database routines/views and applies integrity changes. The upgrade can stop safely if legacy duplicate certificate numbers need resolution.

## Testing

### GitHub Actions

The workflow in .github/workflows/ci.yml is designed to run:

- PHP syntax lint across the web PHP files;
- Python bytecode compilation for db and data/clean;
- a fresh MySQL 8.0 setup, schema/routine checks and a public verification call;
- non-destructive-upgrade and review-migration repeatability checks;
- the state-changing SQL feature/regression suite.

Check the Actions run itself for the status of a particular commit; a queued run is not a passed run.

### SQL scripts

- db/06_queries.sql is SELECT-only and suitable for routine read-only inspection.
- db/07_acid_demo.sql is a guided two-terminal demonstration; follow its [A]/[B] instructions in the same order instead of piping the whole file into a single session.
- db/04_demo.sql mutates demo state.
- db/08_feature_tests.sql intentionally produces errors for negative tests, uses the mysql client force option, and changes records. Run it only against a disposable demo database, then reset that disposable database if needed.
- docs/test_cases.md documents the manual test matrix.

## Data provenance and limitations

- Manufacturer, factory, supplier, batch, QA, scan and audit events are synthetic demonstration data.
- The 15-medicine dataset is derived from CSV data plus hand-entered overrides documented in docs/data_overrides.md and docs/dataset_report.md.
- Drug uses, side effects, avoid-with details, and generic storage notes are not clinically verified by this project. Do not use them to diagnose, prescribe, or make real medication decisions.
- Source-data licences have not been fully audited; review them before redistribution or any non-academic use.
- There is no built-in end-user screen for creating corporate master records such as medicines or suppliers. Those are managed through SQL and seed scripts.
- The QR is a database lookup token rather than a digitally signed object, so online verification is required.
- Public-scan and staff-login rate limiting are not implemented. Add infrastructure/application throttles before any Internet-facing deployment.
- The analyst status Blocked is for admin triage and does not, by itself, change the public verdict.
- The public verdict's velocity rule is a classroom heuristic, not a validated counterfeiting classifier.

## Security notes

- Keep web/config.local.php and backups containing database/user data out of Git. Never commit real DB credentials, password hashes from live accounts, or backup dumps.
- pt_public is for public verification; pt_app is for the staff web portal; pt_setup is only for the CLI password bootstrap tool.
- Keep pt_setup credentials out of any web-hosted database connection and restrict host/database access to the local machine where possible.
- The local PHP server is intended for development. Production requires HTTPS, appropriate web-server configuration, robust rate limiting, monitored logging, reviewed access policies, regular backups, and a clear restore procedure.
- MySQL grants, stored procedure inputs, PHP session checks, and server-side form validation work together; the current shared pt_app identity is not a standalone per-user database-authentication boundary.
- Review docs/known_limitations.md before describing the project as production-ready.

## Contributing / making changes

1. Work on a separate branch.
2. Inspect a diff before committing: git diff --check and git diff.
3. Run PHP lint, Python compilation, the read-only SQL queries, and the applicable MySQL regression checks against a disposable database.
4. Back up existing data before applying database migrations.
5. Never use the destructive reset on a database containing data you need.
