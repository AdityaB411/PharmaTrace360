# PharmaTrace 360 — Relational Schema

> Built from `db/01_schema.sql`. Notation:
> `PK` = primary key column · `FK -> Table.column` = foreign key
> Composite PKs are shown with both parts labelled PK.

---

## 1. Roles
```
Roles(role_id PK, role_name UNIQUE)
```

## 2. Manufacturers
```
Manufacturers(manufacturer_id PK, company_name, registration_no UNIQUE,
              contact_email, contact_phone, address)
```

## 3. Factories
```
Factories(factory_id PK,
          manufacturer_id FK -> Manufacturers.manufacturer_id,
          factory_name, location, license_no)
```

## 4. Users
```
Users(user_id PK, full_name, email UNIQUE, password_hash,
      role_id FK -> Roles.role_id,
      manufacturer_id FK -> Manufacturers.manufacturer_id [nullable],
      is_active, created_at)
```

## 5. Suppliers
```
Suppliers(supplier_id PK, supplier_name, contact_email, contact_phone, address)
```

## 6. Ingredients
```
Ingredients(ingredient_id PK, ingredient_name UNIQUE, cas_number)
```

## 7. Material_Deliveries
```
Material_Deliveries(delivery_id PK,
                    supplier_id FK -> Suppliers.supplier_id,
                    ingredient_id FK -> Ingredients.ingredient_id,
                    manufacturer_id FK -> Manufacturers.manufacturer_id,
                    quantity_kg CHECK(>0), received_date, certificate_number)
```

## 8. Medicines
```
Medicines(medicine_id PK,
          brand_name,
          manufacturer_id FK -> Manufacturers.manufacturer_id,
          UNIQUE(brand_name, manufacturer_id),
          dosage_form, pack_size, therapeutic_class,
          habit_forming, storage_note, source_note)
```

## 9. Drug_Formulations
```
Drug_Formulations(medicine_id PK FK -> Medicines.medicine_id,
                  ingredient_id PK FK -> Ingredients.ingredient_id,
                  strength, is_active)
```

## 10. Medicine_Info
```
Medicine_Info(info_id PK,
              medicine_id FK -> Medicines.medicine_id,
              info_type ENUM('use','side_effect','avoid_with'),
              info_text)
```

## 11. Production_Batches
```
Production_Batches(batch_id PK, batch_number UNIQUE,
                   medicine_id FK -> Medicines.medicine_id,
                   factory_id FK -> Factories.factory_id,
                   quantity_units CHECK(>0),
                   manufacture_date, expiry_date CHECK(expiry>mfg),
                   status ENUM('Pending','Approved','Rejected','Recalled'))
```

## 12. Batch_Materials
```
Batch_Materials(batch_id PK FK -> Production_Batches.batch_id,
                delivery_id PK FK -> Material_Deliveries.delivery_id,
                quantity_used_kg CHECK(>0))
```

## 13. Quality_Test_Reports
```
Quality_Test_Reports(report_id PK,
                     batch_id FK -> Production_Batches.batch_id,
                     tested_by FK -> Users.user_id,
                     test_date,
                     purity_pct CHECK(0-100 or NULL),
                     dissolution_pct CHECK(0-100 or NULL),
                     weight_variation_pct CHECK(0-100 or NULL),
                     result ENUM('Pass','Fail'), remarks)
```

## 14. QR_Codes
```
QR_Codes(qr_id PK, code UNIQUE VARCHAR(64),
         batch_id FK -> Production_Batches.batch_id,
         issued_at)
```

## 15. Scan_Log
```
Scan_Log(scan_id PK, scanned_code VARCHAR(64),
         qr_id FK -> QR_Codes.qr_id [nullable, ON DELETE SET NULL],
         scanned_at,
         verdict ENUM('Genuine','Expired','Recalled','Not approved','Suspicious'))
```

## 16. Product_Recalls
```
Product_Recalls(recall_id PK,
                batch_id UNIQUE FK -> Production_Batches.batch_id,
                reason, recall_date, issued_at,
                issued_by FK -> Users.user_id)
```

## 17. Audit_Logs
```
Audit_Logs(log_id PK BIGINT,
           user_id FK -> Users.user_id [nullable],
           action VARCHAR(60), table_name VARCHAR(60),
           record_id [nullable], details, logged_at)
```

---

## Explicit Indexes (beyond PKs and UNIQUE keys)

| Index Name | Table | Columns | Purpose |
|---|---|---|---|
| `idx_scan_code_time` | Scan_Log | `(scanned_code, scanned_at)` | Composite: supports code-lookup AND time-range queries |
| `idx_scan_at` | Scan_Log | `(scanned_at)` | Time-range queries on entire Scan_Log |
