# PharmaTrace 360 — Copy-Paste Command Cookbook

This file is the operational companion to [README.md](README.md). It collects the actual commands needed to install, start, inspect, operate, test, back up, and maintain PharmaTrace 360.

**Target environment:** Windows Command Prompt (CMD), MySQL 8.0+, PHP 8.1+ with `pdo_mysql`. Most commands also work from PowerShell, but the examples use CMD redirection and path syntax.

## Read this before running commands

### Which terminal am I in?

| Prompt / tool | Use it for |
|---|---|
| **Windows CMD** | Commands beginning with `mysql`, `mysqldump`, `php`, `python`, `copy`, `cd` |
| **MySQL prompt** (`mysql>`) | SQL statements such as `SELECT`, `UPDATE`, `CREATE USER`, `CALL`, `START TRANSACTION` |
| **Two MySQL prompts** | Only the two-session ACID walkthrough in `db/07_acid_demo.sql` |
| **Text editor** | Editing `web/config.local.php`; never put credentials in tracked files |

### Replace these values before executing

- `C:\\PharmaTrace360` means the folder containing this repository. Replace it with your actual checkout path.
- `REPLACE_WITH_...` values are placeholders, not working passwords/emails/certificates.
- Use strong, unique database passwords. Avoid saving passwords in tracked files or screenshots.
- A command that starts with `mysql -u root -p` asks for the MySQL root password; `-p` without a password is intentional.
- Run repository-relative file commands from the repository root, the directory that contains `db`, `web`, and `docs`.

### Risk labels

- **READ-ONLY:** does not intentionally change database data.
- **CHANGES DATA:** inserts or updates application data.
- **DESTRUCTIVE:** deletes/recreates the database or removes demo/test data.
- **BACKUP FIRST:** do not continue on an important database without a verified backup.

> **Most important rule:** `db/00_reset_all.sql` is destructive. It drops and rebuilds `pharmatrace360`, replaces seeded records, and removes local demo changes. Never run it on the only copy of a database whose data you need to keep.

---

## 1. Open the repository and verify installed tools

### 1.1 Open the project root

**Where:** Windows CMD.  
**Prerequisite:** Repository already cloned or downloaded.

~~~bat
cd /d C:\PharmaTrace360
~~~

Replace `C:\PharmaTrace360` with your actual path. If you already opened CMD in the repository root, skip this step.

### 1.2 Check MySQL client

**Where:** Windows CMD.

~~~bat
mysql --version
~~~

If Windows says the command is not recognized, add your MySQL Server `bin` folder to PATH or use the full executable path:

~~~bat
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" --version
~~~

### 1.3 Check PHP and PDO MySQL

**Where:** Windows CMD.

~~~bat
php -v
php -m | findstr /i pdo_mysql
~~~

The second command should print `pdo_mysql`. If it prints nothing, enable `extension=pdo_mysql` in the PHP `php.ini` and reopen CMD.

### 1.4 Check Python (optional)

~~~bat
python --version
~~~

Python is needed for seed generation and Python compile checks, not for normal PHP web use.

---

## 2. Install from scratch — fresh demo database

**Use this section only when creating a new local demo database or when you intentionally want to wipe and rebuild the demo.**

### 2.1 Create the three MySQL application accounts

**Where:** Windows CMD.  
**Prerequisite:** MySQL Server is running and you know the root password.  
**Changes:** Creates database accounts, not application users.

First open an interactive MySQL root session:

~~~bat
mysql -u root -p
~~~

At the `mysql>` prompt, paste the following after replacing each placeholder with a different strong password:

~~~sql
CREATE USER 'pt_public'@'localhost' IDENTIFIED BY 'REPLACE_WITH_STRONG_PUBLIC_DB_PASSWORD';
CREATE USER 'pt_app'@'localhost' IDENTIFIED BY 'REPLACE_WITH_STRONG_APP_DB_PASSWORD';
CREATE USER 'pt_setup'@'localhost' IDENTIFIED BY 'REPLACE_WITH_STRONG_SETUP_DB_PASSWORD';
EXIT;
~~~

If a user already exists, MySQL reports that it exists. Do not delete an existing account blindly; inspect it and decide whether to use `ALTER USER` instead.

**What each account is for**

- `pt_public`: anonymous QR-verification page; limited to the public verification procedure and demo-code view.
- `pt_app`: authenticated staff portal; business procedures and reporting views.
- `pt_setup`: only the CLI password bootstrap utility. Never use this account for a web page.

