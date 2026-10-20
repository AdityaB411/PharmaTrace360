-- =============================================================
-- 06_queries.sql - 14 Labelled SELECT-Only Demonstration Queries
-- PharmaTrace 360 - MySQL 8.0+
-- All queries are read-only (SELECT only). No data is modified.
-- Run AFTER 01_schema.sql, 02_seed.sql and 03_logic.sql.
-- =============================================================
-- HOW TO RUN:
--   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p ^
--     pharmatrace360 < "E:\DBMS\PharmaTrace360\db\06_queries.sql"
-- =============================================================

USE pharmatrace360;

-- =============================================================
-- Q1: INNER JOIN
-- Every QR code with its batch number, medicine brand name and
-- the factory that produced it.
-- Demonstrates: Three-table INNER JOIN.
-- =============================================================
SELECT '--- Q1: INNER JOIN - QR codes with batch and medicine ---' AS query_label;
SELECT
    qr.code            AS qr_code,
    pb.batch_number,
    m.brand_name       AS medicine,
    f.factory_name     AS factory,
    qr.issued_at
FROM QR_Codes          qr
JOIN Production_Batches pb  ON pb.batch_id   = qr.batch_id
JOIN Medicines          m   ON m.medicine_id  = pb.medicine_id
JOIN Factories          f   ON f.factory_id   = pb.factory_id
ORDER BY qr.issued_at DESC
LIMIT 20;


-- =============================================================
-- Q2: LEFT JOIN - Batches Without QR Codes
-- Lists every batch that has not yet had any QR code issued.
-- Useful to identify Pending or Rejected batches waiting for
-- approval, or Approved batches where QR generation was missed.
-- Demonstrates: LEFT JOIN with NULL filter (anti-join pattern).
-- =============================================================
SELECT '--- Q2: LEFT JOIN - Batches with no QR codes ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name       AS medicine,
    mfr.company_name   AS manufacturer,
    pb.status,
    pb.manufacture_date
FROM Production_Batches pb
JOIN Medicines          m   ON m.medicine_id      = pb.medicine_id
JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
LEFT JOIN QR_Codes      qr  ON qr.batch_id        = pb.batch_id
WHERE qr.qr_id IS NULL
ORDER BY pb.manufacture_date DESC;


-- =============================================================
-- Q3: GROUP BY with HAVING
-- Suppliers who have supplied more than one type of ingredient,
-- showing the count of distinct ingredients per supplier.
-- Demonstrates: GROUP BY, HAVING with aggregate condition.
-- =============================================================
SELECT '--- Q3: GROUP BY HAVING - Suppliers with multiple ingredients ---' AS query_label;
SELECT
    s.supplier_name,
    COUNT(DISTINCT md.ingredient_id) AS distinct_ingredients,
    SUM(md.quantity_kg)              AS total_kg_delivered
FROM Suppliers          s
JOIN Material_Deliveries md ON md.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.supplier_name
HAVING COUNT(DISTINCT md.ingredient_id) > 1
ORDER BY distinct_ingredients DESC;


-- =============================================================
-- Q4: Scalar Subquery
-- For each batch, show its name and the total quantity of raw
-- materials (kg) consumed - computed as a scalar subquery.
-- Demonstrates: Correlated scalar subquery in SELECT list.
-- =============================================================
SELECT '--- Q4: Scalar Subquery - Raw material consumption per batch ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name       AS medicine,
    pb.status,
    (SELECT COALESCE(SUM(bm.quantity_used_kg), 0)
     FROM Batch_Materials bm
     WHERE bm.batch_id = pb.batch_id) AS total_materials_used_kg
FROM Production_Batches pb
JOIN Medicines          m ON m.medicine_id = pb.medicine_id
ORDER BY total_materials_used_kg DESC
LIMIT 15;


-- =============================================================
-- Q5: Correlated Subquery
-- Batches whose latest quality test result was 'Fail'.
-- The subquery is correlated on batch_id.
-- Demonstrates: Correlated subquery using ORDER BY + LIMIT 1.
-- =============================================================
SELECT '--- Q5: Correlated Subquery - Batches whose latest QA test was Fail ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name   AS medicine,
    mfr.company_name AS manufacturer,
    pb.status
