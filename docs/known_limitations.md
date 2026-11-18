# PharmaTrace 360 — Known Limitations & System Assumptions

> **Audience:** Academic Evaluators, Auditors, and Future Developers.  
> **Course:** 2nd-Year B.Tech DBMS Project.  
> **Purpose:** Transparently documents all synthetic data boundaries, unverified third-party sources, cryptographic trade-offs, and deliberate design decisions made in PharmaTrace 360.

---

## 1. The Three Hand-Typed Drug Interaction Lists

While 12 of the 15 medicines in our demo dataset obtained their drug-interaction warnings directly from the Kaggle dataset (`medicine_data.csv`), three widely-used generic medicines had no single-ingredient interaction row in that source file:

1. **Amoxycillin (500mg Tablet):**
   - *Hand-supplied interactions:* `Warfarin; Methotrexate; Allopurinol; Probenecid`
   - *Pharmacological basis:* Warfarin anticoagulant potentiation, Methotrexate toxicity elevation, Allopurinol rash incidence, and Probenecid competition for renal tubular excretion.
2. **Atorvastatin (10mg Tablet):**
   - *Hand-supplied interactions:* `Clarithromycin; Erythromycin; Gemfibrozil; Rifampicin; Digoxin`
   - *Pharmacological basis:* Macrolide CYP3A4 inhibition (increased myopathy risk), Gemfibrozil AUC elevation, Rifampicin CYP3A4 induction (decreased efficacy), and Digoxin clearance interaction.
3. **Amlodipine (5mg Tablet):**
   - *Hand-supplied interactions:* `Simvastatin; Cyclosporine; Rifampicin; Tacrolimus`
   - *Pharmacological basis:* Simvastatin dose-capping guidance (FDA safety alert), Cyclosporine AUC doubling, Rifampicin induction, and Tacrolimus immunosuppressant interaction.

> **Limitation Note:** These fallback interaction lists were typed from general drug-reference knowledge, not verified against a cited source. They are documented in `docs/data_overrides.md` and hard-coded into `data/clean/build_medicines_15.py`. They are for educational demonstration only and must never be used for actual clinical advice.

---

## 2. Simulated & Synthetic Operational Data

To demonstrate supply-chain relationships and quality-assurance enforcement without requiring confidential corporate records, the following entities are **simulated**:

- **Suppliers (5 fictional entities):** Greenleaf Chem Supplies, Apex Pharma Ingredients, Nexus Raw Materials Pvt, PrimeChem Industries, and Reliable API Corporation. None represent real-world commercial companies.
- **Material Deliveries (20 shipments):** Delivery quantities (kg), delivery dates, and Certificate of Analysis numbers (`COA-2024-xxxx`) are synthetic values generated to ensure every batch has at least one valid upstream delivery.
- **Production Batches (12 batches):** Batch numbers (`BT-2026-001` through `BT-2026-012` and `BT-2024-007`), batch sizes, and status distributions (7 Approved, 2 Pending, 2 Rejected, 1 Recalled) are created to test every branch of the business logic.
- **Quality Assurance Reports (13 test reports):** Chemical assay metrics (purity %, dissolution %, weight variation %) are simulated. Rejections and re-tests (such as the Fail-then-Pass re-test for `BT-2026-010`) were deliberately constructed to test trigger validation.
- **QR Codes (40 serialized packs):** 5 codes per eligible batch generated via deterministic UUID hashing.
- **Scan Log (31 sample scans):** A constructed scan history containing normal genuine scans, expired scans, recalled scans, invalid counterfeit scans, and 12 scans of one code over 48 hours to demonstrate clone detection.

---

## 3. Demo-Only Attributes & Generic Storage Conditions

