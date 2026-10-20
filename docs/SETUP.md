# PharmaTrace 360 — Fresh Windows PC Setup Guide

> **Target Audience:** Evaluators, Students, and Developers setting up on a clean Windows machine.  
> **Course:** 2nd-Year B.Tech DBMS Project.  
> **Security Rule:** Never commit or store real passwords in any project file. All credentials shown below are placeholders.

---

## 1. System Prerequisites

### A. Install MySQL 8.0+
1. Download and run the **MySQL Community Server 8.0+** installer for Windows from the official MySQL website.
2. During setup, configure MySQL Server as a Windows Service (default port `3306`) and set a root password. Remember this password.
3. Add the MySQL binary folder to your Windows system `PATH` (typically `C:\Program Files\MySQL\MySQL Server 8.0\bin`):
   - Press `Win + R`, type `sysdm.cpl`, and hit Enter.
   - Go to **Advanced** > **Environment Variables**.
   - Under **System variables**, select `Path`, click **Edit**, click **New**, and paste `C:\Program Files\MySQL\MySQL Server 8.0\bin`.
4. Open a new Command Prompt and verify:
   ```cmd
   mysql --version
   ```

### B. Install PHP 8.1+ with PDO MySQL
1. Download PHP 8.1 or higher (VS16 x64 Thread Safe or Non-Thread Safe) for Windows from [windows.php.net](https://windows.php.net/download/).
2. Extract the archive into a folder (e.g. `C:\php`).
3. Add `C:\php` to your Windows system `PATH` (using the same steps as above).
4. In `C:\php`, copy `php.ini-development` to `php.ini`.
5. Open `php.ini` in a text editor (e.g. Notepad, VS Code) and configure:
   - Search for `extension_dir = "ext"` and remove the leading semicolon (`;`) so it is enabled:
     ```ini
     extension_dir = "ext"
     ```
   - Search for `pdo_mysql` and remove the leading semicolon to enable the MySQL driver:
     ```ini
     extension=pdo_mysql
     ```
6. Open a new Command Prompt and verify both PHP and the driver:
   ```cmd
   php -v
   php -m | findstr pdo_mysql
   ```
   *(The command should output `pdo_mysql` confirming the extension is loaded).*

---

## 2. Copy the Project

Copy or clone the repository to your chosen local directory (for example, `E:\DBMS\PharmaTrace360` or `C:\PharmaTrace360`).

Open Command Prompt and navigate to the project root:
```cmd
cd /d E:\DBMS\PharmaTrace360
```
*(Replace `E:\DBMS\PharmaTrace360` with your actual project location).*

---

## 3. Create the Database Users by Hand

The system enforces least privilege using two dedicated MySQL accounts:
- `pt_public`: Used by anonymous public scan visitors.
- `pt_app`: Used by staff logins.

Log in to MySQL as root in your Command Prompt:
```cmd
mysql -u root -p
```
Enter your MySQL root password when prompted.

Run the following SQL commands to create the two user accounts. **Choose your own passwords and replace the placeholders:**

```sql
CREATE USER 'pt_public'@'localhost' IDENTIFIED BY '<TYPE_YOUR_PT_PUBLIC_PASSWORD_HERE>';
CREATE USER 'pt_app'@'localhost'    IDENTIFIED BY '<TYPE_YOUR_PT_APP_PASSWORD_HERE>';
EXIT;
```

> [!IMPORTANT]
> The placeholders `<TYPE_YOUR_PT_PUBLIC_PASSWORD_HERE>` and `<TYPE_YOUR_PT_APP_PASSWORD_HERE>` must be replaced by you when typing the commands into MySQL. Never store these passwords in any tracked files.

---

## 4. Fix Paths in `00_reset_all.sql`

The master reset script [db/00_reset_all.sql](file:///e:/DBMS/PharmaTrace360/db/00_reset_all.sql) uses absolute paths to execute its child SQL scripts sequentially.

1. Open `db/00_reset_all.sql` in a text editor.
2. Ensure the four `SOURCE` lines match your actual project folder location on Windows, using **forward slashes** (`/`):
   ```sql
   SOURCE E:/DBMS/PharmaTrace360/db/01_schema.sql;
   SOURCE E:/DBMS/PharmaTrace360/db/02_seed.sql;
   SOURCE E:/DBMS/PharmaTrace360/db/03_logic.sql;
   SOURCE E:/DBMS/PharmaTrace360/db/05_grants.sql;
   ```
   *(If your project is at `C:/PharmaTrace360`, update all paths to `C:/PharmaTrace360/db/...`).*
3. Save the file.

---

## 5. Run the Database Reset

Run the master reset script from Command Prompt using MySQL root:

```cmd
mysql -u root -p < db\00_reset_all.sql
```
*(If MySQL is not in your PATH, run: `"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < "db\00_reset_all.sql"`)*

Enter your MySQL root password when prompted.

This script will:
1. Re-create the `pharmatrace360` database.
2. Build all 17 tables, primary keys, foreign keys, and indexes (`01_schema.sql`).
3. Load the initial 390 seed rows (`02_seed.sql`).
4. Install all views, functions, triggers, and stored procedures (`03_logic.sql`).
5. Grant least-privilege permissions to `pt_public` and `pt_app` (`05_grants.sql`).

Output should end with:
```
Database reset complete! 17 tables and logic installed successfully.
```

---

## 6. Create `config.local.php`

1. In Command Prompt at the project root, copy the sample configuration template:
   ```cmd
   copy web\config.sample.php web\config.local.php
   ```
2. Open `web/config.local.php` in your text editor.
3. Fill in the database passwords you created in Step 3:
   ```php
   <?php
   return [
       'db' => [
           'host'    => '127.0.0.1',
           'port'    => 3306,
           'dbname'  => 'pharmatrace360',
           'charset' => 'utf8mb4',

           // pt_public: anonymous scan portal
           'public' => [
               'user'     => 'pt_public',
               'password' => '<TYPE_YOUR_PT_PUBLIC_PASSWORD_HERE>',
           ],

           // pt_app: staff portal (procedures + views only)
           'app' => [
               'user'     => 'pt_app',
               'password' => '<TYPE_YOUR_PT_APP_PASSWORD_HERE>',
           ],
       ],
       // Set to true to display sample QR codes on the public portal
       'DEMO_MODE' => true,
   ];
   ```
4. Save the file.

> [!NOTE]
> `web/config.local.php` is explicitly ignored by `.gitignore`. It contains your local credentials and must never be shared or committed.

---

## 7. Set Demo User Passwords

The database seed inserts users with disabled placeholder hashes (`!`). Use the included command-line utility [web/tools/set_password.php](file:///e:/DBMS/PharmaTrace360/web/tools/set_password.php) to set real bcrypt hashes for the demo accounts:

```cmd
php web\tools\set_password.php
```

Follow the interactive prompts to assign passwords to the demo accounts:
- `priya.admin@demo.test` (Admin / Regulator)
- `rahul.mfr@demo.test` (Manufacturer — Cipla Ltd)
- `anjali.mfr@demo.test` (Manufacturer — Alkem Laboratories Ltd)
- `vikram.mfr@demo.test` (Manufacturer — Alembic Pharmaceuticals Ltd)

---

## 8. Start the Web Server

From the project root directory, launch PHP's built-in web server:

```cmd
php -S localhost:8000 -t web/public
```

Leave this Command Prompt window running.

Open your browser and navigate to:
- **Public Drug Authentication Portal:** [http://localhost:8000](http://localhost:8000)
- **Staff Login Portal:** [http://localhost:8000/login.php](http://localhost:8000/login.php)

---

## 9. Mobile Phone Testing Over Local Wi-Fi (Optional)

To test scanning serialized QR codes with a real smartphone camera:
1. Find your PC's local IPv4 address by running `ipconfig` in Command Prompt (e.g. `192.168.1.50`).
2. Open `web/config.local.php` and set `PUBLIC_BASE_URL`:
   ```php
   'PUBLIC_BASE_URL' => 'http://192.168.1.50:8000',
   ```
3. Start the PHP server bound to all network interfaces:
   ```cmd
   php -S 0.0.0.0:8000 -t web/public
   ```
4. Allow PHP through Windows Defender Firewall for Private networks if prompted.
5. Connect your mobile phone to the same Wi-Fi network, view batch QR codes in the staff portal, and scan them with your phone camera.
