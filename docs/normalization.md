# PharmaTrace 360 — Normalization Notes

> **Audience:** 2nd-year B.Tech students.  
> This document explains — in plain English — how the database design satisfies
> 1NF, 2NF, 3NF, and BCNF, and **why** some tables exist purely to enforce
> those rules.

---

## What is Normalization?

Normalization is the process of organizing a database so that:

1. Data is stored in **exactly one place** (no duplication).
2. Every column in a table is **about the primary key** — nothing else.
3. Updating or deleting a row cannot accidentally break other data.

The normal forms are a checklist: each one fixes a specific problem.

---

## 1NF — First Normal Form

**Rule:** Every column must hold a **single, atomic value** (no lists or
repeating groups inside a cell).

### Problem this solves

The raw CSV (`medicines_15.csv`) has columns like:

```
uses            = "Pain relief; Treatment of Fever"
side_effects    = "Stomach pain; Nausea; Vomiting"
when_to_avoid   = "Nimesulide; Oxyphenbutazone"
active_ingredient_1, strength_1, active_ingredient_2, strength_2 ...
```

These are **repeating groups** — multiple facts crammed into one cell, or
spread across numbered column pairs. That violates 1NF.

### How we fixed it

| Problem column(s) in CSV | Separate table created | What each row stores |
|---|---|---|
| `uses`, `side_effects`, `when_to_avoid` | **`Medicine_Info`** | One row per fact, tagged with `info_type` = `'use'`, `'side_effect'`, or `'avoid_with'` |
| `active_ingredient_1/2`, `strength_1/2` | **`Drug_Formulations`** | One row per medicine–ingredient pair with its strength |

Result: every cell in every table holds exactly one value. ✅

---

## 2NF — Second Normal Form

**Rule:** Every non-key column must depend on the **whole** primary key, not
just part of it. (Only matters when the PK is composite.)

### Tables with composite PKs

| Table | Composite PK | Non-key column | Depends on whole PK? |
|---|---|---|---|
| `Drug_Formulations` | `(medicine_id, ingredient_id)` | `strength` | ✅ — strength is a property of this specific medicine+ingredient pairing |
| `Drug_Formulations` | same | `is_active` | ✅ — same reason |
| `Batch_Materials` | `(batch_id, delivery_id)` | `quantity_used_kg` | ✅ — how much of *this delivery* was used in *this batch* |

Neither junction table has columns that depend on only one part of the key,
so both are in 2NF. ✅

---

## 3NF — Third Normal Form

**Rule:** Non-key columns must depend **directly on the primary key**, not on
another non-key column (no transitive dependencies).

### Example: Medicines table

An earlier (un-normalized) idea might have been:

```
Medicines(medicine_id, brand_name, manufacturer_name, manufacturer_city)
```

Here `manufacturer_city` depends on `manufacturer_name`, not on `medicine_id`.
That is a transitive dependency — a 3NF violation.

**Fix:** We moved manufacturer data into its own `Manufacturers` table and
stored only `manufacturer_id` (a FK) in `Medicines`. Now every column in
`Medicines` tells us something directly about the medicine itself. ✅

### Another example: Production_Batches

We store `factory_id`, not `factory_location` directly. Factory details live
in the `Factories` table. No transitive dependency. ✅

---

## BCNF — Boyce–Codd Normal Form

**Rule:** Every determinant (column or combination that uniquely identifies
another column) must be a candidate key.

BCNF is a slightly stricter version of 3NF. A table violates BCNF only when
a non-key attribute determines part of the key.

### Does our schema violate BCNF?

Check `Drug_Formulations (medicine_id, ingredient_id, strength, is_active)`:

- The only determinant is `(medicine_id, ingredient_id)` — the full PK.
- `strength` and `is_active` do not determine any part of the PK.
- ✅ BCNF satisfied.

Check `Batch_Materials (batch_id, delivery_id, quantity_used_kg)`:

- The only determinant is `(batch_id, delivery_id)` — the full PK.
- ✅ BCNF satisfied.

All other tables have simple (single-column) primary keys, so BCNF reduces
to 3NF for them — and we have already shown 3NF holds. ✅

---

## Summary Table

| Normal Form | Core Requirement | How PharmaTrace 360 satisfies it |
|---|---|---|
| **1NF** | No repeating groups; atomic values | `Medicine_Info` splits uses/side-effects/interactions. `Drug_Formulations` splits ingredient-strength pairs. |
| **2NF** | All non-key columns depend on the *whole* PK | Junction tables only store data meaningful to the full composite key. |
| **3NF** | No transitive dependencies | Manufacturer, factory, supplier, ingredient data each live in their own table; only FKs appear in child tables. |
| **BCNF** | Every determinant is a candidate key | No non-key column determines any part of any key in any table. |

> **Key takeaway for the report:** The existence of `Medicine_Info` and
> `Drug_Formulations` is not optional — they are required by normalization
> theory to bring the Medicines data into 1NF and 2NF.
