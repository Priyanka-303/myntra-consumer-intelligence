/*
=====================================================================================================
File        : 03_business_analysis.sql
Project     : Myntra Consumer Intelligence — Funnel & Sentiment Analysis
Description : Advanced business analysis queries on cleaned tables
              Covers: Funnel Analysis, Cohort Analysis, Retention, RFM, Geographic, Revenue Trends

Tables used : customer_journey_cleaned, customer_reviews_cleaned, engagement_data_cleaned,
              customers, products, geography

Database    : PostgreSQL
=====================================================================================================
*/

-- ============================================
-- SECTION 1: FUNNEL ANALYSIS
-- Business Question: Where are we losing customers?
-- ============================================

-- 1a. Total visits per stage
SELECT
    Stage,
    COUNT(*)                                AS total_visits,
    COUNT(DISTINCT CustomerID)              AS unique_customers
FROM customer_journey_cleaned
GROUP BY Stage
ORDER BY
    CASE Stage
        WHEN 'Homepage'    THEN 1
        WHEN 'ProductPage' THEN 2
        WHEN 'Checkout'    THEN 3
        WHEN 'Purchase'    THEN 4
    END;

-- 1b. Drop-off rate at each stage
WITH stage_counts AS (
    SELECT
        Stage,
        COUNT(*)                                        AS total_visits,
        COUNT(*) FILTER (WHERE Action = 'Drop-off')    AS drop_offs
    FROM customer_journey_cleaned
    GROUP BY Stage
)
SELECT
    Stage,
    total_visits,
    drop_offs,
    ROUND(drop_offs * 100.0 / total_visits, 2)         AS drop_off_rate_pct
FROM stage_counts
ORDER BY
    CASE Stage
        WHEN 'Homepage'    THEN 1
        WHEN 'ProductPage' THEN 2
        WHEN 'Checkout'    THEN 3
        WHEN 'Purchase'    THEN 4
    END;

-- 1c. Conversion funnel — stage by stage conversion rate
WITH stage_totals AS (
    SELECT
        Stage,
        COUNT(DISTINCT CustomerID) AS unique_customers
    FROM customer_journey_cleaned
    WHERE Action != 'Drop-off'
    GROUP BY Stage
),
homepage_count AS (
    SELECT unique_customers AS homepage_visitors
    FROM stage_totals
    WHERE Stage = 'Homepage'
)
SELECT
    s.Stage,
    s.unique_customers,
    ROUND(s.unique_customers * 100.0 / h.homepage_visitors, 2) AS conversion_from_homepage_pct
FROM stage_totals s
CROSS JOIN homepage_count h
ORDER BY
    CASE s.Stage
        WHEN 'Homepage'    THEN 1
        WHEN 'ProductPage' THEN 2
        WHEN 'Checkout'    THEN 3
        WHEN 'Purchase'    THEN 4
    END;

-- ============================================
-- SECTION 2: COHORT ANALYSIS
-- Business Question: Which signup cohort converts best?
-- ============================================

-- 2a. Cohort size — how many customers signed up each month
SELECT
    TO_CHAR(SignupDate, 'YYYY-MM')          AS signup_cohort,
    COUNT(DISTINCT CustomerID)              AS cohort_size
FROM customers
GROUP BY signup_cohort
ORDER BY signup_cohort;

-- 2b. Cohort conversion — did they eventually make a purchase?
WITH cohort_base AS (
    SELECT
        CustomerID,
        TO_CHAR(SignupDate, 'YYYY-MM')      AS signup_cohort
    FROM customers
),
purchasers AS (
    SELECT DISTINCT CustomerID
    FROM customer_journey_cleaned
    WHERE Action = 'Purchase'
)
SELECT
    c.signup_cohort,
    COUNT(DISTINCT c.CustomerID)            AS cohort_size,
    COUNT(DISTINCT p.CustomerID)            AS total_purchasers,
    ROUND(COUNT(DISTINCT p.CustomerID) * 100.0 /
          COUNT(DISTINCT c.CustomerID), 2)  AS conversion_rate_pct
