# PharmaTrace 360 - Web Application

This directory contains the PHP web frontend for **PharmaTrace 360**.

---

## 1. Initial Setup

### Step 1: Create your local configuration file
Copy the sample configuration file [web/config.sample.php](file:///e:/DBMS/PharmaTrace360/web/config.sample.php) to `web/config.local.php`:

```cmd
copy web\config.sample.php web\config.local.php
```

### Step 2: Configure your database credentials
Open `web/config.local.php` in your text editor and update your database credentials.
The application uses two least-privilege database connections:
- `public`: Uses MySQL user `pt_public` (only can call `sp_verify_scan` and read `v_demo_codes`).
- `app`: Uses MySQL user `pt_app` (can execute business stored procedures and read views, zero table access).

```php
return [
    'db' => [
        'host'    => '127.0.0.1',
        'port'    => 3306,
        'dbname'  => 'pharmatrace360',
        'charset' => 'utf8mb4',

        // pt_public: anonymous scan portal
        'public' => [
            'user'     => 'pt_public',
            'password' => 'YOUR_PT_PUBLIC_PASSWORD',
        ],

        // pt_app: staff portal (procedures + views only)
        'app' => [
            'user'     => 'pt_app',
            'password' => 'YOUR_PT_APP_PASSWORD',
        ],
    ],
    // Set to true to display sample QR codes on the public portal
    'DEMO_MODE' => true,
];
```

> [!NOTE]
> `web/config.local.php` and `web/logs/` are ignored by git in `.gitignore`. Your credentials and error logs will never be committed.

### Step 3: Set passwords for demo users
Seed data creates demo users without active passwords. Use the CLI tool [web/tools/set_password.php](file:///e:/DBMS/PharmaTrace360/web/tools/set_password.php) to set passwords:

```cmd
php web\tools\set_password.php
```

Demo user accounts in seed data:
- `priya.admin@demo.test` (Admin/Regulator)
- `rahul.mfr@demo.test` (Manufacturer - Cipla Ltd)
- `anjali.mfr@demo.test` (Manufacturer - Alkem Laboratories Ltd)
- `vikram.mfr@demo.test` (Manufacturer - Alembic Pharmaceuticals Ltd)

---

## 2. Starting the Web Server

From the project root directory (`E:\DBMS\PharmaTrace360`), run PHP's built-in web server:

```cmd
php -S localhost:8000 -t web/public
```

Open your browser and navigate to:
- Public Verification Portal: [http://localhost:8000](http://localhost:8000)
- Staff Login: [http://localhost:8000/login.php](http://localhost:8000/login.php)

### Phone Scanning Over Local Wi-Fi

To scan QR codes directly with your mobile phone camera during testing:

1. **Find your PC's local network IPv4 address:**
   Open Command Prompt or PowerShell and run `ipconfig`. Find your active Wi-Fi or Ethernet adapter's **IPv4 Address** (e.g. `192.168.1.50`).

2. **Configure `PUBLIC_BASE_URL` in `web/config.local.php`:**
   Update the `PUBLIC_BASE_URL` setting with your PC's IP address so generated QR codes point to your network machine:
   ```php
   'PUBLIC_BASE_URL' => 'http://<PC network address>:8000',
   // Example:
   // 'PUBLIC_BASE_URL' => 'http://192.168.1.50:8000',
   ```

3. **Start PHP bound to all interfaces:**
   Start the built-in server listening on `0.0.0.0` instead of `localhost`:
   ```cmd
   php -S 0.0.0.0:8000 -t web/public
   ```

4. **Allow PHP through Windows Firewall:**
   Ensure Windows Defender Firewall allows incoming connections to PHP on **Private networks**:
   - When Windows prompts you on first launch, check **Private networks** and click **Allow access**.
   - Or manually allow TCP port `8000` for private networks in *Windows Defender Firewall with Advanced Security* (Inbound Rules).

5. **Scan with your phone on the same Wi-Fi:**
   - Connect your phone to the same Wi-Fi network as your PC.
   - Open batch details ([http://localhost:8000/app/batch_detail.php](http://localhost:8000/app/batch_detail.php)) or the printable sheet ([http://localhost:8000/app/qr_sheet.php](http://localhost:8000/app/qr_sheet.php)) on your PC.
   - Point your phone camera or QR reader at any displayed QR code.
   - Tap the detected URL (`http://<PC network address>:8000/?code=...`) to immediately verify the medicine on your mobile browser.

---

## 3. Roles & Permissions

Permissions are enforced at **two independent layers**:
1. **Database Layer (MySQL):** Least privilege via dedicated users (`pt_public`, `pt_app`), stored procedures, and MySQL `GRANT` statements. Users have zero direct access to underlying tables.
2. **Web Application Layer (PHP):** Session authentication, role guards (`requireRole()`), 30-minute idle timeouts, and per-form CSRF verification tokens.

| Role | MySQL User | Database Permissions | Web Capabilities & Enforcement |
|---|---|---|---|
| **Public Visitor** | `pt_public` | `EXECUTE` on `sp_verify_scan`<br>`SELECT` on `v_demo_codes` | Anonymous access to `index.php`. Can scan QR codes and view consumer drug information. No login credentials exist. |
| **Manufacturer** | `pt_app` | `EXECUTE` on `sp_record_delivery`, `sp_create_batch`, `sp_add_batch_material`, `sp_record_test`, `sp_approve_batch`, `sp_reject_batch`, `sp_change_password`<br>`SELECT` on views (`v_batch_overview`, `v_batch_traceability`, `v_batch_tests`, `v_batch_qr_codes`, `v_form_suppliers`, `v_form_ingredients`, `v_form_medicines`, `v_form_factories`, `v_my_deliveries`, `v_batch_timeline`) | Authenticates via `login.php`. Accesses `/app/batches.php`, `/app/deliveries.php`, `/app/batch_new.php`, `/app/batch_detail.php` (including vertical lifecycle timeline), and `/app/change_password.php`. Filtered strictly to their company's batches (`fn_user_can_manage_batch` prevents cross-tenant actions). |
| **Admin / Regulator** | `pt_app` | `EXECUTE` on `sp_issue_recall`, `sp_log_event`, `sp_login_lookup`<br>`SELECT` on views (`v_dashboard`, `v_batch_status_counts`, `v_batch_overview`, `v_suspicious_codes`, `v_recent_audit`, `v_recall_list`, `v_batch_timeline`) | Authenticates via `login.php`. Accesses executive dashboard (`/app/dashboard.php`), all batches (`/app/all_batches.php`), suspicious scans (`/app/suspicious.php`), audit trail (`/app/audit.php`), issue recall (`/app/recall.php`), recall monitor (`/app/recalls.php`), and `/app/change_password.php`. |

---

## 4. Live Manufacturer Production & Traceability Flow

A fully validated, interactive production lifecycle is available for Manufacturer accounts:

1. **Record Raw Material Delivery (`/app/deliveries.php`):**
   - Navigate to **Deliveries** from the top header navigation.
   - Fill in the **Record Inbound Delivery** form: choose qualified supplier from `v_form_suppliers`, raw ingredient from `v_form_ingredients`, quantity in kg, received date, and unique Certificate of Analysis (CoA) number.
   - Calls `sp_record_delivery` with full transactional integrity and database rule validation.
   - The delivery appears immediately under **Company Delivery Inventory** with live balance tracking (`quantity_kg`, `used_kg`, `remaining_kg`).

2. **Initialize New Batch (`/app/batch_new.php`):**
   - Click **New batch** in the navigation header.
   - Specify batch number, registered brand medicine (from `v_form_medicines`), manufacturing facility (from `v_form_factories`), production quantity, manufacture date, and expiry date.
   - Calls `sp_create_batch` to create the batch in **Pending** status and redirects directly to `/app/batch_detail.php?batch=<batch_number>`.

3. **Link Certified Materials (`/app/batch_detail.php`):**
   - Under **Link Active Raw Material**, choose from the manufacturer's available inbound deliveries (`v_my_deliveries`) displaying remaining balance.
   - Enter consumed quantity in kg. Calls `sp_add_batch_material` to attach supply chain provenance.

4. **Perform QA Testing & Batch Approval (`/app/batch_detail.php`):**
   - Submit laboratory quality assurance parameters (purity %, dissolution %, weight variation %) and mark as `Pass` via `sp_record_test`.
   - Once tested and linked, approve the batch with target pack count (1–50) via `sp_approve_batch`.
   - The batch transitions to **Approved**, generating serialized QR codes ready for printing (`/app/qr_sheet.php`) and public verification.

5. **Batch Lifecycle History (`/app/batch_detail.php` — History section):**
   - All authenticated users with batch access see a **Batch Lifecycle History** vertical timeline at the bottom of the batch detail page.
   - Reads `v_batch_timeline` ordered by `event_time ASC`.
   - Each event type renders with a distinct badge colour and SVG icon: `BATCH_MANUFACTURED` (blue), `MATERIAL_RECEIVED` (cyan), `MATERIAL_LINKED` (grey), `QA_TEST` (yellow), `QR_ISSUED` (green), `STATUS_Approved` (green), `STATUS_Recalled` / `RECALL_ISSUED` (red), `STATUS_Rejected` (dark).

---

## 5. Account Security

### Change Password (`/app/change_password.php`)

Available to **every authenticated user** (Manufacturer and Admin/Regulator) via the **"Change password"** link in the top navigation bar.

1. User enters their **current password**, **new password** (minimum 10 characters), and **confirm new password**.
2. The PHP page calls `sp_login_lookup` with the session email and verifies the result with `password_verify()`.
3. If correct, the new password is hashed with `password_hash($pw, PASSWORD_DEFAULT)` (bcrypt) and stored via `sp_change_password(user_id, hash)`.
4. **Plaintext passwords are never logged, printed, or stored.**
5. Any validation failure (wrong current password, length < 10, mismatch, DB error) shows an identical generic message to prevent enumeration.

---

## 6. Recall Monitor (`/app/recalls.php`)

Accessible to **Admin/Regulator** only. Linked from:
- The **"Recalls"** link in the top navigation bar.
- The **"Recalled Batches Monitor"** entry in the Regulatory Operations list on the Dashboard.
- The **Product Recalls KPI card** on the Dashboard (card is now a clickable link).

Displays:
- **KPI summary cards**: Total recalls, total post-recall scans, and a shortcut button to `/app/recall.php`.
- **Full recall table** from `v_recall_list` ordered by most recent first, with columns: Batch (linking to `/app/batch_detail.php?batch=...`), Medicine, Manufacturer, Reason, Recall Date, Issued By, QR Count, Total Scans, Post-Recall Scans (badge highlighted red when > 0).
- **Totals row** in the table footer.

---

## 5. Demo Steps to Try Each Verdict (Public Portal)

The public scan page accepts code input via the text box or direct URL parameter `?code=...`.

When `DEMO_MODE` is enabled in `config.local.php`, sample codes appear directly below the search box with one-click buttons to automatically fill and verify the code.

### 1. Genuine (Green Badge)
- **Sample Code:** `PT360-20515ECBE7F2` (from Approved batch `BT-2026-001`, Actiflu 500mg Tablet)
- **Direct Link:** [http://localhost:8000/?code=PT360-20515ECBE7F2](http://localhost:8000/?code=PT360-20515ECBE7F2)
- **Expected Result:**
  - Verdict badge: `Genuine` (Green)
  - Plain sentence: *"This medicine is verified genuine, active, and within its expiry period."*
  - Shows medicine name, strength, active ingredient, manufacturer, batch number, dates, storage, *"Used for"*, *"Common side effects"*, and *"Avoid taking together with"*, followed by the advisory note.

### 2. Expired (Amber Badge)
- **Sample Code:** `PT360-DC2566C8811D` (from Approved batch `BT-2024-007`, Omee 10mg Tablet, expiry `2026-02-28`)
- **Direct Link:** [http://localhost:8000/?code=PT360-DC2566C8811D](http://localhost:8000/?code=PT360-DC2566C8811D)
- **Expected Result:**
  - Verdict badge: `Expired` (Amber)
  - Plain sentence: *"This medicine has passed its expiry date. Do not use expired medicine."*
  - Displays full medicine information with the past expiry date clearly visible.

### 3. Recalled (Red Badge)
- **Sample Code:** `PT360-DC651A49114C` (from Recalled batch `BT-2026-012`, Ciplox 500 Tablet, recalled `2026-09-15`)
- **Direct Link:** [http://localhost:8000/?code=PT360-DC651A49114C](http://localhost:8000/?code=PT360-DC651A49114C)
- **Expected Result:**
  - Verdict badge: `Recalled` (Red)
  - Plain sentence: *"This batch has been recalled by the manufacturer or regulator. Do not use this medicine."*
  - Displays warning and medicine information.

### 4. Suspicious / Unknown Code (Red Badge)
- **Sample Code:** `TOTALLY-FAKE-CODE-XYZ` or `FAKE-000000000001`
- **Direct Link:** [http://localhost:8000/?code=TOTALLY-FAKE-CODE-XYZ](http://localhost:8000/?code=TOTALLY-FAKE-CODE-XYZ)
- **Expected Result:**
  - Verdict badge: `Suspicious` (Red)
  - Plain sentence: *"We could not confirm this code. Do not use this medicine until you check with a pharmacist."*
  - **No** medicine, manufacturer, or batch details are shown. Only the verdict and the public advisory note appear.

---

## 5. Architecture & Security Notes

- **Least Privilege Connections:** Web application separates unauthenticated visitors (`pt_public`) from staff members (`pt_app`). Neither user has permissions to run raw `SELECT`, `INSERT`, `UPDATE`, or `DELETE` on base tables.
- **Single Stored Procedure for Public Scans:** The public verification portal strictly calls `CALL sp_verify_scan(?)` using PDO prepared statements.
- **Multiple Result Sets:** Results are processed cleanly using `nextRowset()` and `closeCursor()`.
- **Zero Data Leakage:** Internal supplier names, QA test parameters, and costs are never exposed to public visitors.
- **Visitor Safety:** Database exceptions are caught, logged to `web/logs/error.log`, and the user is shown a generic message: *"Something went wrong, please try again"*.
- **XSS Protection:** All dynamic outputs are escaped with `htmlspecialchars()` via helper function `e()`.
- **Session & CSRF Protection:** Staff sessions are guarded with `httponly` and `samesite=Lax` cookies, session regeneration on login, 30-minute idle expiration, and CSRF token validation on every POST request.