FROM Production_Batches pb
JOIN Medicines           m   ON m.medicine_id      = pb.medicine_id
JOIN Manufacturers       mfr ON mfr.manufacturer_id = m.manufacturer_id
WHERE (
    SELECT result
    FROM Quality_Test_Reports qtr
    WHERE qtr.batch_id = pb.batch_id
    ORDER BY qtr.test_date DESC, qtr.report_id DESC
    LIMIT 1
) = 'Fail'
ORDER BY pb.batch_number;


-- =============================================================
-- Q6: IN Subquery
-- All batches produced by manufacturers who have had at least
-- one product recall - using an IN subquery.
-- Demonstrates: IN (...subquery) filtering.
-- =============================================================
SELECT '--- Q6: IN Subquery - Batches from manufacturers with at least one recall ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name       AS medicine,
    mfr.company_name   AS manufacturer,
    pb.status
FROM Production_Batches pb
JOIN Medicines          m   ON m.medicine_id      = pb.medicine_id
JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
WHERE mfr.manufacturer_id IN (
    SELECT DISTINCT f2.manufacturer_id
    FROM Product_Recalls pr
    JOIN Production_Batches pb2 ON pb2.batch_id = pr.batch_id
    JOIN Factories          f2  ON f2.factory_id = pb2.factory_id
)
ORDER BY mfr.company_name, pb.batch_number;


-- =============================================================
-- Q7: NOT EXISTS - Batches with No Quality Test
-- Finds all batches for which no Quality_Test_Reports row exists.
-- Demonstrates: NOT EXISTS (correlated anti-join).
-- =============================================================
SELECT '--- Q7: NOT EXISTS - Batches with no quality test ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name       AS medicine,
    mfr.company_name   AS manufacturer,
    pb.status,
    pb.manufacture_date
FROM Production_Batches pb
JOIN Medicines          m   ON m.medicine_id      = pb.medicine_id
JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM Quality_Test_Reports qtr
    WHERE qtr.batch_id = pb.batch_id
)
ORDER BY pb.manufacture_date;


-- =============================================================
-- Q8: CTE - Fail Rate per Manufacturer
-- Computes the quality test fail rate for each manufacturer.
-- Demonstrates: Common Table Expression (WITH clause).
-- =============================================================
SELECT '--- Q8: CTE - Quality test fail rate per manufacturer ---' AS query_label;
WITH manufacturer_test_stats AS (
    SELECT
        mfr.company_name                           AS manufacturer,
        COUNT(qtr.report_id)                       AS total_tests,
        SUM(CASE WHEN qtr.result = 'Fail' THEN 1 ELSE 0 END) AS failed_tests
    FROM Quality_Test_Reports qtr
    JOIN Production_Batches   pb  ON pb.batch_id        = qtr.batch_id
    JOIN Factories             f   ON f.factory_id       = pb.factory_id
    JOIN Manufacturers         mfr ON mfr.manufacturer_id = f.manufacturer_id
    GROUP BY mfr.manufacturer_id, mfr.company_name
)
SELECT
    manufacturer,
    total_tests,
    failed_tests,
    ROUND(failed_tests / total_tests * 100, 1) AS fail_rate_pct
FROM manufacturer_test_stats
WHERE total_tests > 0
ORDER BY fail_rate_pct DESC;


-- =============================================================
-- Q9a: Window Function - ROW_NUMBER for Latest Test per Batch
-- Assigns row number 1 to the most recent test for each batch.
-- Filtering for rn = 1 gives the definitive "latest test".
-- Demonstrates: ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...).
-- =============================================================
SELECT '--- Q9a: Window ROW_NUMBER - Latest test per batch ---' AS query_label;
SELECT
    batch_number,
    medicine,
    test_date,
    result,
    purity_pct,
    dissolution_pct,
    rn
FROM (
    SELECT
        pb.batch_number,
        m.brand_name                  AS medicine,
        qtr.test_date,
        qtr.result,
        qtr.purity_pct,
        qtr.dissolution_pct,
        ROW_NUMBER() OVER (
            PARTITION BY qtr.batch_id
            ORDER BY qtr.test_date DESC, qtr.report_id DESC
        ) AS rn
    FROM Quality_Test_Reports qtr
    JOIN Production_Batches   pb ON pb.batch_id  = qtr.batch_id
    JOIN Medicines             m  ON m.medicine_id = pb.medicine_id
) ranked
WHERE rn = 1
ORDER BY batch_number;


