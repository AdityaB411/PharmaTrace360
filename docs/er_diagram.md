# PharmaTrace 360 — ER Diagram

> Generated for MySQL 8 schema (`db/01_schema.sql`).  
> All 17 tables are shown. Relationships use crow-foot notation.

---

## Mermaid Diagram

```mermaid
erDiagram

    Roles {
        TINYINT role_id PK
        VARCHAR role_name
    }

    Users {
        INT user_id PK
        VARCHAR full_name
        VARCHAR email
        VARCHAR password_hash
        TINYINT role_id FK
        INT manufacturer_id FK
        TINYINT is_active
        DATETIME created_at
    }

    Manufacturers {
        INT manufacturer_id PK
        VARCHAR company_name
        VARCHAR registration_no
        VARCHAR contact_email
        VARCHAR contact_phone
        TEXT address
    }

    Factories {
        INT factory_id PK
        INT manufacturer_id FK
        VARCHAR factory_name
        VARCHAR location
        VARCHAR license_no
    }

    Suppliers {
        INT supplier_id PK
        VARCHAR supplier_name
        VARCHAR contact_email
        VARCHAR contact_phone
        TEXT address
    }

    Ingredients {
        INT ingredient_id PK
        VARCHAR ingredient_name
        VARCHAR cas_number
    }

    Material_Deliveries {
        INT delivery_id PK
        INT supplier_id FK
        INT ingredient_id FK
        INT manufacturer_id FK
        DECIMAL quantity_kg
        DATE received_date
        VARCHAR certificate_number
    }

    Medicines {
        INT medicine_id PK
        VARCHAR brand_name
        INT manufacturer_id FK
        VARCHAR dosage_form
        VARCHAR pack_size
        VARCHAR therapeutic_class
        TINYINT habit_forming
        TEXT storage_note
        TEXT source_note
    }

    Drug_Formulations {
        INT medicine_id FK
        INT ingredient_id FK
        VARCHAR strength
        TINYINT is_active
    }

    Medicine_Info {
        INT info_id PK
        INT medicine_id FK
        ENUM info_type
        TEXT info_text
    }

    Production_Batches {
        INT batch_id PK
        VARCHAR batch_number
        INT medicine_id FK
        INT factory_id FK
        INT quantity_units
        DATE manufacture_date
        DATE expiry_date
        ENUM status
    }

    Batch_Materials {
        INT batch_id FK
        INT delivery_id FK
        DECIMAL quantity_used_kg
    }

    Quality_Test_Reports {
        INT report_id PK
        INT batch_id FK
        INT tested_by FK
        DATE test_date
        DECIMAL purity_pct
        DECIMAL dissolution_pct
        DECIMAL weight_variation_pct
        ENUM result
        TEXT remarks
    }

    QR_Codes {
        INT qr_id PK
        VARCHAR code
        INT batch_id FK
        DATETIME issued_at
    }

    Scan_Log {
        INT scan_id PK
        VARCHAR scanned_code
        INT qr_id FK
        DATETIME scanned_at
        ENUM verdict
    }

    Product_Recalls {
        INT recall_id PK
        INT batch_id FK
        TEXT reason
        DATE recall_date
        INT issued_by FK
    }

    Audit_Logs {
        BIGINT log_id PK
        INT user_id FK
        VARCHAR action
        VARCHAR table_name
        INT record_id
        TEXT details
        DATETIME logged_at
    }

    Roles            ||--o{ Users               : "has"
    Manufacturers    ||--o{ Users               : "employs"
    Manufacturers    ||--o{ Factories            : "owns"
    Manufacturers    ||--o{ Material_Deliveries  : "receives"
    Manufacturers    ||--o{ Medicines            : "makes"
    Suppliers        ||--o{ Material_Deliveries  : "supplies"
    Ingredients      ||--o{ Material_Deliveries  : "delivered via"
    Ingredients      ||--o{ Drug_Formulations    : "used in"
    Medicines        ||--o{ Drug_Formulations    : "contains"
    Medicines        ||--o{ Medicine_Info        : "has info"
    Medicines        ||--o{ Production_Batches   : "produced as"
    Factories        ||--o{ Production_Batches   : "produces"
    Material_Deliveries ||--o{ Batch_Materials   : "consumed in"
    Production_Batches  ||--o{ Batch_Materials   : "uses"
    Production_Batches  ||--o{ Quality_Test_Reports : "tested by"
    Production_Batches  ||--o{ QR_Codes          : "issued (one per pack)"
    Production_Batches  ||--o| Product_Recalls   : "recalled as"
    QR_Codes         ||--o{ Scan_Log             : "scanned"
    Users            ||--o{ Quality_Test_Reports : "conducts"
    Users            ||--o{ Product_Recalls      : "issues"
    Users            ||--o{ Audit_Logs           : "logged"
```

