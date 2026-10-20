# PharmaTrace 360 — Functional Dependencies & Normal Forms

> Analysis derived from `db/01_schema.sql`. For each table: candidate keys,
> functional dependencies (FDs), highest achieved normal form with reasoning,
> and deliberate denormalisations.

---

## 1. Roles

**Candidate keys:** {role_id}, {role_name}

**Functional Dependencies:**
- role_id -> role_name
- role_name -> role_id

**Normal form: BCNF**
Every non-trivial FD has a superkey on the left. No partial or transitive dependencies.

---

## 2. Manufacturers

**Candidate keys:** {manufacturer_id}, {registration_no}

**Functional Dependencies:**
- manufacturer_id -> company_name, registration_no, contact_email, contact_phone, address
- registration_no -> manufacturer_id, company_name, contact_email, contact_phone, address

**Normal form: BCNF**
Both candidate keys are minimal. All attributes depend only on the full key.

---

## 3. Factories

**Candidate keys:** {factory_id}

**Functional Dependencies:**
- factory_id -> manufacturer_id, factory_name, location, license_no

**Normal form: BCNF**
Single-attribute PK; all attributes depend on factory_id only.

---

## 4. Users

**Candidate keys:** {user_id}, {email}

**Functional Dependencies:**
- user_id -> full_name, email, password_hash, role_id, manufacturer_id, is_active, created_at
- email -> user_id, full_name, password_hash, role_id, manufacturer_id, is_active, created_at

**Normal form: BCNF**
All non-key attributes depend only on the full candidate key.

---

## 5. Suppliers

**Candidate keys:** {supplier_id}

**Functional Dependencies:**
- supplier_id -> supplier_name, contact_email, contact_phone, address

**Normal form: BCNF**
Single-attribute PK; no partial or transitive FDs.

---

## 6. Ingredients

**Candidate keys:** {ingredient_id}, {ingredient_name}

**Functional Dependencies:**
- ingredient_id -> ingredient_name, cas_number
- ingredient_name -> ingredient_id, cas_number

**Normal form: BCNF**
Two candidate keys; cas_number depends on either.

---

## 7. Material_Deliveries

**Candidate keys:** {delivery_id}
(certificate_number is NOT a candidate key — it is nullable in the schema, though `sp_record_delivery` enforces its uniqueness procedurally.)

**Functional Dependencies:**
- delivery_id -> supplier_id, ingredient_id, manufacturer_id, quantity_kg, received_date, certificate_number

**Normal form: BCNF**
Single-attribute surrogate key; no repeating groups.

---

## 8. Medicines

**Candidate keys:** {medicine_id}, {brand_name, manufacturer_id}

**Functional Dependencies:**
- medicine_id -> brand_name, manufacturer_id, dosage_form, pack_size, therapeutic_class, habit_forming, storage_note, source_note
- {brand_name, manufacturer_id} -> medicine_id, dosage_form, pack_size, ...

**Normal form: BCNF**
Both candidate keys are proper superkeys. No transitive FDs.

**Deliberate denormalisation — manufacturer reachable via two paths:**
A batch's manufacturer can be found via `Production_Batches.factory_id -> Factories.manufacturer_id`
OR via `Production_Batches.medicine_id -> Medicines.manufacturer_id`. This is not redundant data
storage (the manufacturer_id is only stored once in each table); rather, it is a cross-table
integrity property that is enforced by `trg_batches_bi` and `trg_batches_bu`, which signal an
error if the two paths yield different manufacturers.

---

## 9. Drug_Formulations

**Candidate keys:** {medicine_id, ingredient_id}

**Functional Dependencies:**
- {medicine_id, ingredient_id} -> strength, is_active

**Normal form: BCNF**
Composite PK is the only candidate key. All attributes depend on the full composite key — no
partial FDs.

---

## 10. Medicine_Info

**Candidate keys:** {info_id}
(No UNIQUE constraint on (medicine_id, info_type, info_text), so duplicate rows are possible —
see audit report P2.)

**Functional Dependencies:**
- info_id -> medicine_id, info_type, info_text

**Normal form: BCNF** (given the surrogate PK)

**Deliberate 1NF enforcement:**
This table exists to remove repeating groups from `Medicines`. Without it, `Medicines` would
need multi-valued columns for uses, side effects, and drug interactions — violating 1NF.
`Medicine_Info` normalises those repeating groups into individual rows tagged by `info_type`.