-- =============================================================
-- Q9b: Window Function - RANK of Manufacturers by Approved Batches
-- Ranks manufacturers by their count of Approved batches.
-- Demonstrates: RANK() OVER (ORDER BY ...) for leaderboard ranking.
-- =============================================================
SELECT '--- Q9b: Window RANK - Manufacturers ranked by approved batch count ---' AS query_label;
SELECT
    mfr.company_name                                  AS manufacturer,
    COUNT(pb.batch_id)                                AS approved_batches,
    RANK() OVER (ORDER BY COUNT(pb.batch_id) DESC)    AS ranking
FROM Manufacturers      mfr
LEFT JOIN Factories      f   ON f.manufacturer_id  = mfr.manufacturer_id
LEFT JOIN Production_Batches pb ON pb.factory_id   = f.factory_id
                               AND pb.status       = 'Approved'
GROUP BY mfr.manufacturer_id, mfr.company_name
ORDER BY ranking;


-- =============================================================
-- Q9c: Window Function - Running Scan Count per QR Code
-- Shows each scan with a running cumulative count for that code.
-- Demonstrates: SUM() OVER (PARTITION BY ... ORDER BY ...) as a
-- running total window function.
-- =============================================================
SELECT '--- Q9c: Window Running Total - Cumulative scan count per QR code ---' AS query_label;
SELECT
    sl.scanned_code,
    sl.scanned_at,
    sl.verdict,
    SUM(1) OVER (
        PARTITION BY sl.scanned_code
        ORDER BY sl.scanned_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_scan_count
FROM Scan_Log sl
ORDER BY sl.scanned_code, sl.scanned_at
LIMIT 50;


-- =============================================================
-- Q10: UNION
-- Lists both approved batches and recalled batches in one result
-- set with a type label, combining two separate queries.
-- Demonstrates: UNION (deduplication) of two SELECT statements.
-- =============================================================
SELECT '--- Q10: UNION - Approved and Recalled batches combined ---' AS query_label;
SELECT
    'Approved'         AS lifecycle_state,
    pb.batch_number,
    m.brand_name       AS medicine,
    pb.manufacture_date,
    pb.expiry_date
FROM Production_Batches pb
JOIN Medicines          m ON m.medicine_id = pb.medicine_id
WHERE pb.status = 'Approved'

UNION

SELECT
    'Recalled'         AS lifecycle_state,
    pb.batch_number,
    m.brand_name       AS medicine,
    pb.manufacture_date,
    pb.expiry_date
FROM Production_Batches pb
JOIN Medicines          m ON m.medicine_id = pb.medicine_id
WHERE pb.status = 'Recalled'

ORDER BY lifecycle_state, batch_number;


-- =============================================================
-- Q11: CASE Expression
-- Classifies each batch by days to expiry into risk categories.
-- Demonstrates: CASE expression for conditional column labelling.
-- =============================================================
SELECT '--- Q11: CASE - Expiry risk classification of approved batches ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name                                  AS medicine,
    pb.expiry_date,
    DATEDIFF(pb.expiry_date, CURDATE())            AS days_to_expiry,
    CASE
        WHEN pb.expiry_date < CURDATE()                            THEN 'EXPIRED'
        WHEN DATEDIFF(pb.expiry_date, CURDATE()) <= 90            THEN 'EXPIRING SOON (<90 days)'
        WHEN DATEDIFF(pb.expiry_date, CURDATE()) <= 365           THEN 'WITHIN 1 YEAR'
        ELSE                                                            'MORE THAN 1 YEAR'
    END                                            AS expiry_risk
FROM Production_Batches pb
JOIN Medicines          m ON m.medicine_id = pb.medicine_id
WHERE pb.status = 'Approved'
ORDER BY days_to_expiry ASC;


-- =============================================================
-- Q12: Date Function - Days to Expiry
-- Shows each approved, non-expired batch sorted by urgency using
-- DATEDIFF() and CURDATE().
-- Demonstrates: Date arithmetic functions.
-- =============================================================
SELECT '--- Q12: Date Function - Days to expiry for active batches ---' AS query_label;
SELECT
    pb.batch_number,
    m.brand_name                         AS medicine,
    mfr.company_name                     AS manufacturer,
    pb.expiry_date,
    DATEDIFF(pb.expiry_date, CURDATE())  AS days_to_expiry,
    CURDATE()                            AS today
FROM Production_Batches pb
JOIN Medicines          m   ON m.medicine_id      = pb.medicine_id
JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
WHERE pb.status = 'Approved'
  AND pb.expiry_date >= CURDATE()
ORDER BY days_to_expiry ASC;


-- =============================================================
-- Q13: BACKWARD TRACE - QR Code to Batch, Materials and Suppliers
-- Given a QR code value (by name/code string, not hard-coded ID),
-- traces backward through the supply chain:
--   QR code -> batch -> materials -> deliveries -> suppliers
-- Demonstrates: Multi-table join backward trace, real-world forensics.
-- Change the code value to trace any QR code in the database.
-- =============================================================
SELECT '--- Q13: BACKWARD TRACE - QR code to batch, materials, suppliers ---' AS query_label;
SELECT
    qr.code                         AS qr_code,
    pb.batch_number,
    m.brand_name                    AS medicine,
    mfr.company_name                AS manufacturer,
    pb.manufacture_date,
    pb.expiry_date,
    pb.status                       AS batch_status,
    ing.ingredient_name             AS material,
    md.quantity_kg                  AS delivered_kg,
    bm.quantity_used_kg             AS used_kg,
    md.received_date                AS delivery_received,
    md.certificate_number           AS certificate,
    s.supplier_name                 AS supplier,
    s.contact_email                 AS supplier_email
FROM QR_Codes            qr
JOIN Production_Batches  pb  ON pb.batch_id       = qr.batch_id
JOIN Medicines           m   ON m.medicine_id     = pb.medicine_id
JOIN Factories           f   ON f.factory_id      = pb.factory_id
JOIN Manufacturers       mfr ON mfr.manufacturer_id = f.manufacturer_id
LEFT JOIN Batch_Materials bm  ON bm.batch_id      = pb.batch_id
LEFT JOIN Material_Deliveries md ON md.delivery_id = bm.delivery_id
LEFT JOIN Ingredients    ing ON ing.ingredient_id = md.ingredient_id
LEFT JOIN Suppliers      s   ON s.supplier_id     = md.supplier_id
WHERE qr.code = 'PT360-20515ECBE7F2'   -- Change to any code to trace backward
ORDER BY md.received_date;


-- =============================================================
-- Q14: FORWARD TRACE - Certificate Number to Batches, QR Codes and Scans
-- Given a delivery Certificate of Analysis number (by name, not ID),
-- traces forward through the supply chain:
--   Certificate -> delivery -> batch -> QR codes -> scans
-- Demonstrates: Multi-table join forward trace, supply-chain recall analysis.
-- Change the certificate value to trace any delivery.
-- =============================================================
SELECT '--- Q14: FORWARD TRACE - Certificate to batches, QR codes and scans ---' AS query_label;
SELECT
    md.certificate_number,
    ing.ingredient_name             AS material,
    s.supplier_name                 AS supplier,
    md.received_date,
    md.quantity_kg                  AS delivered_kg,
    bm.quantity_used_kg             AS used_in_batch_kg,
    pb.batch_number,
    m.brand_name                    AS medicine,
    pb.status                       AS batch_status,
    qr.code                         AS qr_code,
    qr.issued_at                    AS qr_issued,
    sl.scanned_at,
    sl.verdict
FROM Material_Deliveries md
JOIN Ingredients         ing ON ing.ingredient_id = md.ingredient_id
JOIN Suppliers           s   ON s.supplier_id     = md.supplier_id
JOIN Batch_Materials     bm  ON bm.delivery_id    = md.delivery_id
JOIN Production_Batches  pb  ON pb.batch_id       = bm.batch_id
JOIN Medicines           m   ON m.medicine_id     = pb.medicine_id
LEFT JOIN QR_Codes       qr  ON qr.batch_id       = pb.batch_id
LEFT JOIN Scan_Log       sl  ON sl.qr_id          = qr.qr_id
WHERE md.certificate_number = 'COA-2024-0001'   -- Change to trace any certificate
ORDER BY pb.batch_number, qr.issued_at, sl.scanned_at;

-- =============================================================
-- End of 06_queries.sql
-- =============================================================
