# PharmaTrace 360 — Expected Row Counts

> After running `01_schema.sql` followed by `02_seed.sql`, every table
> should contain exactly the counts below.

---

## Verification query

```sql
USE pharmatrace360;

SELECT 'Roles'                 AS table_name, COUNT(*) AS row_count FROM Roles
UNION ALL SELECT 'Manufacturers',       COUNT(*) FROM Manufacturers
UNION ALL SELECT 'Factories',           COUNT(*) FROM Factories
UNION ALL SELECT 'Users',               COUNT(*) FROM Users
UNION ALL SELECT 'Suppliers',           COUNT(*) FROM Suppliers
UNION ALL SELECT 'Ingredients',         COUNT(*) FROM Ingredients
UNION ALL SELECT 'Material_Deliveries', COUNT(*) FROM Material_Deliveries
UNION ALL SELECT 'Medicines',           COUNT(*) FROM Medicines
UNION ALL SELECT 'Drug_Formulations',   COUNT(*) FROM Drug_Formulations
UNION ALL SELECT 'Medicine_Info',       COUNT(*) FROM Medicine_Info
UNION ALL SELECT 'Production_Batches',  COUNT(*) FROM Production_Batches
UNION ALL SELECT 'Batch_Materials',     COUNT(*) FROM Batch_Materials
UNION ALL SELECT 'Quality_Test_Reports',COUNT(*) FROM Quality_Test_Reports
UNION ALL SELECT 'QR_Codes',           COUNT(*) FROM QR_Codes
UNION ALL SELECT 'Product_Recalls',    COUNT(*) FROM Product_Recalls
UNION ALL SELECT 'Scan_Log',           COUNT(*) FROM Scan_Log
UNION ALL SELECT 'Audit_Logs',         COUNT(*) FROM Audit_Logs;
```

---

## Expected counts

| #  | Table                  | Rows | Source       | Notes |
|----|------------------------|-----:|--------------|-------|
| 1  | Roles                  |    2 | Simulated    | Admin/Regulator, Manufacturer |
| 2  | Manufacturers          |    9 | Real (CSV)   | 9 unique manufacturers from `medicines_15.csv` |
| 3  | Factories              |   18 | Simulated    | 2 per manufacturer × 9 |
| 4  | Users                  |    4 | Simulated    | 1 admin + 3 manufacturer users |
| 5  | Suppliers              |    5 | Simulated    | 5 fictional supplier companies |
| 6  | Ingredients            |   15 | Real (CSV)   | 15 active ingredients |
| 7  | Material_Deliveries    |   20 | Simulated    | ≥1 per (ingredient, manufacturer) pair used by batches |
| 8  | Medicines              |   15 | Real (CSV)   | 15 branded products |
| 9  | Drug_Formulations      |   15 | Real (CSV)   | 1 per medicine (single active ingredient each) |
| 10 | Medicine_Info          |  165 | Real (CSV)   | uses + side_effects + avoid_with, split on `;` |
| 11 | Production_Batches     |   12 | Simulated    | 7 Approved, 2 Pending, 2 Rejected, 1 Recalled |
| 12 | Batch_Materials        |   17 | Simulated    | 1–2 deliveries per batch |
| 13 | Quality_Test_Reports   |   13 | Simulated    | ≥1 per batch; BT-2026-010 has Fail + Pass re-test |
| 14 | QR_Codes               |   40 | Simulated    | 5 codes × 8 eligible batches (7 Approved + 1 Recalled) |
| 15 | Product_Recalls        |    1 | Simulated    | 1 recall (BT-2026-012) |
| 16 | Scan_Log               |   31 | Simulated    | 15 Genuine + 1 Expired + 1 Recalled + 2 Suspicious (unknown) + 12 Suspicious (copied code) |
| 17 | Audit_Logs             |    8 | Simulated    | 8 sample entries |
|    | **TOTAL**              |**390**|             | |

---

## Special rows to look for

| Scenario | Batch | What to verify |
|---|---|---|
| **Expired** | BT-2024-007 | `status = 'Approved'`, `expiry_date = '2026-02-28'` (already past) |
| **Recalled** | BT-2026-012 | `status = 'Recalled'`, 1 row in `Product_Recalls`, 5 QR codes |
| **Rejected (re-test)** | BT-2026-010 | 2 rows in `Quality_Test_Reports` (1 Fail, 1 Pass) |
| **Copied code** | PT360-20515ECBE7F2 | 13 total scans (1 Genuine + 12 Suspicious) |
| **Unknown codes** | FAKE-000000000001, COUNTERFEIT-00002 | `qr_id IS NULL`, verdict `'Suspicious'` |