FROM cohort_base c
LEFT JOIN purchasers p ON c.CustomerID = p.CustomerID
GROUP BY c.signup_cohort
ORDER BY c.signup_cohort;

-- 2c. Avg days to first purchase by membership type
WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(VisitDate)                      AS first_purchase_date
    FROM customer_journey_cleaned
    WHERE Action = 'Purchase'
    GROUP BY CustomerID
)
SELECT
    c.MembershipType,
    COUNT(DISTINCT c.CustomerID)            AS total_customers,
    ROUND(AVG(fp.first_purchase_date - c.SignupDate), 1) AS avg_days_to_purchase
FROM customers c
JOIN first_purchase fp ON c.CustomerID = fp.CustomerID
GROUP BY c.MembershipType
ORDER BY avg_days_to_purchase;

-- ============================================
-- SECTION 3: RETENTION ANALYSIS
-- Business Question: Are we retaining customers?
-- ============================================

-- 3a. Single visit vs repeat visitors
WITH visit_counts AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT VisitDate)           AS total_visit_days
    FROM customer_journey_cleaned
    GROUP BY CustomerID
)
SELECT
    CASE
        WHEN total_visit_days = 1 THEN 'Single Visit'
        WHEN total_visit_days BETWEEN 2 AND 3 THEN '2-3 Visits'
        WHEN total_visit_days BETWEEN 4 AND 6 THEN '4-6 Visits'
        ELSE '7+ Visits'
    END                                     AS visit_frequency,
    COUNT(*)                                AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM visit_counts
GROUP BY visit_frequency
ORDER BY customer_count DESC;

-- 3b. Monthly active users (MAU)
SELECT
    TO_CHAR(VisitDate, 'YYYY-MM')           AS visit_month,
    COUNT(DISTINCT CustomerID)              AS monthly_active_users
FROM customer_journey_cleaned
GROUP BY visit_month
ORDER BY visit_month;

