# PharmaTrace 360 — Documentation & Consistency Audit Report

> **Date:** October 6, 2026  
> **Status:** Completed  
> **Scope:** `docs/*.md`, `web/README.md`, `web/public/index.php`, `web/includes/db.php`, `db/*.sql` comments.  
> **Rules Followed:** Database table structures and SQL logic in `db/01` to `db/04` were preserved without modification.

---

## 1. Summary of Audit Findings & Fixes

| Category | Checked For | Finding / Status | Action Taken |
|---|---|---|---|
| **Database Engine** | Mentions of `XAMPP` or `MariaDB` as database | No file used MariaDB. `docs/CONTEXT.md` had a parenthetical note `(not XAMPP)`. | Removed `(not XAMPP)` in `docs/CONTEXT.md` to avoid any confusion. Confirmed clean statement: *MySQL 8 installed directly on Windows.* |
| **User & Role Counts** | "3 user types" or "Roles has 3 rows" | The database table `Roles` contains **exactly 2 rows**: `Admin/Regulator` (role_id 1) and `Manufacturer` (role_id 2). Public visitors do not have accounts and do not exist in `Users` or `Roles`. | Clarified in `docs/CONTEXT.md` that `Roles` has exactly 2 rows and that Public is an unauthenticated visitor role with no database account or role entry. |
| **Batch Numbers** | Old batch number prefixes (e.g. `BT-2024-xxx`) | All active/pending/rejected/recalled batches are prefixed with `BT-2026-` (`BT-2026-001` through `BT-2026-006`, `BT-2026-008` through `BT-2026-012`). | Verified that **only `BT-2024-007`** retains the 2024 prefix (specifically designed as the Approved expired demo batch, expired on `2026-02-28`). |
| **QR Code Examples** | Stale QR code strings (e.g. old `PT360-A927...`) | All documents, tests, and web examples reference active deterministic QR codes generated from the seed script. | Verified `PT360-20515ECBE7F2` (Genuine, pack 1 of `BT-2026-001`), `PT360-DC2566C8811D` (Expired, pack 1 of `BT-2024-007`), and `PT360-DC651A49114C` (Recalled, pack 1 of `BT-2026-012`). |
| **Copied-Code Demo Count** | Inconsistency between `expected_counts.md` and `data_overrides.md` | `data_overrides.md` stated "scanned 12 times over 2 days", while `expected_counts.md` stated 13 total scans (1 Genuine + 12 Suspicious). | Updated `docs/data_overrides.md` to state: `PT360-20515ECBE7F2 scanned 12 times over 2 days (13 total scans: 1 Genuine + 12 Suspicious copies)`. Both files are now 100% synchronized. |
| **Table & Row Counts** | Schema tables and seed row counts | All 17 tables and 390 seed rows match `db/02_seed.sql` and `db/build_seed.py`. | Verified `docs/expected_counts.md` table-by-table against `db/02_seed.sql` (details below). |
| **Dates & Timeline** | Stale dates or timeline contradictions | All batch manufacture dates are in 2026 (except `BT-2024-007`), deliveries occur 1–8 weeks prior to manufacturing, test dates are 3–10 days post-manufacture, recall is on `2026-09-15`. | Verified all dates conform to the reference date (October 6, 2026). |

---

## 2. Table-by-Table Expected Count Verification

Cross-referenced `docs/expected_counts.md` against `db/02_seed.sql` and `db/build_seed.py`:

| # | Table Name | `expected_counts.md` | `db/02_seed.sql` | Verification Result |
|---|---|---:|---:|:---:|
| 1 | `Roles` | 2 | 2 | Match (Admin/Regulator, Manufacturer) |
| 2 | `Manufacturers` | 9 | 9 | Match (from CSV) |
| 3 | `Factories` | 18 | 18 | Match (2 per manufacturer) |
| 4 | `Users` | 4 | 4 | Match (1 admin + 3 manufacturer users) |
| 5 | `Suppliers` | 5 | 5 | Match (5 simulated suppliers) |
| 6 | `Ingredients` | 15 | 15 | Match (active ingredients from CSV) |
| 7 | `Material_Deliveries` | 20 | 20 | Match (received 1–8 wks before batch mfg) |
| 8 | `Medicines` | 15 | 15 | Match (15 branded medicines) |
| 9 | `Drug_Formulations` | 15 | 15 | Match (1:1 active ingredient link) |
| 10 | `Medicine_Info` | 165 | 165 | Match (uses, side_effects, avoid_with) |
| 11 | `Production_Batches` | 12 | 12 | Match (7 Approved, 2 Pending, 2 Rejected, 1 Recalled) |
| 12 | `Batch_Materials` | 17 | 17 | Match (delivery consumption links) |
| 13 | `Quality_Test_Reports` | 13 | 13 | Match (12 initial tests + 1 re-test for BT-2026-010) |
| 14 | `QR_Codes` | 40 | 40 | Match (5 packs × 8 eligible batches) |
| 15 | `Product_Recalls` | 1 | 1 | Match (BT-2026-012 on 2026-09-15) |
| 16 | `Scan_Log` | 31 | 31 | Match (15 Genuine, 1 Expired, 1 Recalled, 2 Unknown Fake, 12 Copied Suspicious) |
| 17 | `Audit_Logs` | 8 | 8 | Match (8 demo audit events) |
| | **TOTAL ROWS** | **390** | **390** | **Exact 100% Match** |

---

## 3. Audited Files List

- `docs/CONTEXT.md` (Updated)
- `docs/data_overrides.md` (Updated)
- `docs/expected_counts.md` (Verified)
- `docs/dataset_report.md` (Verified)
- `docs/er_diagram.md` (Verified)
- `docs/logic_overview.md` (Verified)
- `docs/normalization.md` (Verified)
- `web/README.md` (Verified)
- `web/public/index.php` (Verified)
- `web/includes/db.php` (Verified)
- `db/01_schema.sql` (Verified comments)
- `db/02_seed.sql` (Verified comments)
- `db/03_logic.sql` (Verified comments)
- `db/04_demo.sql` (Verified comments)
