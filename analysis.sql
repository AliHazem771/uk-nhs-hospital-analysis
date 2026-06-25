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

-- ============================================================
-- SECTION 2: GEOGRAPHIC DISTRIBUTION
-- Where are hospitals concentrated across the UK?
-- ============================================================

-- 2.1 Top 15 counties by total hospital count with sector split
SELECT
    County,
    COUNT(*) AS total_hospitals,
    SUM(CASE WHEN Sector = 'NHS Sector' THEN 1 ELSE 0 END) AS nhs_hospitals,
    SUM(CASE WHEN Sector = 'Independent Sector' THEN 1 ELSE 0 END) AS independent_hospitals
FROM hospitals
WHERE County IS NOT NULL AND County != ''
GROUP BY County
ORDER BY total_hospitals DESC
LIMIT 15;

-- 2.2 Top 10 cities by hospital count with sector split
SELECT
    City,
    COUNT(*) AS total_hospitals,
    SUM(CASE WHEN Sector = 'NHS Sector' THEN 1 ELSE 0 END) AS nhs_count,
    SUM(CASE WHEN Sector = 'Independent Sector' THEN 1 ELSE 0 END) AS independent_count,
    ROUND(SUM(CASE WHEN Sector = 'Independent Sector' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS independent_pct
FROM hospitals
WHERE City IS NOT NULL AND City != ''
GROUP BY City
ORDER BY total_hospitals DESC
LIMIT 10;

-- 2.3 Counties with highest proportion of Independent sector hospitals
-- Useful for identifying areas with potentially lower NHS provision
SELECT
    County,
    COUNT(*) AS total_hospitals,
    SUM(CASE WHEN Sector = 'Independent Sector' THEN 1 ELSE 0 END) AS independent_count,
    ROUND(SUM(CASE WHEN Sector = 'Independent Sector' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS independent_pct
FROM hospitals
WHERE County IS NOT NULL AND County != ''
GROUP BY County
HAVING COUNT(*) >= 10
ORDER BY independent_pct DESC
LIMIT 10;