-- 3c. Rolling 3-month active users
SELECT
    TO_CHAR(VisitDate, 'YYYY-MM')           AS visit_month,
    COUNT(DISTINCT CustomerID)              AS mau,
    ROUND(AVG(COUNT(DISTINCT CustomerID)) OVER (
        ORDER BY TO_CHAR(VisitDate, 'YYYY-MM')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0)                                   AS rolling_3month_avg
FROM customer_journey_cleaned
GROUP BY visit_month
ORDER BY visit_month;

-- ============================================
-- SECTION 4: RFM ANALYSIS
-- Business Question: Who are our best customers?
-- ============================================

-- 4a. RFM scores per customer
WITH rfm_base AS (
    SELECT
        CustomerID,
        MAX(VisitDate)                                      AS last_visit_date,
        COUNT(DISTINCT VisitDate)                           AS frequency,
        COUNT(*) FILTER (WHERE Action = 'Purchase')         AS total_purchases
    FROM customer_journey_cleaned
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        last_visit_date,
        frequency,
        total_purchases,
        CURRENT_DATE - last_visit_date                      AS recency_days,
        NTILE(4) OVER (ORDER BY last_visit_date DESC)       AS r_score,
        NTILE(4) OVER (ORDER BY frequency)                  AS f_score,
        NTILE(4) OVER (ORDER BY total_purchases)            AS m_score
    FROM rfm_base
)
SELECT
    CustomerID,
    recency_days,
    frequency,
    total_purchases,
    r_score, f_score, m_score,
    r_score + f_score + m_score                             AS rfm_total,
    CASE
        WHEN r_score + f_score + m_score >= 10 THEN 'Champions'
        WHEN r_score + f_score + m_score >= 8  THEN 'Loyal Customers'
        WHEN r_score + f_score + m_score >= 6  THEN 'Potential Loyalists'
        WHEN r_score + f_score + m_score >= 4  THEN 'At Risk'
        ELSE 'Lost'
    END                                                     AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC;

-- 4b. RFM segment summary
WITH rfm_base AS (
    SELECT
        CustomerID,
        MAX(VisitDate)                                      AS last_visit_date,
        COUNT(DISTINCT VisitDate)                           AS frequency,
        COUNT(*) FILTER (WHERE Action = 'Purchase')         AS total_purchases
    FROM customer_journey_cleaned
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        NTILE(4) OVER (ORDER BY last_visit_date DESC)       AS r_score,
        NTILE(4) OVER (ORDER BY frequency)                  AS f_score,
        NTILE(4) OVER (ORDER BY total_purchases)            AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        CustomerID,
        r_score + f_score + m_score AS rfm_total,
        CASE
            WHEN r_score + f_score + m_score >= 10 THEN 'Champions'
            WHEN r_score + f_score + m_score >= 8  THEN 'Loyal Customers'
            WHEN r_score + f_score + m_score >= 6  THEN 'Potential Loyalists'
            WHEN r_score + f_score + m_score >= 4  THEN 'At Risk'
            ELSE 'Lost'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    COUNT(*)                                                AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)      AS percentage
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY customer_count DESC;

-- ============================================
-- SECTION 5: GEOGRAPHIC ANALYSIS
-- Business Question: Which states drive the most activity?
-- ============================================

-- 5a. Visits and purchases by state
SELECT
    c.State,
    g.Region,
    COUNT(*)                                                AS total_visits,
    COUNT(*) FILTER (WHERE cj.Action = 'Purchase')          AS total_purchases,
    COUNT(DISTINCT cj.CustomerID)                           AS unique_customers,
    ROUND(COUNT(*) FILTER (WHERE cj.Action = 'Purchase') * 100.0 /
          COUNT(*), 2)                                      AS purchase_rate_pct
FROM customer_journey_cleaned cj
JOIN customers c ON cj.CustomerID = c.CustomerID
JOIN geography g ON c.City = g.City
GROUP BY c.State, g.Region
ORDER BY total_visits DESC;

-- 5b. Region level summary
SELECT
    g.Region,
    COUNT(DISTINCT cj.CustomerID)                           AS unique_customers,
    COUNT(*)                                                AS total_visits,
    COUNT(*) FILTER (WHERE cj.Action = 'Purchase')          AS total_purchases
FROM customer_journey_cleaned cj
JOIN customers c  ON cj.CustomerID = c.CustomerID
JOIN geography g  ON c.City = g.City
GROUP BY g.Region
ORDER BY total_purchases DESC;

-- ============================================
-- SECTION 6: PRODUCT PERFORMANCE
-- Business Question: Which products and categories drive the most purchases?
-- ============================================

-- 6a. Top products by purchases
SELECT
    p.ProductName,
    p.Brand,
    p.Category,
    p.Price,
    COUNT(*) FILTER (WHERE cj.Action = 'Purchase')          AS total_purchases,
    COUNT(*) FILTER (WHERE cj.Action = 'AddToCart')         AS total_addtocart,
    COUNT(*) FILTER (WHERE cj.Action = 'Drop-off')          AS total_dropoffs,
    ROUND(COUNT(*) FILTER (WHERE cj.Action = 'Purchase') * 100.0 /
          NULLIF(COUNT(*), 0), 2)                           AS purchase_rate_pct
FROM customer_journey_cleaned cj
JOIN products p ON cj.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName, p.Brand, p.Category, p.Price
ORDER BY total_purchases DESC
LIMIT 10;

-- 6b. Category performance
SELECT
    p.Category,
    COUNT(DISTINCT cj.CustomerID)                           AS unique_customers,
    COUNT(*) FILTER (WHERE cj.Action = 'Purchase')          AS total_purchases,
    COUNT(*) FILTER (WHERE cj.Action = 'Drop-off')          AS total_dropoffs,
    ROUND(AVG(p.Price), 2)                                  AS avg_price
FROM customer_journey_cleaned cj
JOIN products p ON cj.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY total_purchases DESC;

-- 6c. Top product per category (TOP N per group using RANK)
WITH product_purchases AS (
    SELECT
        p.Category,
        p.ProductName,
        COUNT(*) FILTER (WHERE cj.Action = 'Purchase')      AS total_purchases,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY COUNT(*) FILTER (WHERE cj.Action = 'Purchase') DESC
        )                                                   AS rank_in_category
    FROM customer_journey_cleaned cj
    JOIN products p ON cj.ProductID = p.ProductID
    GROUP BY p.Category, p.ProductName
)
SELECT Category, ProductName, total_purchases, rank_in_category
FROM product_purchases
WHERE rank_in_category = 1
ORDER BY total_purchases DESC;

