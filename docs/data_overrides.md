# PharmaTrace 360 — Data Overrides

> **Rule:** Any value typed in by hand (not read directly from the Kaggle CSV
> files) must be listed here with its reason.
> See `docs/CONTEXT.md § DATA RULES` for the full policy.

---

## What counts as an "override"?

A value is an override if it was **not** copied verbatim from one of the two
raw Kaggle files:

- `data/raw/Extensive_A_Z_medicines_dataset_of_India.csv` (the A-Z file)
- `data/raw/medicine_data.csv`

These overrides are defined in the `OVERRIDES` section at the top of
`data/clean/build_medicines_15.py` and are used automatically when the script
runs.

---

## Override 1 — Pantoprazole: Lupin Ltd chosen as manufacturer

| Property | Value |
|----------|-------|
| **Affected medicine** | Pantoprazole (row 9 in `medicines_15.csv`) |
| **Field** | `manufacturer` |
| **Value produced** | `Lupin Ltd` → brand name **Lupipan 40mg Tablet** |
| **How it is enforced** | In `TARGETS`, `'lupin'` is placed first in the Pantoprazole manufacturer-preference list (`PANTOPRAZOLE_MFR_PREFS`). The scoring function then naturally picks the Lupin product. |
| **Reason** | Without the override the scorer picks a Sun Pharma or Aristo product. Lupin Ltd is a well-known Indian generic manufacturer and its brand *Lupipan* is widely recognised. Using it gives the demo data better manufacturer diversity (Lupin would not otherwise appear in the top 15 except for Levocetirizine/Elate). |
| **Source of the brand/medicine data itself** | `Extensive_A_Z_medicines_dataset_of_India.csv` — the row is real Kaggle data; only the *selection preference* is overridden. |

---

## Override 2 — Amoxycillin: hand-supplied drug-interaction list

| Property | Value |
|----------|-------|
| **Affected medicine** | Amoxycillin (row 2 in `medicines_15.csv`) |
| **Field** | `when_to_avoid_interactions` |
| **Value** | `Warfarin; Methotrexate; Allopurinol; Probenecid` |
| **How it is enforced** | Defined in `FALLBACK_INTERACTIONS['amoxycillin']` in the OVERRIDES section of the build script. Used only because `medicine_data.csv` contains no single-ingredient Amoxycillin row with a non-empty interaction list. |
| **Reason** | These are standard drug-drug interactions for Amoxycillin, typed from general drug-reference knowledge, not verified against a cited source: Warfarin anticoagulant potentiation, Methotrexate toxicity increase, Allopurinol rash risk, Probenecid competition for renal tubular secretion. |
| **Source** | Public pharmacology references — **not** from the Kaggle files. For demonstration purposes only. |

---

## Override 3 — Atorvastatin: hand-supplied drug-interaction list

| Property | Value |
|----------|-------|
| **Affected medicine** | Atorvastatin (row 5 in `medicines_15.csv`) |
| **Field** | `when_to_avoid_interactions` |
| **Value** | `Clarithromycin; Erythromycin; Gemfibrozil; Rifampicin; Digoxin` |
| **How it is enforced** | Defined in `FALLBACK_INTERACTIONS['atorvastatin']` in the OVERRIDES section of the build script. Used only because `medicine_data.csv` contains no single-ingredient Atorvastatin row with a non-empty interaction list. |
| **Reason** | These are standard interactions for Atorvastatin, typed from general drug-reference knowledge, not verified against a cited source: Clarithromycin and Erythromycin inhibit CYP3A4 (raising statin plasma levels, myopathy risk); Gemfibrozil raises statin AUC significantly; Rifampicin is a CYP3A4 inducer (lowers efficacy); Digoxin plasma levels are increased by atorvastatin. |
| **Source** | Public pharmacology references — **not** from the Kaggle files. For demonstration purposes only. |

---

## Override 4 — Amlodipine: hand-supplied drug-interaction list

| Property | Value |
|----------|-------|
| **Affected medicine** | Amlodipine (row 10 in `medicines_15.csv`) |
| **Field** | `when_to_avoid_interactions` |
| **Value** | `Simvastatin; Cyclosporine; Rifampicin; Tacrolimus` |
| **How it is enforced** | Defined in `FALLBACK_INTERACTIONS['amlodipine']` in the OVERRIDES section of the build script. Used only because `medicine_data.csv` contains no single-ingredient Amlodipine row with a non-empty interaction list. |
| **Reason** | These are standard interactions for Amlodipine, typed from general drug-reference knowledge, not verified against a cited source: Simvastatin dose cap; Cyclosporine raises amlodipine AUC ~2×; Rifampicin (CYP3A4 inducer) reduces amlodipine efficacy; Tacrolimus interaction via CYP3A4. |
| **Source** | Public pharmacology references — **not** from the Kaggle files. For demonstration purposes only. |

