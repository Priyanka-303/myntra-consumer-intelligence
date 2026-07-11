/*
=====================================================================================================
File        : 02_cleaning_transformation.sql
Project     : Myntra Consumer Intelligence — Funnel & Sentiment Analysis
Description : Cleans and transforms raw data based on findings from 01_validation.sql
              Creates new _cleaned tables — original tables are NEVER modified
              All issues found in validation are fixed here

Issues fixed:
  customer_journey  → remove 80 logical duplicates
  customer_journey  → standardize Stage casing (Homepage/homepage/HOMEPAGE → Homepage)
  customer_journey  → standardize Action casing (View/view/VIEW → View)
  customer_reviews  → TRIM leading/trailing whitespace from ReviewText
  customer_reviews  → remove double spaces from ReviewText
  engagement_data   → standardize ContentType casing (Blog/blog/BLOG → Blog)
  engagement_data   → split ViewsClicksCombined into Views (INT) + Clicks (INT)

Database    : PostgreSQL
=====================================================================================================
*/

-- ============================================
-- SECTION 1: CLEAN customer_journey
-- Fixes: duplicates + Stage casing + Action casing
-- NULL Duration rows are KEPT (intentional system behaviour, documented in validation)
-- ============================================

DROP TABLE IF EXISTS customer_journey_cleaned;

CREATE TABLE customer_journey_cleaned AS
WITH deduped AS (
    -- Step 1: assign row number within each logical duplicate group
    -- keep row_num = 1 (first occurrence), discard the rest
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
            ORDER BY JourneyID
        ) AS row_num
    FROM customer_journey
),
no_duplicates AS (
    -- Step 2: keep only the first occurrence of each duplicate group
    SELECT
        JourneyID,
        CustomerID,
        ProductID,
        VisitDate,
        Stage,
        Action,
        Duration
    FROM deduped
    WHERE row_num = 1
)
-- Step 3: standardize Stage and Action casing using INITCAP
-- INITCAP converts "homepage" → "Homepage", "HOMEPAGE" → "Homepage"
-- Special case: "Drop-off" needs manual handling since INITCAP gives "Drop-Off"
SELECT
    JourneyID,
    CustomerID,
    ProductID,
    VisitDate,
    CASE
        WHEN LOWER(Stage) = 'homepage'    THEN 'Homepage'
        WHEN LOWER(Stage) = 'productpage' THEN 'ProductPage'
        WHEN LOWER(Stage) = 'checkout'    THEN 'Checkout'
        WHEN LOWER(Stage) = 'purchase'    THEN 'Purchase'
        ELSE Stage
    END AS Stage,
    CASE
        WHEN LOWER(Action) = 'view'      THEN 'View'
        WHEN LOWER(Action) = 'click'     THEN 'Click'
        WHEN LOWER(Action) = 'addtocart' THEN 'AddToCart'
        WHEN LOWER(Action) = 'purchase'  THEN 'Purchase'
        WHEN LOWER(Action) = 'drop-off'  THEN 'Drop-off'
        ELSE Action
    END AS Action,
    Duration
FROM no_duplicates;

-- Verify: row count should be ~3920 (4000 - 80 duplicates)
SELECT COUNT(*) AS cleaned_journey_rows FROM customer_journey_cleaned;

-- Verify: Stage should now have exactly 4 distinct values
SELECT Stage, COUNT(*) AS row_count
FROM customer_journey_cleaned
GROUP BY Stage
ORDER BY Stage;

-- Verify: Action should now have exactly 5 distinct values
SELECT Action, COUNT(*) AS row_count
FROM customer_journey_cleaned
GROUP BY Action
ORDER BY Action;

-- ============================================
-- SECTION 2: CLEAN customer_reviews
-- Fixes: leading/trailing whitespace + double spaces in ReviewText
-- ============================================

DROP TABLE IF EXISTS customer_reviews_cleaned;

CREATE TABLE customer_reviews_cleaned AS
SELECT
    ReviewID,
    CustomerID,
    ProductID,
    ReviewDate,
    Rating,
    -- Step 1: TRIM removes leading and trailing spaces
    -- Step 2: REGEXP_REPLACE collapses multiple spaces into one
    TRIM(
        REGEXP_REPLACE(ReviewText, '\s{2,}', ' ', 'g')
    ) AS ReviewText
FROM customer_reviews;