- **Generic Storage Instructions:** Neither raw Kaggle dataset provided a storage condition field. A uniform generic text — *"Store below 25 C, in a cool dry place, away from light"* — was applied to all 15 solid oral dosage forms. In the database, this is explicitly tagged with `source_note = 'demo storage text'` to avoid confusion with manufacturer labelling.
- **Manufacturer Registration & License Numbers:** Corporate registration IDs (`DEMO-MFR-001` … `009`) and factory drug manufacturing licenses (`DL-MUM-001`, etc.) are fictional placeholders.

---

## 4. Unverified Licenses of Scraped Datasets

The raw data files (`Extensive_A_Z_medicines_dataset_of_India.csv` and `medicine_data.csv`) were obtained from public community repositories on Kaggle.  
- Licences of the scraped datasets have not been verified. The underlying original web licenses (from commercial online pharmacies such as 1mg) have not been independently audited or verified by the project team.
- The datasets are utilized strictly for academic coursework evaluation and demonstration.
- The raw data reflects market listings circa 2022 and does not necessarily represent current pricing, discontinuation status, or packaging.

---

## 5. QR Codes are Random / Unique, Not Digitally Signed

- **Current Implementation:** Runtime QR tokens use 128 bits from MySQL `RANDOM_BYTES(16)` and are prefixed with `PT360-`. Seeded demo tokens are deterministic so test data is reproducible.
- **Limitation:** Codes are stored in the database and do **not** contain an embedded asymmetric cryptographic digital signature. Offline verification is not supported.
- **Security Implications:** Verification relies on an active online database query (`sp_verify_scan`).
- **Counterfeit Mitigation:** The system flags unknown codes and codes scanned more than 10 times in a rolling 48-hour window. Public rate limiting remains a deployment requirement.

## 6. No Rate Limiting on the Public Scan Page

- The consumer verification page (`web/public/index.php`) and its underlying stored procedure `sp_verify_scan` are completely public and accessible without authentication.
- **Limitation:** There is currently no IP-based rate limiting, token bucket algorithm, or CAPTCHA verification on the public scan endpoint.
- **Context:** This was chosen intentionally to make classroom demonstration and browser grading frictionless. In an enterprise internet deployment, an API gateway or reverse proxy (such as Cloudflare or Nginx `limit_req`) would be mandatory to prevent brute-force code enumeration and denial-of-service (DoS) attacks.

---

## 7. `Scan_Log.verdict` is a Historical Snapshot (Deliberate Design Decision)

A common question is why `Scan_Log.verdict` is recorded as a static `ENUM('Genuine', 'Expired', 'Recalled', 'Suspicious')` at scan time rather than always calculated dynamically via a view.

- **Deliberate Design Rationale:** In regulatory audit logging, an audit log must record **what the system observed and told the consumer at the exact moment the event occurred**.
- **Scenario:** If a consumer scans a valid pack in June 2026, the medicine is Genuine, and the system correctly logs `verdict = 'Genuine'`. If the manufacturer discovers an impurity and issues a recall in September 2026, the historical scan record from June must **not** retroactively change to `'Recalled'`. It remains a factual record that on June 20, the pack was scanned and verified genuine.
- **Dynamic Status Today:** If that same QR code is scanned again in October 2026, `fn_qr_verdict` dynamically checks `Product_Recalls` and `expiry_date` in real-time, instantly issuing a `Recalled` verdict for the new scan. The database therefore maintains both **dynamic real-time security** and **immutable historical truth**.

---

## 8. Web Security & Session Architecture Limitations (Demo Only)