The SQL contains placeholder passwords; replace them before pasting. Do not reuse your MySQL root password for these accounts.

### 2.2 Build/reseed the database

**Where:** Windows CMD, from the repository root.  
**Prerequisite:** The database users can exist already; this step runs as MySQL root.  
**Risk:** **DESTRUCTIVE — DROPS AND RECREATES `pharmatrace360`.**

~~~bat
mysql -u root -p < db\00_reset_all.sql
~~~

The script calls, in order:

1. `db/01_schema.sql` — creates the database, 17 base tables, keys and constraints;
2. `db/02_seed.sql` — inserts master and synthetic demo data;
3. `db/03_logic.sql` — installs views, functions, triggers and stored procedures;
4. `db/06_suspicious_review.sql` — installs suspicious-review status and view/procedure support;
5. `db/05_grants.sql` — reapplies the `pt_public` and `pt_app` grants.

Wait for the script to finish and read any SQL errors before moving on.

### 2.3 Grant the CLI password-bootstrap account

**Where:** Windows CMD, from the repository root.  
**Prerequisite:** Step 2.2 has completed successfully and `pt_setup` was created in step 2.1.

~~~bat
mysql -u root -p < db\10_setup_grants.sql
~~~

This grants `EXECUTE` on `sp_set_password` to `pt_setup`. It does not grant this routine to `pt_app`.

### 2.4 Create the local PHP configuration

**Where:** Windows CMD, from the repository root.  
**Prerequisite:** None; do this once per checkout.

~~~bat
copy web\config.sample.php web\config.local.php
notepad web\config.local.php
~~~

In the copied file, enter the passwords you created for `pt_public`, `pt_app`, and `pt_setup`. Check the database host, port, database name, and charset. The expected local defaults are host `127.0.0.1`, port `3306`, database `pharmatrace360`, charset `utf8mb4`.

Set `DEMO_MODE` to `true` only when you want the public page to show representative demo QR codes. Keep `config.local.php` local; it is ignored by Git.

**If the file already exists:** do not run `copy` over it without first preserving your working configuration.

### 2.5 Set passwords for seeded staff accounts

**Where:** Windows CMD, from the repository root.  
**Prerequisites:** Steps 2.1–2.4 completed, and `pt_setup` credentials are correct in `web/config.local.php`.

~~~bat
php web\tools\set_password.php
~~~

The tool asks for the user's email and a new password of at least 10 characters, hashes the password with PHP's `password_hash()`, and calls `sp_set_password` through the setup-only connection. Repeat it for each account you need.

Demo emails seeded in the database:

- `priya.admin@demo.test` — Admin/Regulator
- `rahul.mfr@demo.test` — Manufacturer (Cipla Ltd)
- `anjali.mfr@demo.test` — Manufacturer (Alkem Laboratories Ltd)
- `vikram.mfr@demo.test` — Manufacturer (Alembic Pharmaceuticals Ltd)

**Windows input note:** the current CLI tool warns that the password can be visible while typing in a Windows console. Run it in a private local terminal, do not record the screen, and do not paste real passwords into chat, tickets, or logs.

### 2.6 Start the PHP site

**Where:** Windows CMD, from the repository root.  
**Prerequisites:** Database installed, local config valid, PHP and `pdo_mysql` working.

~~~bat
php -S localhost:8000 -t web/public
~~~

Keep that terminal open while using the site. Visit:

- Public QR verification: http://localhost:8000/
- Staff login: http://localhost:8000/login.php

Stop the server with **Ctrl+C** in the terminal where it is running.

This PHP built-in server is for local development/demo only; do not expose it as a production Internet-facing server.

---

## 3. Existing database — upgrade without reseeding

**Use this when you already have a working `pharmatrace360` database and want to preserve its rows. Do not run section 2.2 first.**

### 3.1 Take a backup first

Create the backup directory if necessary, then write to a new filename so you do not overwrite an earlier backup:

~~~bat
if not exist backups mkdir backups
mysqldump -u root -p --routines --triggers --events --single-transaction pharmatrace360 > backups\pharmatrace360_before_upgrade.sql
~~~

Check that the file exists and is non-empty before proceeding. If your MySQL version/permissions report a dump error, stop and resolve it before upgrading.

### 3.2 Run the non-destructive upgrade