-- ============================================
-- SECTION 7: MARKETING / ENGAGEMENT ANALYSIS
-- Business Question: Which campaigns and content types drive the most clicks?
-- ============================================

-- 7a. Performance by content type
SELECT
    ContentType,
    COUNT(*)                                AS total_posts,
    SUM(Views)                              AS total_views,
    SUM(Clicks)                             AS total_clicks,
    SUM(Likes)                              AS total_likes,
    ROUND(SUM(Clicks) * 100.0 / NULLIF(SUM(Views), 0), 2)  AS ctr_pct
FROM engagement_data_cleaned
GROUP BY ContentType
ORDER BY ctr_pct DESC;

-- 7b. Top 5 campaigns by clicks
SELECT
    CampaignID,
    SUM(Views)                              AS total_views,
    SUM(Clicks)                             AS total_clicks,
    ROUND(SUM(Clicks) * 100.0 / NULLIF(SUM(Views), 0), 2)  AS ctr_pct
FROM engagement_data_cleaned
GROUP BY CampaignID
ORDER BY total_clicks DESC
LIMIT 5;

-- 7c. Monthly engagement trend
SELECT
    TO_CHAR(EngagementDate, 'YYYY-MM')      AS engagement_month,
    SUM(Views)                              AS total_views,
    SUM(Clicks)                             AS total_clicks,
    ROUND(SUM(Clicks) * 100.0 / NULLIF(SUM(Views), 0), 2)  AS ctr_pct
FROM engagement_data_cleaned
GROUP BY engagement_month
ORDER BY engagement_month;

-- ============================================
-- SECTION 8: WINDOW FUNCTIONS SHOWCASE
-- Month over month growth, running totals, rankings
-- ============================================

-- 8a. Month over month visit growth using LAG
WITH monthly_visits AS (
    SELECT
        TO_CHAR(VisitDate, 'YYYY-MM')       AS visit_month,
        COUNT(*)                            AS total_visits
    FROM customer_journey_cleaned
    GROUP BY visit_month
)
SELECT
    visit_month,
    total_visits,
    LAG(total_visits) OVER (ORDER BY visit_month)       AS prev_month_visits,
    total_visits - LAG(total_visits) OVER (ORDER BY visit_month) AS mom_change,
    ROUND((total_visits - LAG(total_visits) OVER (ORDER BY visit_month)) * 100.0 /
          NULLIF(LAG(total_visits) OVER (ORDER BY visit_month), 0), 2) AS mom_growth_pct
FROM monthly_visits
ORDER BY visit_month;

-- 8b. Running total of purchases over time using SUM OVER
WITH daily_purchases AS (
    SELECT
        VisitDate,
        COUNT(*) FILTER (WHERE Action = 'Purchase') AS daily_purchases
    FROM customer_journey_cleaned
    GROUP BY VisitDate
)
SELECT
    VisitDate,
    daily_purchases,
    SUM(daily_purchases) OVER (ORDER BY VisitDate)      AS running_total_purchases
FROM daily_purchases
ORDER BY VisitDate;

-- 8c. Rank customers by total visits using RANK vs DENSE_RANK
WITH customer_visits AS (
    SELECT
        CustomerID,
        COUNT(*)                            AS total_visits
    FROM customer_journey_cleaned
    GROUP BY CustomerID
)
SELECT
    cv.CustomerID,
    c.CustomerName,
    c.MembershipType,
    c.City,
    cv.total_visits,
    RANK() OVER (ORDER BY cv.total_visits DESC)         AS visit_rank,
    DENSE_RANK() OVER (ORDER BY cv.total_visits DESC)   AS dense_visit_rank
FROM customer_visits cv
JOIN customers c ON cv.CustomerID = c.CustomerID
ORDER BY visit_rank
LIMIT 10;