-- Verify: no more leading/trailing spaces
SELECT
    COUNT(*) FILTER (WHERE ReviewText LIKE '  %')   AS leading_space_rows,
    COUNT(*) FILTER (WHERE ReviewText LIKE '%  ')   AS trailing_space_rows,
    COUNT(*) FILTER (WHERE ReviewText LIKE '%  %')  AS double_space_rows
FROM customer_reviews_cleaned;
-- Expected: all 0

-- Verify: row count unchanged (we cleaned, not deleted)
SELECT COUNT(*) AS cleaned_reviews_rows FROM customer_reviews_cleaned;
-- Expected: 1400

-- ============================================
-- SECTION 3: CLEAN engagement_data
-- Fixes: ContentType casing + split ViewsClicksCombined
-- ============================================

DROP TABLE IF EXISTS engagement_data_cleaned;

CREATE TABLE engagement_data_cleaned AS
SELECT
    EngagementID,
    ContentID,
    -- Fix casing: Blog/blog/BLOG → Blog
    CASE
        WHEN LOWER(ContentType) = 'blog'        THEN 'Blog'
        WHEN LOWER(ContentType) = 'socialmedia'  THEN 'SocialMedia'
        WHEN LOWER(ContentType) = 'video'        THEN 'Video'
        WHEN LOWER(ContentType) = 'newsletter'   THEN 'Newsletter'
        ELSE ContentType
    END AS ContentType,
    Likes,
    EngagementDate,
    CampaignID,
    ProductID,
    -- Split ViewsClicksCombined "15000-300" into two separate columns
    CAST(SPLIT_PART(ViewsClicksCombined, '-', 1) AS INTEGER) AS Views,
    CAST(SPLIT_PART(ViewsClicksCombined, '-', 2) AS INTEGER) AS Clicks
FROM engagement_data;

-- Verify: ContentType should now have exactly 4 distinct values
SELECT ContentType, COUNT(*) AS row_count
FROM engagement_data_cleaned
GROUP BY ContentType
ORDER BY ContentType;

-- Verify: Views and Clicks are now proper integers, not strings
SELECT
    MIN(Views)  AS min_views,
    MAX(Views)  AS max_views,
    MIN(Clicks) AS min_clicks,
    MAX(Clicks) AS max_clicks
FROM engagement_data_cleaned;

-- Verify: row count unchanged
SELECT COUNT(*) AS cleaned_engagement_rows FROM engagement_data_cleaned;
-- Expected: 4500

-- ============================================
-- SECTION 4: FINAL CLEANED TABLE SUMMARY
-- Confirm all 3 cleaned tables are ready
-- ============================================

SELECT 'customer_journey_cleaned'  AS table_name, COUNT(*) AS row_count FROM customer_journey_cleaned
UNION ALL
SELECT 'customer_reviews_cleaned',  COUNT(*) FROM customer_reviews_cleaned
UNION ALL
SELECT 'engagement_data_cleaned',   COUNT(*) FROM engagement_data_cleaned;

/*
Expected output:
  customer_journey_cleaned  → ~3920  (4000 - 80 duplicates removed)
  customer_reviews_cleaned  → 1400   (all rows kept, text cleaned)
  engagement_data_cleaned   → 4500   (all rows kept, casing fixed, column split)
*/

-- ============================================
-- SECTION 5: BEFORE vs AFTER COMPARISON
-- Shows the impact of cleaning clearly
-- Great for README and portfolio documentation
-- ============================================

SELECT
    'customer_journey'  AS table_name,
    (SELECT COUNT(*) FROM customer_journey)         AS rows_before,
    (SELECT COUNT(*) FROM customer_journey_cleaned) AS rows_after,
    (SELECT COUNT(*) FROM customer_journey) -
    (SELECT COUNT(*) FROM customer_journey_cleaned) AS rows_removed,
    (SELECT COUNT(DISTINCT Stage) FROM customer_journey)         AS stage_variants_before,
    (SELECT COUNT(DISTINCT Stage) FROM customer_journey_cleaned) AS stage_variants_after

UNION ALL

SELECT
    'engagement_data',
    (SELECT COUNT(*) FROM engagement_data),
    (SELECT COUNT(*) FROM engagement_data_cleaned),
    0,
    (SELECT COUNT(DISTINCT ContentType) FROM engagement_data),
    (SELECT COUNT(DISTINCT ContentType) FROM engagement_data_cleaned);