---

## Override 5 — Storage note (all 15 medicines)

| Property | Value |
|----------|-------|
| **Affected medicines** | All 15 rows in `medicines_15.csv` |
| **Field** | `storage_note` |
| **Value** | `Store below 25 C, in a cool dry place, away from light` |
| **How it is enforced** | Defined in `STORAGE` constant in the OVERRIDES section of the build script and written to every output row. |
| **Reason** | Neither Kaggle source file contains a storage conditions column. A single generic cool-dry-place instruction was applied to all 15 solid-dose tablets as a reasonable default for the demo. Each row's `source_note` field includes `"demo storage text"` so it is never confused with real labelling data. |
| **Source** | Hand-written by the project team. For demonstration purposes only. |

---

## Simulated data (generated by `db/build_seed.py`)

The seed file `db/02_seed.sql` contains a mix of **real** data (from the CSV)
and **simulated** data (invented for the demo). Every simulated INSERT is
marked with a `-- SIMULATED` comment header in the SQL.

### What is simulated

| Table | Simulated? | Details |
|---|---|---|
| Roles | Yes | Exactly 2: `Admin/Regulator`, `Manufacturer` |
| Manufacturers | **No** — real | 9 companies from `medicines_15.csv`. `registration_no` values (`DEMO-MFR-001` … `009`) are simulated placeholders. |
| Factories | Yes | 2 per manufacturer, named `<Company> Plant 1/2`, located in Indian cities, with demo license numbers. |
| Users | Yes | 1 admin (`priya.admin@demo.test`) and 3 manufacturer users. `password_hash = '!'` (login disabled — a later PHP step sets real bcrypt hashes). |
| Suppliers | Yes | 5 **fictional** companies (Greenleaf Chem Supplies, Apex Pharma Ingredients, Nexus Raw Materials Pvt, PrimeChem Industries, Reliable API Corporation). **No real company names.** |
| Ingredients | **No** — real | 15 active ingredients from the CSV. |
| Material_Deliveries | Yes | ~20 deliveries, ensuring every (ingredient, manufacturer) pair used by a batch has at least one delivery. Quantities, dates, and COA certificate numbers are demo values. |
| Medicines | **No** — real | 15 rows from `medicines_15.csv`. |
| Drug_Formulations | **No** — real | 1 row per medicine, from `active_ingredient_1` + `strength_1`. |
| Medicine_Info | **No** — real | Split from `uses`, `side_effects`, `when_to_avoid_interactions` on `;`. |
| Production_Batches | Yes | 12 batches with fixed dates (no `NOW()`). |
| Batch_Materials | Yes | 1–2 deliveries per batch; **only** deliveries received by the same manufacturer that owns the batch's factory, and only deliveries of that medicine's ingredient. |
| Quality_Test_Reports | Yes | ≥1 per batch. Rejected batches have Fail results (purity < 90% or dissolution < 80%). BT-2026-010 has a Fail followed by a Pass re-test. |
| QR_Codes | Yes | 5 deterministic codes per eligible batch (format `PT360-` + 12 hex chars via `uuid5`). |
| Product_Recalls | Yes | 1 recall for BT-2026-012 (Ciplox 500 Tablet). |
| Scan_Log | Yes | Hard-coded demo scans (see below). |
| Audit_Logs | Yes | 8 sample entries (see below). |

### Fixed assumptions

| Assumption | Value |
|---|---|
| Number of batches | 12 |
| Status mix | 7 Approved, 2 Pending, 2 Rejected, 1 Recalled |
| Expired demo | BT-2024-007 (Omee 10mg Tablet) — Approved, expiry 2026-02-28 |
| Recalled batch | BT-2026-012 (Ciplox 500 Tablet) — reason: impurity in stability test |
| QR codes per batch | 5 (for Approved + Recalled batches only) |
| Copied-code demo | `PT360-20515ECBE7F2` scanned 12 times over 2 days (13 total scans: 1 Genuine + 12 Suspicious copies) |
| Unknown-code demo | `FAKE-000000000001`, `COUNTERFEIT-00002` (qr_id NULL) |

### Scan_Log and Audit_Logs caveat

The `Scan_Log` rows (31 total) and `Audit_Logs` rows (8 total) are
**hard-coded for demonstration purposes** until the stored procedures and
triggers that generate them automatically are created in a later SQL file.
Once the verify procedure and auto-audit triggers exist, these rows will
serve as baseline examples and may be replaced by trigger-generated data.

---

## Acknowledgement

These overrides are for a **2nd-Year B.Tech DBMS demonstration project only**.
The interaction data and storage notes are general information and **must not**
be used for any clinical or patient-facing purpose.