**Where:** Windows CMD, from the repository root.  
**Prerequisite:** A verified backup.  
**Changes:** Adds the recall issuance timestamp/indexes and FK rules as required, recreates routines/views, and reapplies grants; it does not drop/reseed all application rows.

~~~bat
mysql -u root -p < db\09_upgrade_existing.sql
~~~

The upgrade intentionally stops if duplicate non-NULL certificate numbers prevent the uniqueness constraint. It does not delete those deliveries for you.

### 3.3 If the upgrade reports duplicate certificate numbers

**Where:** CMD. This is a read-only report.

~~~bat
mysql -u root -p pharmatrace360 -e "SELECT certificate_number, COUNT(*) AS copies FROM Material_Deliveries WHERE certificate_number IS NOT NULL GROUP BY certificate_number HAVING COUNT(*) > 1;"
~~~

Investigate each duplicate using the source paperwork. Do not invent new certificate values merely to make the command pass. After the records are legitimately resolved and the backup verified, run step 3.2 again.

### 3.4 Reapply setup-account permission if needed

After a routine/schema upgrade, ensure `pt_setup` exists and its password matches the local configuration, then run:

~~~bat
mysql -u root -p < db\10_setup_grants.sql
~~~

The upgrade script reapplies the normal `pt_public` and `pt_app` grants; `pt_setup` is separate by design.

---

## 4. Database inspection — read-only commands

### 4.1 Open a database prompt

~~~bat
mysql -u root -p pharmatrace360
~~~

Paste the SQL in the following subsections at the `mysql>` prompt. Finish with `EXIT;` to leave the client.

### 4.2 Check tables and views

**READ-ONLY**

~~~sql
SHOW FULL TABLES;
SHOW TABLES;
~~~

### 4.3 Check application users, emails, roles and active status

**READ-ONLY.** This query does not return password hashes.

~~~sql
SELECT u.user_id, u.full_name, u.email, r.role_name,
       u.manufacturer_id, u.is_active, u.created_at
FROM Users AS u
JOIN Roles AS r ON r.role_id = u.role_id
ORDER BY u.user_id;
~~~

### 4.4 Check counts for core tables

**READ-ONLY**

~~~sql
SELECT 'Users' AS table_name, COUNT(*) AS row_count FROM Users
UNION ALL SELECT 'Manufacturers', COUNT(*) FROM Manufacturers
UNION ALL SELECT 'Factories', COUNT(*) FROM Factories
UNION ALL SELECT 'Suppliers', COUNT(*) FROM Suppliers
UNION ALL SELECT 'Ingredients', COUNT(*) FROM Ingredients
UNION ALL SELECT 'Material_Deliveries', COUNT(*) FROM Material_Deliveries
UNION ALL SELECT 'Medicines', COUNT(*) FROM Medicines
UNION ALL SELECT 'Production_Batches', COUNT(*) FROM Production_Batches
UNION ALL SELECT 'Batch_Materials', COUNT(*) FROM Batch_Materials
UNION ALL SELECT 'Quality_Test_Reports', COUNT(*) FROM Quality_Test_Reports
UNION ALL SELECT 'QR_Codes', COUNT(*) FROM QR_Codes
UNION ALL SELECT 'Scan_Log', COUNT(*) FROM Scan_Log
UNION ALL SELECT 'Product_Recalls', COUNT(*) FROM Product_Recalls
UNION ALL SELECT 'Audit_Logs', COUNT(*) FROM Audit_Logs;
~~~

Counts change when you use the application, run demos, or run feature tests. Do not treat a changing count as a failure without checking which operations were performed.

### 4.5 Check stored procedures and functions

**READ-ONLY**

~~~sql
SELECT ROUTINE_TYPE, ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'pharmatrace360'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;
~~~

### 4.6 Check installed grants

**READ-ONLY**

~~~sql
SHOW GRANTS FOR 'pt_public'@'localhost';
SHOW GRANTS FOR 'pt_app'@'localhost';
SHOW GRANTS FOR 'pt_setup'@'localhost';
~~~

If an account has not been created, its `SHOW GRANTS` command will fail for that account. Do not respond by granting global `ALL PRIVILEGES`; use the project's specific grant scripts.

### 4.7 Inspect batch status and QR totals

**READ-ONLY**

~~~sql
SELECT * FROM v_batch_overview ORDER BY batch_number;
SELECT * FROM v_batch_status_counts;
~~~

### 4.8 Inspect suspicious scans

**READ-ONLY**

