/*
=====================================================================================================
File        : 01_validation.sql
Project     : Myntra Consumer Intelligence — Funnel & Sentiment Analysis
Description : Validates all 6 tables for data quality issues BEFORE any cleaning
              READ ONLY — no data is changed in this file

Issues we expect to find:
  customer_journey  → ~80 logical duplicates
  customer_journey  → Stage casing inconsistency (Homepage/homepage/HOMEPAGE)
  customer_journey  → Action casing inconsistency (View/view/VIEW)
  customer_journey  → NULL Duration on Drop-off rows
  customer_reviews  → leading/trailing whitespace in ReviewText
  customer_reviews  → double spaces in ReviewText
  engagement_data   → ContentType casing inconsistency (Blog/blog/BLOG)
  engagement_data   → ViewsClicksCombined stored as "15000-300" string

Database    : PostgreSQL
=====================================================================================================
*/

-- ============================================
-- SECTION 1: ROW COUNTS
-- Quick sanity check on all tables
-- ============================================

SELECT 'products'         AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'customers',        COUNT(*) FROM customers
UNION ALL
SELECT 'geography',        COUNT(*) FROM geography
UNION ALL
SELECT 'customer_journey', COUNT(*) FROM customer_journey
UNION ALL
SELECT 'customer_reviews', COUNT(*) FROM customer_reviews
UNION ALL
SELECT 'engagement_data',  COUNT(*) FROM engagement_data;

-- ============================================
-- SECTION 2: NULL CHECKS
-- ============================================

-- 2a. NULL check: customer_journey
SELECT
    COUNT(*) FILTER (WHERE CustomerID IS NULL)  AS null_customerid,
    COUNT(*) FILTER (WHERE ProductID  IS NULL)  AS null_productid,
    COUNT(*) FILTER (WHERE VisitDate  IS NULL)  AS null_visitdate,
    COUNT(*) FILTER (WHERE Stage      IS NULL)  AS null_stage,
    COUNT(*) FILTER (WHERE Action     IS NULL)  AS null_action,
    COUNT(*) FILTER (WHERE Duration   IS NULL)  AS null_duration  -- expect ~800+ NULLs
FROM customer_journey;

-- 2b. Investigate: are NULL Duration rows always Drop-off?
-- This tells us if NULLs are intentional system behaviour or a real data error
SELECT
    Action,
    COUNT(*)                                        AS total_rows,
    COUNT(*) FILTER (WHERE Duration IS NULL)        AS null_duration_count,
    COUNT(*) FILTER (WHERE Duration IS NOT NULL)    AS has_duration_count
FROM customer_journey
GROUP BY Action
ORDER BY null_duration_count DESC;

-- Expected finding: ALL NULL Duration rows belong to Drop-off action
-- This is intentional — system doesn't record duration when user drops off

-- 2c. NULL check: customer_reviews
SELECT
    COUNT(*) FILTER (WHERE CustomerID  IS NULL) AS null_customerid,
    COUNT(*) FILTER (WHERE ProductID   IS NULL) AS null_productid,
    COUNT(*) FILTER (WHERE Rating      IS NULL) AS null_rating,
    COUNT(*) FILTER (WHERE ReviewText  IS NULL) AS null_reviewtext
FROM customer_reviews;

-- 2d. NULL check: engagement_data
SELECT
    COUNT(*) FILTER (WHERE ContentType          IS NULL) AS null_contenttype,
    COUNT(*) FILTER (WHERE CampaignID           IS NULL) AS null_campaignid,
    COUNT(*) FILTER (WHERE ViewsClicksCombined  IS NULL) AS null_viewsclicks
FROM engagement_data;

-- ============================================
-- SECTION 3: DUPLICATE CHECK
-- ============================================

-- 3a. Logical duplicates in customer_journey
-- Same CustomerID + ProductID + VisitDate + Stage + Action = same event recorded twice
WITH duplicates AS (
    SELECT
        CustomerID,
        ProductID,
        VisitDate,
        Stage,
        Action,
        COUNT(*) AS occurrence_count
    FROM customer_journey
    GROUP BY CustomerID, ProductID, VisitDate, Stage, Action
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*)            AS duplicate_groups,
    SUM(occurrence_count - 1) AS extra_rows_to_remove
FROM duplicates;

-- Expected finding: ~80 duplicate groups, ~80 extra rows to remove

-- 3b. Preview the actual duplicate rows
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
            ORDER BY JourneyID
        ) AS row_num
    FROM customer_journey
)
SELECT * FROM ranked
WHERE row_num > 1
LIMIT 10;

-- ============================================
-- SECTION 4: CASING INCONSISTENCY CHECK
-- ============================================

-- 4a. Stage casing variants in customer_journey
-- If casing was consistent, we'd see exactly 4 values
-- More than 4 = casing problem
SELECT
    Stage,
    COUNT(*) AS row_count
FROM customer_journey
GROUP BY Stage
ORDER BY Stage;

-- Expected: Homepage, homepage, HOMEPAGE, ProductPage, productpage, PRODUCTPAGE etc.