**ENUM column:**
`info_type ENUM('use','side_effect','avoid_with')` is a deliberate denormalisation: it encodes
a domain directly in the column type rather than in a separate lookup table. This trades
flexibility for simplicity and fast equality checks.

---

## 11. Production_Batches

**Candidate keys:** {batch_id}, {batch_number}

**Functional Dependencies:**
- batch_id -> batch_number, medicine_id, factory_id, quantity_units, manufacture_date, expiry_date, status
- batch_number -> batch_id, medicine_id, ...

**Normal form: BCNF**
All non-key attributes depend only on a candidate key. The `status` ENUM is a deliberate
denormalisation (see below).

**Deliberate denormalisation — ENUM status:**
`status ENUM('Pending','Approved','Rejected','Recalled')` stores lifecycle state directly in the
row rather than in a separate Status table with an FK. This avoids a join on every batch read and
is justified by the closed, stable domain (exactly 4 states).

---

## 12. Batch_Materials

**Candidate keys:** {batch_id, delivery_id}

**Functional Dependencies:**
- {batch_id, delivery_id} -> quantity_used_kg

**Normal form: BCNF**
The composite PK is the only candidate key; quantity_used_kg depends on the full key.
This is a pure junction table resolving the M:N relationship between Production_Batches and
Material_Deliveries.

---

## 13. Quality_Test_Reports

**Candidate keys:** {report_id}

**Functional Dependencies:**
- report_id -> batch_id, tested_by, test_date, purity_pct, dissolution_pct, weight_variation_pct, result, remarks

**Normal form: BCNF**
Single-attribute surrogate key.

---

## 14. QR_Codes

**Candidate keys:** {qr_id}, {code}

**Functional Dependencies:**
- qr_id -> code, batch_id, issued_at
- code -> qr_id, batch_id, issued_at

**Normal form: BCNF**
Both candidate keys are minimal superkeys.

---

## 15. Scan_Log

**Candidate keys:** {scan_id}

**Functional Dependencies:**
- scan_id -> scanned_code, qr_id, scanned_at, verdict

**Normal form: BCNF** (given the surrogate PK)

**Deliberate denormalisation — verdict snapshot:**
`verdict` is a snapshot of `fn_qr_verdict(scanned_code)` at the moment of the scan. It is
not derivable from current base-table state because the batch status may have changed since the
scan. For example, a code scanned while "Genuine" may later belong to a recalled batch. Storing
the snapshot is intentional for forensic accuracy — regulators need to know what the consumer saw,
not what the current status is.

This is a violation of 3NF in the sense that `verdict` is functionally determined by
`{scanned_code, scanned_at, current batch status}` — but because "current batch status" is a
time-varying fact, not a stored attribute, the storage of the snapshot is justified and necessary.

---

## 16. Product_Recalls

**Candidate keys:** {recall_id}, {batch_id}

**Functional Dependencies:**
- recall_id -> batch_id, reason, recall_date, issued_by
- batch_id -> recall_id, reason, recall_date, issued_by

**Normal form: BCNF**
Both candidate keys are minimal. The UNIQUE constraint on batch_id enforces one recall per batch.

---

## 17. Audit_Logs

**Candidate keys:** {log_id}

**Functional Dependencies:**
- log_id -> user_id, action, table_name, record_id, details, logged_at

**Normal form: BCNF**
Append-only; single surrogate key.

---

## Summary of Deliberate Denormalisations

| Denormalisation | Location | Justification |
|---|---|---|
| **Batch manufacturer reachable via two paths** | Production_Batches (via Factories) AND via Medicines | Cross-path integrity is enforced by triggers `trg_batches_bi/bu`. The redundancy is structural (two foreign keys), not data duplication. |
| **Scan_Log.verdict snapshot** | Scan_Log | Time-varying forensic record. Cannot be re-derived from current tables. Necessary for regulatory audit trails. |
| **ENUM status columns** | Production_Batches.status, Quality_Test_Reports.result, Scan_Log.verdict, Medicine_Info.info_type | Closed domains with stable values. Avoids extra lookup-table JOINs. Checked at insert time by MySQL. |
| **Therapeutic classification stored in Medicines** | Medicines.therapeutic_class | Repeated per medicine; not normalised into a separate TherapeuticClass table. Justified by the small number of queries on this attribute and the dataset's CSV origin. |
| **Medicine_Info instead of columns in Medicines** | Medicine_Info | Positive normalisation: removes repeating groups (uses, side effects, avoid_with) from Medicines to enforce 1NF. |
