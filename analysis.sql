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

-- ============================================================
-- SECTION 3: PARENT ORGANISATION ANALYSIS
-- Which organisations control the most hospitals?
-- ============================================================

-- 3.1 Top 15 parent organisations by hospital count
SELECT
    ParentName,
    Sector,
    COUNT(*) AS hospitals_managed,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitals), 2) AS pct_of_total
FROM hospitals
WHERE ParentName IS NOT NULL AND ParentName != ''
GROUP BY ParentName, Sector
ORDER BY hospitals_managed DESC
LIMIT 15;

-- 3.2 Top NHS parent organisations only
SELECT
    ParentName,
    COUNT(*) AS nhs_hospitals,
    COUNT(DISTINCT County) AS counties_covered
FROM hospitals
WHERE Sector = 'NHS Sector'
AND ParentName IS NOT NULL AND ParentName != ''
GROUP BY ParentName
ORDER BY nhs_hospitals DESC
LIMIT 10;

-- 3.3 Top Independent sector parent organisations
SELECT
    ParentName,
    COUNT(*) AS independent_hospitals,
    COUNT(DISTINCT County) AS counties_covered
FROM hospitals
WHERE Sector = 'Independent Sector'
AND ParentName IS NOT NULL AND ParentName != ''
GROUP BY ParentName
ORDER BY independent_hospitals DESC
LIMIT 10;

-- 3.4 Geographic reach of largest parent organisations
-- Subquery to find parents managing 20 or more hospitals
SELECT
    p.ParentName,
    p.Sector,
    p.hospitals_managed,
    COUNT(DISTINCT h.County) AS counties_present,
    COUNT(DISTINCT h.City) AS cities_present
FROM (
    SELECT ParentName, Sector, COUNT(*) AS hospitals_managed
    FROM hospitals
    GROUP BY ParentName, Sector
    HAVING COUNT(*) >= 20
) p
JOIN hospitals h ON h.ParentName = p.ParentName
GROUP BY p.ParentName, p.Sector, p.hospitals_managed
ORDER BY p.hospitals_managed DESC;

-- ============================================================
-- SECTION 4: SECTOR COMPARISON ANALYSIS
-- Deep dive into NHS vs Independent sector differences
-- using Common Table Expressions (CTEs)
-- ============================================================

-- 4.1 NHS vs Independent breakdown by SubType
SELECT
    Sector,
    SubType,
    COUNT(*) AS hospital_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Sector), 1) AS pct_within_sector
FROM hospitals
GROUP BY Sector, SubType
ORDER BY Sector, hospital_count DESC;

-- 4.2 Counties where NHS provision is significantly below average
-- Step 1: Calculate NHS percentage per county
-- Step 2: Calculate the national average NHS percentage
-- Step 3: Compare each county against the average
WITH county_totals AS (
    SELECT
        County,
        COUNT(*) AS total,
        SUM(CASE WHEN Sector = 'NHS Sector' THEN 1 ELSE 0 END) AS nhs_count,
        ROUND(SUM(CASE WHEN Sector = 'NHS Sector' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS nhs_pct
    FROM hospitals
    WHERE County IS NOT NULL AND County != ''
    GROUP BY County
    HAVING COUNT(*) >= 8
),
avg_nhs AS (
    SELECT ROUND(AVG(nhs_pct), 1) AS avg_nhs_percentage
    FROM county_totals
)
SELECT
    ct.County,
    ct.total AS total_hospitals,
    ct.nhs_count,
    ct.nhs_pct,
    a.avg_nhs_percentage,
    ROUND(ct.nhs_pct - a.avg_nhs_percentage, 1) AS variance_from_average
FROM county_totals ct, avg_nhs a
WHERE ct.nhs_pct < a.avg_nhs_percentage
ORDER BY variance_from_average ASC
LIMIT 10;

-- 4.3 Sector balance summary per county
-- Classifying each county by its NHS dominance level
WITH county_balance AS (
    SELECT
        County,
        COUNT(*) AS total_hospitals,
        ROUND(SUM(CASE WHEN Sector = 'NHS Sector' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS nhs_pct
    FROM hospitals
    WHERE County IS NOT NULL AND County != ''
    GROUP BY County
    HAVING COUNT(*) >= 5
)
SELECT
    CASE
        WHEN nhs_pct >= 75 THEN 'Predominantly NHS (75%+)'
        WHEN nhs_pct >= 50 THEN 'NHS Majority (50-74%)'
        WHEN nhs_pct >= 25 THEN 'Independent Majority (25-49% NHS)'
        ELSE 'Predominantly Independent (under 25% NHS)'
    END AS sector_profile,
    COUNT(*) AS number_of_counties,
    ROUND(AVG(total_hospitals), 1) AS avg_hospitals_per_county
FROM county_balance
GROUP BY sector_profile
ORDER BY number_of_counties DESC;

-- ============================================================
-- SECTION 5: WINDOW FUNCTIONS
-- Ranking and comparative analysis across sectors and regions
-- ============================================================

-- 5.1 Rank parent organisations within each sector
-- Shows relative size of each organisation compared to sector peers
WITH org_sizes AS (
    SELECT
        ParentName,
        Sector,
        COUNT(*) AS hospital_count
    FROM hospitals
    WHERE ParentName IS NOT NULL AND ParentName != ''
    GROUP BY ParentName, Sector
)
SELECT
    ParentName,
    Sector,
    hospital_count,
    RANK() OVER (PARTITION BY Sector ORDER BY hospital_count DESC) AS rank_in_sector,
    ROUND(hospital_count * 100.0 / SUM(hospital_count) OVER (PARTITION BY Sector), 2) AS pct_of_sector
FROM org_sizes
ORDER BY Sector, rank_in_sector
LIMIT 20;

-- 5.2 Running total of hospitals by county alphabetically
-- Demonstrates cumulative SUM window function
SELECT
    County,
    COUNT(*) AS hospitals_in_county,
    SUM(COUNT(*)) OVER (
        ORDER BY County
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM hospitals
WHERE County IS NOT NULL AND County != ''
GROUP BY County
ORDER BY County;

-- 5.3 Compare each county's hospital count against the national average
-- Using AVG as a window function across the full dataset
WITH county_counts AS (
    SELECT
        County,
        COUNT(*) AS total_hospitals
    FROM hospitals
    WHERE County IS NOT NULL AND County != ''
    GROUP BY County
)
SELECT
    County,
    total_hospitals,
    ROUND(AVG(total_hospitals) OVER (), 1) AS national_avg,
    total_hospitals - ROUND(AVG(total_hospitals) OVER (), 1) AS variance_from_avg,
    RANK() OVER (ORDER BY total_hospitals DESC) AS national_rank
FROM county_counts
ORDER BY national_rank
LIMIT 15;

-- 5.4 Cumulative share of Independent sector hospitals by parent organisation
-- Shows how concentrated Independent sector provision is
WITH independent_orgs AS (
    SELECT
        ParentName,
        COUNT(*) AS hospital_count
    FROM hospitals
    WHERE Sector = 'Independent Sector'
    AND ParentName IS NOT NULL AND ParentName != ''
    GROUP BY ParentName
)
SELECT
    ParentName,
    hospital_count,
    RANK() OVER (ORDER BY hospital_count DESC) AS org_rank,
    ROUND(SUM(hospital_count) OVER (
        ORDER BY hospital_count DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) * 100.0 / SUM(hospital_count) OVER (), 1) AS cumulative_pct
FROM independent_orgs
ORDER BY org_rank
LIMIT 15;