~~~sql
SELECT scanned_code, scan_count, first_scan, last_scan, review_status
FROM v_suspicious_codes
ORDER BY scan_count DESC, last_scan DESC;
~~~

The view shows codes with more than 10 scans during the rolling 48-hour window. It can be empty on a clean database.

### 4.9 Inspect recent audit events

**READ-ONLY**

~~~sql
SELECT * FROM v_recent_audit;
~~~

### 4.10 Inspect recalls

**READ-ONLY**

~~~sql
SELECT recall_id, batch_number, medicine, manufacturer, reason,
       recall_date, qr_count, total_scans, scans_after_recall
FROM v_recall_list
ORDER BY recall_date DESC;
~~~

### 4.11 Inspect one user's account by email

**READ-ONLY**

~~~sql
SELECT u.user_id, u.full_name, u.email, r.role_name,
       u.manufacturer_id, u.is_active
FROM Users u
JOIN Roles r ON r.role_id = u.role_id
WHERE u.email = 'priya.admin@demo.test';
~~~

Replace the example email with the exact email to find. Do not query or copy password hashes for routine account inspection.

---

## 5. Password operations

### 5.1 Set/reset a staff password (recommended method)

**Where:** Windows CMD, repository root.  
**Prerequisite:** `web/config.local.php` has valid `pt_setup` credentials and the `pt_setup` grant has been installed.

~~~bat
php web\tools\set_password.php
~~~

At the prompts, enter the target user's current email and the new password. The tool requires at least 10 characters. Run it once per user.

### 5.2 Change your own password while logged in

1. Sign in at http://localhost:8000/login.php.
2. Open **Change Password** in the staff navigation.
3. Enter the current password, new password, and confirmation.

This uses the `sp_change_password` procedure after the current password is verified. Do not use a direct SQL UPDATE to store a plaintext password.

### 5.3 If the password tool says it cannot connect

Check, in this order:

1. MySQL Server is running and responds to `mysql -u root -p`.
2. `web/config.local.php` contains the correct local database host/port/name.
3. `db.setup.user` is `pt_setup`, and its password matches the account created in MySQL.
4. `db/10_setup_grants.sql` completed successfully.
5. The database and routine exist: at the MySQL prompt run `USE pharmatrace360; SHOW PROCEDURE STATUS WHERE Db='pharmatrace360' AND Name='sp_set_password';`.

Do not grant `sp_set_password` to `pt_app` as a shortcut.

---

## 6. Email, account role and active status

There is **no staff-account creation or email-edit screen** in the current UI. Use an administrative MySQL session for controlled account maintenance. Back up first if changing an account used by other staff.

### 6.1 Change a user's login email

**Where:** MySQL prompt as a privileged administrator.  
**Changes:** Updates the login identifier. The new email must be unique. The user must log in with the new email after the change.

First inspect the current account:

~~~sql
SELECT user_id, full_name, email, is_active
FROM Users
WHERE email = 'OLD_EMAIL@example.test';
~~~

Then perform the update in a transaction, replacing both email values:

~~~sql
START TRANSACTION;

UPDATE Users
SET email = 'NEW_EMAIL@example.test'
WHERE email = 'OLD_EMAIL@example.test';

SELECT ROW_COUNT() AS rows_changed;

SELECT user_id, full_name, email, is_active
FROM Users
WHERE email = 'NEW_EMAIL@example.test';

COMMIT;
~~~

**Check the output before committing if you paste interactively:** expect exactly one changed row and verify the new email belongs to the intended account. If the UPDATE fails or the account is not the expected one, run `ROLLBACK;` instead of `COMMIT;`. If the new email already exists, choose a genuinely unique address rather than disabling the unique index.

If you also need to reset the user's password, run section 5.1 using the **new email** after the email update is committed.

### 6.2 Disable a staff account

**Changes:** Prevents that account from using protected pages after session revalidation. Use only when you are authorized to deactivate it.

~~~sql
START TRANSACTION;
UPDATE Users
SET is_active = 0
WHERE email = 'USER_TO_DISABLE@example.test';
SELECT ROW_COUNT() AS rows_changed;
SELECT user_id, full_name, email, is_active
FROM Users
WHERE email = 'USER_TO_DISABLE@example.test';
COMMIT;
~~~

Verify that exactly one intended row was changed. If not, roll back before committing.

### 6.3 Re-enable a staff account