- **No Account Lockout or Rate Limiting on Login:** Failed attempts are logged but not automatically rate-limited or locked out. Production deployment should add application or reverse-proxy rate limits.
- **Default File Session Storage:** Sessions use PHP's default file storage. Cookies are HttpOnly, SameSite=Lax, Secure when HTTPS is detected, and sessions expire after 30 minutes of inactivity. High-availability deployment would need a shared session store.
- **Plain HTTP (Local Demo Only):** The local PHP server uses HTTP. Production deployment requires HTTPS/TLS.
- **Shared Application Database Identity:** `pt_app` is shared by all logged-in staff. Stored procedures receive the application-supplied user ID, so the database cannot independently prove which staff member initiated a call. The PHP layer performs session and role checks; production should use a stronger trusted identity boundary.
- **Authentication Hash Boundary:** `sp_login_lookup` returns the selected user's password hash to PHP so `password_verify()` can run. A holder of the shared `pt_app` database credentials could call it for other email addresses and retrieve their hashes; the same shared identity also cannot independently prove which user requested `sp_change_password`. Keep DB credentials server-only and use a separate authentication service/credential boundary in production.

## 9. CLI-Only Password Bootstrap

- The normal web application account `pt_app` is not granted `EXECUTE` on `sp_set_password`.
- The CLI-only `pt_setup` account receives that permission through `db/10_setup_grants.sql` and is used only by `web/tools/set_password.php`.
- Keep `pt_setup` credentials local and never configure them in a web-facing database connection.

## 10. Master Data Loaded Exclusively via SQL Scripts (No UI Screens)

- Master data — including Manufacturers, Suppliers, Medicines, Ingredients, and Drug Formulations — is loaded and maintained directly by SQL scripts (`db/01_schema.sql`, `db/02_seed.sql`, and `db/build_seed.py`).
- **Limitation:** There are no screens in the web portal for creating or updating corporate master data (e.g. adding new manufacturers, registering suppliers, or authoring new drug formulations). Operational deliveries and batches are managed via database stored procedures (`sp_record_delivery`, `sp_create_batch`, `sp_add_batch_material`).
- **Context:** The project scope focuses strictly on the batch lifecycle (manufacturing linkage, quality test recording, batch approval/rejection, serialized QR issuance, scan verification, clone detection, and recall cascades).

---

## 11. Database Status of Expired Batches Remains `Approved`

- An `Approved` batch that has passed its `expiry_date` retains `status = 'Approved'` in the `Production_Batches` table. The database does not alter historical batch rows or run a background job to flip the stored status to `'Expired'`.
- **Limitation & Enforcement:** In the batch table itself, the status remains `Approved`. However, public verification dynamically evaluates expiration at query time via `fn_qr_verdict`.
- **Behavior:** `fn_qr_verdict` checks `IF v_expiry < CURDATE() THEN RETURN 'Expired';`. When a consumer scans a pack from an expired batch, the system displays an amber **Expired** badge and warning (*"This medicine has passed its expiry date. Do not use expired medicine."*), ensuring real-time consumer safety without altering the batch's immutable manufacturing status.

---

## 12. Suppliers Are Fixed Records (Cannot Be Added from the Web)

- Suppliers are fixed database records (`Suppliers` table) established during database initialization.
- **Limitation:** Suppliers are fixed records and cannot be added from the web. There is no web form or endpoint to register new suppliers.
- **Context:** Suppliers represent pre-vetted external chemical vendors. When recording raw material arrivals via `sp_record_delivery`, manufacturers must select from existing pre-registered suppliers.

---

## 13. Reset and Upgrade Paths

- `db/00_reset_all.sql` uses relative `SOURCE db/...` paths and must be run from the repository root.
- The reset script is destructive and intended only for fresh demo installs. Existing installations should review and use `db/09_upgrade_existing.sql`, which preserves rows but can stop safely if legacy duplicate certificate numbers prevent the new unique index from being created.






---

## 14. QA Acceptance Thresholds

- The database validates that QA measurements are present and within the allowed numeric range, and that the submitted result is `Pass` or `Fail`.
- The project does not define a verified product-specific purity, dissolution, or weight-variation acceptance specification. The database therefore does not invent numerical thresholds or automatically derive a Pass/Fail result from those measurements.
- Before using this workflow beyond a classroom demo, define documented acceptance criteria for each product and enforce those criteria in the QA workflow.