-- 4b. How many distinct Stage values exist?
SELECT COUNT(DISTINCT Stage) AS distinct_stage_values FROM customer_journey;
-- Expected: more than 4 (should be 4 if clean)

-- 4c. Action casing variants
SELECT
    Action,
    COUNT(*) AS row_count
FROM customer_journey
GROUP BY Action
ORDER BY Action;

-- 4d. ContentType casing variants in engagement_data
SELECT
    ContentType,
    COUNT(*) AS row_count
FROM engagement_data
GROUP BY ContentType
ORDER BY ContentType;

-- Expected: Blog/blog/BLOG, Video/video/VIDEO etc.

-- 4e. How many distinct ContentType values?
SELECT COUNT(DISTINCT ContentType) AS distinct_contenttype_values FROM engagement_data;
-- Expected: more than 4 (should be 4 if clean)

-- ============================================
-- SECTION 5: WHITESPACE CHECK (customer_reviews)
-- ============================================

-- 5a. Count rows with leading spaces
SELECT
    COUNT(*) FILTER (WHERE ReviewText LIKE '  %')       AS leading_space_rows,
    COUNT(*) FILTER (WHERE ReviewText LIKE '%  ')       AS trailing_space_rows,
    COUNT(*) FILTER (WHERE ReviewText LIKE '%  %')      AS double_space_rows,
    COUNT(*)                                            AS total_rows
FROM customer_reviews;

-- 5b. Preview messy review text
SELECT
    ReviewID,
    Rating,
    LENGTH(ReviewText)          AS raw_length,
    LENGTH(TRIM(ReviewText))    AS trimmed_length,
    ReviewText
FROM customer_reviews
WHERE ReviewText LIKE '  %'
   OR ReviewText LIKE '%  %'
LIMIT 10;

-- ============================================
-- SECTION 6: COMBINED COLUMN CHECK (engagement_data)
-- ============================================

-- 6a. Preview ViewsClicksCombined — should look like "15000-300"
SELECT
    EngagementID,
    ViewsClicksCombined,
    SPLIT_PART(ViewsClicksCombined, '-', 1) AS views_extracted,
    SPLIT_PART(ViewsClicksCombined, '-', 2) AS clicks_extracted
FROM engagement_data
LIMIT 10;

-- 6b. Confirm all rows follow the "number-number" pattern
SELECT
    COUNT(*) FILTER (WHERE ViewsClicksCombined NOT LIKE '%-%') AS malformed_rows
FROM engagement_data;
-- Expected: 0 malformed rows

-- ============================================
-- SECTION 7: RANGE / LOGIC CHECKS
-- ============================================

-- 7a. Rating must be between 1 and 5
SELECT
    COUNT(*) FILTER (WHERE Rating < 1 OR Rating > 5) AS invalid_ratings,
    MIN(Rating) AS min_rating,
    MAX(Rating) AS max_rating
FROM customer_reviews;

-- 7b. Price and MRP sanity check
SELECT
    COUNT(*) FILTER (WHERE Price <= 0)  AS zero_or_negative_price,
    COUNT(*) FILTER (WHERE MRP < Price) AS mrp_less_than_price,
    MIN(Price)                          AS min_price,
    MAX(Price)                          AS max_price
FROM products;

-- 7c. Age range check in customers
SELECT
    COUNT(*) FILTER (WHERE Age < 18 OR Age > 100) AS invalid_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age
FROM customers;

-- 7d. SignupDate should be before VisitDate (customer signed up before visiting)
SELECT COUNT(*) AS signups_after_visit
FROM customer_journey cj
JOIN customers c ON cj.CustomerID = c.CustomerID
WHERE c.SignupDate > cj.VisitDate;
-- Expected: 0 — all signups predate journey activity

-- ============================================
-- SECTION 8: VALIDATION SUMMARY
-- ============================================

SELECT 'NULL Duration rows (Drop-off)'      AS issue, COUNT(*) AS count FROM customer_journey WHERE Duration IS NULL
UNION ALL
SELECT 'Logical duplicates in journey',      COUNT(*) FROM (
    SELECT CustomerID, ProductID, VisitDate, Stage, Action
    FROM customer_journey
    GROUP BY CustomerID, ProductID, VisitDate, Stage, Action
    HAVING COUNT(*) > 1
) sub
UNION ALL
SELECT 'Stage casing variants',              COUNT(DISTINCT Stage)       FROM customer_journey
UNION ALL
SELECT 'Action casing variants',             COUNT(DISTINCT Action)      FROM customer_journey
UNION ALL
SELECT 'ContentType casing variants',        COUNT(DISTINCT ContentType) FROM engagement_data
UNION ALL
SELECT 'Reviews with whitespace issues',     COUNT(*) FROM customer_reviews WHERE ReviewText LIKE '  %' OR ReviewText LIKE '%  %'
UNION ALL
SELECT 'Invalid ratings (not 1-5)',          COUNT(*) FROM customer_reviews WHERE Rating < 1 OR Rating > 5
UNION ALL
SELECT 'Invalid age (not 18-100)',           COUNT(*) FROM customers WHERE Age < 18 OR Age > 100;