~~~sql
START TRANSACTION;
UPDATE Users
SET is_active = 1
WHERE email = 'USER_TO_ENABLE@example.test';
SELECT ROW_COUNT() AS rows_changed;
SELECT user_id, full_name, email, is_active
FROM Users
WHERE email = 'USER_TO_ENABLE@example.test';
COMMIT;
~~~

Verify exactly one intended row. A disabled account should still use the CLI password tool if its password also needs resetting.

### 6.4 Change role/company association

Role and manufacturer association affect authorization and data ownership. Do not paste a generic role-changing UPDATE into a live database. First inspect valid role IDs and manufacturer IDs:

~~~sql
SELECT role_id, role_name FROM Roles ORDER BY role_id;
SELECT manufacturer_id, company_name FROM Manufacturers ORDER BY manufacturer_id;
~~~

Make this change only with a clear authorization decision. A Manufacturer account needs a valid manufacturer association; an Admin/Regulator account normally has no manufacturer association. After any role change, sign out and sign back in so the session uses the new role.

### 6.5 Add a new staff account

The web UI does not provide account creation. For this demo, use a privileged database administrator and confirm the role/manufacturer relationship before inserting. Never insert a plaintext password.

1. Inspect valid roles and manufacturers with section 6.4.
2. Generate a PHP password hash locally using a private terminal. This quick example prompts for input but terminal visibility depends on the shell; do not record the screen:

~~~bat
php -r "$p = trim(fgets(STDIN)); echo password_hash($p, PASSWORD_DEFAULT), PHP_EOL;"
~~~

Type the new password and press Enter. Copy the resulting hash locally; do not share it or commit it.
3. Insert the account in MySQL, replacing all placeholder values. For a Manufacturer, use that manufacturer's numeric ID; for Admin/Regulator, use SQL `NULL`.

~~~sql
INSERT INTO Users
    (full_name, email, password_hash, role_id, manufacturer_id, is_active)
VALUES
    ('REPLACE_WITH_FULL_NAME',
     'NEW_USER@example.test',
     'PASTE_THE_PHP_PASSWORD_HASH_HERE',
     (SELECT role_id FROM Roles WHERE role_name = 'Manufacturer'),
     REPLACE_WITH_MANUFACTURER_ID,
     1);
~~~

This example is for a Manufacturer and requires replacing `REPLACE_WITH_MANUFACTURER_ID` with a valid numeric ID (no quotes). For an Admin/Regulator account, change the role lookup to `'Admin/Regulator'` and use `NULL` for `manufacturer_id`. Ensure the email is unique and inspect the resulting row before allowing login.

---

## 7. Common application workflows

Most normal operations should be performed through the staff portal so the app's session/role checks, procedures, triggers and audit logging are used together. Avoid inserting operational records directly into tables.

### 7.1 Record a raw-material delivery

1. Sign in as a Manufacturer.
2. Open **Deliveries**.
3. Choose the existing supplier and ingredient.
4. Enter quantity in kg, received date, and a unique CoA/certificate number.
5. Submit and confirm the delivery appears in the inventory table.

Database equivalent: `CALL sp_record_delivery(...)`. Its exact parameter order is visible in `db/03_logic.sql`; use the UI for normal use because it supplies the current user identity and validates the form.

### 7.2 Create a production batch

1. Sign in as the owning Manufacturer.
2. Open **New Batch**.
3. Enter a unique batch number, medicine, factory, quantity, manufacture date and expiry date.
4. Submit and open the new Pending batch.

Database equivalent: `sp_create_batch`. The medicine and factory must be associated with the same manufacturer.

### 7.3 Link a delivery to a batch

1. Open the Pending batch detail page.
2. Add a delivery that belongs to the same manufacturer and contains an ingredient required by the medicine formulation.
3. Enter the quantity used.
4. Check the remaining delivery balance.

Do not over-allocate a delivery. The database checks the combined allocations, not just the value in the current form.

### 7.4 Record QA

1. Open the Pending batch.
2. Enter purity, dissolution and weight variation in the accepted 0–100 range.
3. Select Pass or Fail and provide remarks.
4. Confirm the report appears in the batch timeline/history.

The label is submitted by the operator; the project does not calculate regulatory pass/fail thresholds from those measurements.

### 7.5 Approve a batch and issue QR codes

1. Ensure the latest QA report is Pass.
2. Ensure at least one eligible raw-material delivery is linked.
3. Open the batch detail page and use the approval action.
4. Enter a pack count from 1 to 50 that does not exceed the recorded production quantity.
5. Print/view the QR sheet after approval.

