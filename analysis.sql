-- ============================================================
-- UK NHS Hospital Landscape Analysis
-- Author: Ali Hazem
-- Dataset: NHS Hospital Register (Kaggle)
-- Business Question: How is UK hospital provision distributed
-- across NHS and Independent sectors, and which regions and
-- parent organisations dominate the landscape?
-- ============================================================


-- ============================================================
-- SECTION 1: DATA EXPLORATION
-- Understanding the shape and quality of the dataset
-- ============================================================

-- 1.1 Total number of hospitals in the dataset
SELECT COUNT(*) AS total_hospitals
FROM hospitals;

-- 1.2 Breakdown by sector
SELECT
    Sector,
    COUNT(*) AS hospital_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitals), 1) AS percentage
FROM hospitals
GROUP BY Sector
ORDER BY hospital_count DESC;

-- 1.3 Breakdown by hospital subtype
SELECT
    SubType,
    COUNT(*) AS hospital_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitals), 1) AS percentage
FROM hospitals
GROUP BY SubType
ORDER BY hospital_count DESC;

-- 1.4 Check data quality: missing values in key columns
SELECT
    SUM(CASE WHEN City IS NULL OR City = '' THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN County IS NULL OR County = '' THEN 1 ELSE 0 END) AS missing_county,
    SUM(CASE WHEN ParentName IS NULL OR ParentName = '' THEN 1 ELSE 0 END) AS missing_parent,
    SUM(CASE WHEN Postcode IS NULL OR Postcode = '' THEN 1 ELSE 0 END) AS missing_postcode
FROM hospitals;
