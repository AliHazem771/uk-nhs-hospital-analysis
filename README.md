# UK NHS Hospital Landscape Analysis

## Business Question
How is UK hospital provision distributed across NHS and Independent sectors, 
and which regions and parent organisations dominate the landscape?

## Overview
SQL analysis of 1,211 registered UK hospitals exploring sector balance, 
geographic concentration, and parent organisation dominance across the country.

## Tools
- SQL (SQLite)
- Python (pandas) for data loading and cleaning

## Dataset
- Source: Kaggle - UK NHS Hospital Register
- 1,211 rows, 22 columns
- Key fields: OrganisationName, Sector, SubType, City, County, ParentName

## Status
Work in progress - queries being added daily.

## SQL Queries - Progress

- [x] Section 1: Data Exploration
- [x] Section 2: Geographic Distribution
- [x] Section 3: Parent Organisation Analysis
- [x] Section 4: Sector Comparison
- [ ] Section 5: Window Functions
- [ ] Section 6: Summary Findings

## Key Findings So Far

- Kent has the highest concentration of hospitals in the UK with 51 total
- London leads at city level with 95 hospitals, well ahead of Birmingham (34)
- Oxfordshire has the highest Independent sector proportion at 73.7% of all 
  hospitals in the county, suggesting relatively lower NHS provision in the area
- BMI Healthcare is the largest Independent sector operator with 43 hospitals, 
  followed by Spire Healthcare (33) and Nuffield Health (29)
- The top 4 Independent sector organisations manage 133 hospitals combined, 
  representing 28.4% of all Independent sector provision
- NHS parent organisations tend to have more localised footprints compared 
  to the national reach of large private healthcare groups
- Using CTEs to compare county-level NHS provision against the national 
  average reveals which regions have significantly below-average NHS coverage
- Oxfordshire, Hampshire, and Staffordshire show the largest negative 
  variance from the national NHS average, suggesting heavier reliance 
  on Independent sector provision in these areas
- The majority of counties with sufficient data fall into the NHS Majority 
  category, reflecting the dominance of public healthcare provision nationally