Approval and QR issuance are a single transactional operation. A repeated approval of an already Approved batch should be rejected.

### 7.6 Reject a batch

A Manufacturer can reject a Pending batch only if the latest QA result is Fail. Use the reject action from the batch detail page.

### 7.7 Issue a recall

1. Sign in as Admin/Regulator.
2. Open **Recall**.
3. Enter the exact batch number and a clear reason.
4. Submit and confirm the batch status is Recalled.
5. Open **Recalls** to inspect the recall record and post-recall scan metrics.

A batch can be recalled only once in this model. A recalled batch cannot be transitioned back to Approved.

### 7.8 Review a suspicious code

1. Sign in as Admin/Regulator.
2. Open **Suspicious Scans**.
3. Choose New, Reviewed, or Blocked for the listed code.
4. Save and refresh to confirm the analyst status persists.

**Important:** Blocked is an analyst review label; it does not independently add a block rule to the public verification verdict.

### 7.9 Change password while logged in

Use **Change Password** in the staff portal. The current password is verified before the new hash is stored.

---

## 8. SQL commands and safe query patterns

### 8.1 Run the 14 SELECT-only demonstration queries

**READ-ONLY.** Run from the repository root:

~~~bat
mysql -u root -p < db\06_queries.sql
~~~

This script demonstrates joins, aggregation, subqueries, views and other DBMS concepts. It does not intentionally change data.

### 8.2 Run the demo script

**CHANGES DATA / DEMO STATE.** Read `db/04_demo.sql` before running; it includes operational demonstrations and may insert/change demo events.

~~~bat
mysql -u root -p < db\04_demo.sql
~~~

Use only on a demo database. If you need a pristine demo afterward, back up anything you need and intentionally reset the demo database.

### 8.3 ACID demonstration

**Designed to leave the demo dataset unchanged when followed as written.** It is a two-session exercise, not a normal one-command import.

~~~bat
mysql -u root -p pharmatrace360
~~~

Open two separate CMD windows and run the same command in each. Follow `db/07_acid_demo.sql` comments in order: `[A]` commands in Session A, `[B]` commands in Session B, `[NOTE]` are explanations. Do not paste all the file into one session; the point is to observe transaction isolation between sessions.

### 8.4 Feature/integrity regression tests

**CHANGES DATA and deliberately raises SQL errors for negative tests. BACKUP FIRST. Use a disposable database only.**

The `-f` flag tells the mysql CLI to continue after expected SQL errors:

~~~bat
mysql -u root -p -f < db\08_feature_tests.sql
~~~

Read the output, including each expected rejection. A printed SQL error is not automatically a test failure: negative tests intentionally verify that the database rejects invalid operations. Do not run this script against a database containing data you need. After the tests, rebuild the disposable demo database if you want to restore the seed state.

### 8.5 Call the public verification procedure manually

**CHANGES DATA:** every call logs a scan. Use an unknown test code only on a demo database.

~~~sql
USE pharmatrace360;
CALL sp_verify_scan('PT360-REPLACE_WITH_A_TEST_CODE');
~~~

The procedure may return multiple result sets. MySQL Workbench or the CLI can show multiple result sets; if using PHP PDO, consume/close the cursor as the application does.

### 8.6 Check verdicts without recording a new scan

**READ-ONLY**

~~~sql
USE pharmatrace360;
SELECT qr.code, pb.batch_number, pb.status, pb.expiry_date,
       fn_qr_verdict(qr.code) AS current_verdict
FROM QR_Codes qr
JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
ORDER BY pb.batch_number, qr.code
LIMIT 50;
~~~

This evaluates the current verdict for stored codes without adding a new Scan_Log event.

### 8.7 Check one batch and its latest QA

**READ-ONLY**

~~~sql
SELECT pb.batch_number, pb.status, pb.quantity_units,
       qtr.test_date, qtr.purity_pct, qtr.dissolution_pct,
       qtr.weight_variation_pct, qtr.result, qtr.remarks
FROM Production_Batches pb
LEFT JOIN Quality_Test_Reports qtr ON qtr.batch_id = pb.batch_id
WHERE pb.batch_number = 'BT-2026-001'
ORDER BY qtr.test_date DESC, qtr.report_id DESC;
~~~

Replace the example batch number with the batch to inspect.