---

## Plain-English Relationship Guide

### 1-to-Many (one parent → many children)

| Relationship | Description |
|---|---|
| **Roles → Users** | One role (Admin/Regulator or Manufacturer) can be assigned to many users. |
| **Manufacturers → Users** | One manufacturer company can have many user accounts. Admin users have `manufacturer_id = NULL`. |
| **Manufacturers → Factories** | A manufacturing company can own and operate many factories. |
| **Manufacturers → Material_Deliveries** | A manufacturer receives many raw-material deliveries over time. |
| **Manufacturers → Medicines** | A manufacturer is responsible for many medicine products. |
| **Suppliers → Material_Deliveries** | One supplier makes many deliveries of ingredients. |
| **Ingredients → Material_Deliveries** | The same ingredient can arrive in many separate deliveries. |
| **Medicines → Medicine_Info** | A medicine has many info rows — one per use, side-effect, or drug interaction. |
| **Medicines → Production_Batches** | A medicine is manufactured in many batches over time. |
| **Factories → Production_Batches** | A factory produces many batches (of possibly different medicines). |
| **Production_Batches → Quality_Test_Reports** | A batch can be tested many times (re-tests allowed). |
| **Batch 1-to-many QR_Codes (one code per pack)** | Every approved batch yields many QR codes — one per physical pack/unit. Repeated scans of the same code are flagged as a possible counterfeit. |
| **QR_Codes → Scan_Log** | One QR code can be scanned many times by different members of the public. |
| **Users → Quality_Test_Reports** | One QA officer can conduct many tests. |
| **Users → Product_Recalls** | One admin can issue many recalls over time. |
| **Users → Audit_Logs** | Every action a user takes produces many log entries. |

---

### Many-to-Many (resolved via a junction table)

| Relationship | Junction Table | Extra Columns |
|---|---|---|
| **Medicines ↔ Ingredients** | `Drug_Formulations` | `strength` (e.g. 500 mg), `is_active` flag |
| **Production_Batches ↔ Material_Deliveries** | `Batch_Materials` | `quantity_used_kg` — how much of each delivery was consumed |

Both junction tables use **composite primary keys** (no surrogate ID), which is standard relational practice.

---

### 1-to-1 (enforced by UNIQUE constraint)

| Relationship | How enforced |
|---|---|
| **Production_Batches ↔ Product_Recalls** | `UNIQUE(batch_id)` on Product_Recalls — a batch can be recalled at most once. |

---

### Special Design Notes

- **`Scan_Log.scanned_code`** is a plain `VARCHAR`, **not** a foreign key.  
  This lets the system store scans of completely unknown or counterfeit codes without failing a FK constraint.  
  `qr_id` is a *nullable* FK — it is `NULL` when the scanned code matched nothing in QR_Codes.

- **`Audit_Logs.user_id`** is nullable to allow system-generated log entries (e.g. from triggers) where no human triggered the action.

- **`Medicine_Info`** and **`Drug_Formulations`** exist to eliminate repeating column groups from Medicines — a key normalization step explained in `docs/normalization.md`.