### 8.8 Check material allocation against delivery quantity

**READ-ONLY**

~~~sql
SELECT md.delivery_id, md.certificate_number, i.ingredient_name,
       md.quantity_kg AS delivered_kg,
       COALESCE(SUM(bm.quantity_used_kg), 0) AS allocated_kg,
       md.quantity_kg - COALESCE(SUM(bm.quantity_used_kg), 0) AS remaining_kg
FROM Material_Deliveries md
JOIN Ingredients i ON i.ingredient_id = md.ingredient_id
LEFT JOIN Batch_Materials bm ON bm.delivery_id = md.delivery_id
GROUP BY md.delivery_id, md.certificate_number, i.ingredient_name, md.quantity_kg
ORDER BY md.delivery_id;
~~~

### 8.9 Find QA reports that do not match the current batch state

**READ-ONLY review query**

~~~sql
SELECT pb.batch_number, pb.status, qtr.test_date, qtr.result
FROM Production_Batches pb
JOIN Quality_Test_Reports qtr ON qtr.batch_id = pb.batch_id
ORDER BY pb.batch_number, qtr.test_date DESC, qtr.report_id DESC;
~~~

This lists history for manual review; it does not define new acceptance thresholds.

---

## 9. Build or refresh seed data

### 9.1 Rebuild `db/02_seed.sql` from the checked-in clean CSV

**CHANGES A TRACKED SOURCE FILE.** Use a clean Git working tree or commit/stash existing edits first.

~~~bat
python db\build_seed.py
git diff -- db\02_seed.sql
~~~

The builder reads `data/clean/medicines_15.csv` and writes `db/02_seed.sql`. Review the diff before using the generated SQL. Regenerating seed SQL does not change the database until you run the seed/reset script.

### 9.2 Rebuild the clean 15-medicine CSV from the raw datasets

**Optional; requires two source files not included in the repository. Changes `data/clean/medicines_15.csv`.**

Prerequisite input files:

- `data/raw/Extensive_A_Z_medicines_dataset_of_India.csv`
- `data/raw/medicine_data.csv`

Obtain the source datasets from their original providers and verify licence/usage terms first. Then, from the repository root:

~~~bat
python data\clean\build_medicines_15.py
git diff -- data\clean\medicines_15.csv
~~~

If either raw CSV is missing or a required medicine target cannot be found, the builder should fail. Inspect the output and report before committing the changed CSV.

### 9.3 Rebuild database from regenerated seed

**DESTRUCTIVE.** Only do this on a disposable/fresh demo database, after backing up anything important and reviewing the generated seed diff.

~~~bat
mysql -u root -p < db\00_reset_all.sql
~~~

The reset uses the currently checked-in seed SQL. It does not regenerate the seed automatically.

---

## 10. Backup and restore

### 10.1 Back up the database

**READS DATABASE; WRITES A LOCAL FILE.**

~~~bat
if not exist backups mkdir backups
mysqldump -u root -p --routines --triggers --events --single-transaction pharmatrace360 > backups\pharmatrace360_manual_backup.sql
~~~

If the filename already exists, rename or choose a new filename before running; CMD redirection overwrites the target. Keep backups out of Git and store them securely because they may contain personal data, account emails, password hashes, scan history and operational data.

### 10.2 Verify that a backup file exists

~~~bat
dir backups\pharmatrace360_manual_backup.sql
~~~

A file existing is not proof of a valid backup. Read the `mysqldump` output, verify a plausible non-zero file size, and periodically test restore into a separate disposable database.

### 10.3 Restore a dump (DESTRUCTIVE to target database)

**Do not run against the only copy of important data.** Confirm the dump and target database first. A dump created with the command above may include database creation statements depending on its content/options; inspect it before choosing the target.

~~~bat
mysql -u root -p pharmatrace360 < backups\pharmatrace360_manual_backup.sql
~~~

This can overwrite records and schema in the target database. Prefer testing the restore against an isolated disposable MySQL instance or a separate test database, and ensure the dump's database statements target the intended database before running.

### 10.4 Restore only after confirming the target

For a safe rehearsal, create a separate database and inspect the dump before importing. The project's schema script is hard-wired to the database name `pharmatrace360`, so a clean-room restore into a different database name may require a carefully reviewed SQL transformation. Do not blindly search-and-replace the database name in a dump and then run it on a live server.

---

## 11. Logs and troubleshooting

### 11.1 PHP server logs

PHP's built-in server writes request and runtime messages to the CMD terminal that started it. Keep that window open and inspect it if a page fails. Do not paste passwords, config contents, or database dumps into public bug reports.

### 11.2 Database connection fails

Run these checks in order:

~~~bat
mysql --version
php -v
php -m | findstr /i pdo_mysql
~~~

Then try logging into MySQL:

~~~bat
mysql -u root -p -e "SELECT VERSION();"
~~~

If root login works but the web app fails, check `web/config.local.php`, MySQL service state, account host (`localhost` versus `127.0.0.1`), passwords and grants. Do not switch the web application to root credentials as a workaround.

### 11.3 A page says a procedure or view is missing

**READ-ONLY check**

~~~bat
mysql -u root -p pharmatrace360 -e "SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='pharmatrace360' ORDER BY ROUTINE_TYPE, ROUTINE_NAME;"
~~~

Then check views:

~~~bat
mysql -u root -p pharmatrace360 -e "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='pharmatrace360' ORDER BY TABLE_NAME;"
~~~

For an existing installation, take a backup and run section 3.2. Do not run the destructive reset merely to repair a missing routine.

### 11.4 An application user cannot perform an action

Check the user's active status and role with section 4.3, and verify batch ownership, status, QA result and material allocations. The application intentionally rejects operations that violate the workflow. Do not bypass it by inserting directly into QR_Codes or changing batch status manually.

### 11.5 Duplicate certificate error during upgrade

Use the duplicate query in section 3.3. Investigate the source records and resolve duplicate identifiers with the business owner. The unique index is meant to enforce data integrity, not to delete duplicate rows automatically.

### 11.6 Reset is blocked or SQL errors appear

Read the first error in the MySQL output and the script comments. If a command was run from the wrong directory, `SOURCE db/...` may not resolve; `cd` to the repository root and retry only if it is safe to do so. Do not rerun a partially completed destructive reset against important data; restore from a verified backup or use a disposable environment.

---

## 12. Code quality and CI commands

### 12.1 PHP syntax lint

**READ-ONLY**

~~~bat
for /r web %f in (*.php) do @php -l "%f"
~~~

Run directly in interactive CMD. In a `.bat` file, use `%%f` instead of `%f`.

### 12.2 Python syntax compilation

**Writes cache files under ignored `__pycache__` directories.**

~~~bat
python -m compileall db data\clean
~~~

### 12.3 Git whitespace/diff review

~~~bat
git status --short
git diff --check
git diff
~~~

### 12.4 Check GitHub Actions

Open the repository's **Actions** tab and select the run for the commit you want to validate. A queued run is not a pass; inspect all jobs and logs. The SQL feature suite intentionally produces errors for negative tests, so its log must be interpreted against the test expectations.

---

## 13. Quick command index

| Action | Command / destination | Data risk |
|---|---|---|
| Fresh demo install | `mysql -u root -p < db\00_reset_all.sql` | **DESTRUCTIVE** |
| Existing database upgrade | `mysql -u root -p < db\09_upgrade_existing.sql` | Backup first; preserves rows |
| Apply staff/public grants | `mysql -u root -p < db\05_grants.sql` | Changes privileges |
| Grant CLI password tool | `mysql -u root -p < db\10_setup_grants.sql` | Changes privileges |
| Set/reset seeded user's password | `php web\tools\set_password.php` | Changes credential |
| Start local site | `php -S localhost:8000 -t web/public` | No DB mutation by itself |
| Run read-only SQL examples | `mysql -u root -p < db\06_queries.sql` | Read-only |
| Run stateful demo | `mysql -u root -p < db\04_demo.sql` | Changes demo state |
| Run regression suite | `mysql -u root -p -f < db\08_feature_tests.sql` | **Changes data** |
| Back up DB | `mysqldump -u root -p --routines --triggers --events --single-transaction pharmatrace360 > backups\pharmatrace360_manual_backup.sql` | Writes local backup |
| Build seed SQL | `python db\build_seed.py` | Changes tracked SQL file |
| Lint PHP | `for /r web %f in (*.php) do @php -l "%f"` | Read-only |
| Compile Python | `python -m compileall db data\clean` | Writes ignored cache |

If an operation isn't listed here, check [README.md](README.md), [docs/SETUP.md](docs/SETUP.md), [docs/known_limitations.md](docs/known_limitations.md), and the comments at the top of the relevant SQL file before improvising a command.
