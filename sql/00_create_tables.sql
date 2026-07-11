/*
=====================================================================================================
File        : 00_create_tables.sql
Project     : Myntra Consumer Intelligence — Funnel & Sentiment Analysis
Description : Creates the database and all 6 tables
              Run this FIRST before importing any CSV data

Tables      : products, customers, geography (dimension — clean)
              customer_journey, customer_reviews, engagement_data (fact — messy, to be cleaned)

Database    : PostgreSQL
=====================================================================================================
*/

-- ============================================
-- STEP 1: CREATE DATABASE
-- Run this separately in pgAdmin query tool
-- ============================================

-- CREATE DATABASE myntra_intelligence;

-- Then connect to myntra_intelligence and run everything below

-- ============================================
-- STEP 2: DROP TABLES (if re-running)
-- ============================================

DROP TABLE IF EXISTS customer_journey;
DROP TABLE IF EXISTS customer_reviews;
DROP TABLE IF EXISTS engagement_data;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS geography;

-- ============================================
-- STEP 3: DIMENSION TABLES (clean)
-- ============================================

-- 1. Products (real Myntra data)
CREATE TABLE products (
    ProductID           SERIAL PRIMARY KEY,
    ProductName         VARCHAR(200)    NOT NULL,
    Brand               VARCHAR(100)    NOT NULL,
    Category            VARCHAR(100)    NOT NULL,
    Price               NUMERIC(10, 2)  NOT NULL,
    MRP                 NUMERIC(10, 2)  NOT NULL,
    DiscountPercent     NUMERIC(5, 1),
    AvgRating           NUMERIC(3, 1),
    NumberOfRatings     INT
);

-- 2. Customers (simulated Indian customers)
CREATE TABLE customers (
    CustomerID          SERIAL PRIMARY KEY,
    CustomerName        VARCHAR(100)    NOT NULL,
    Age                 INT             NOT NULL,
    Gender              VARCHAR(10)     NOT NULL,
    City                VARCHAR(100)    NOT NULL,
    State               VARCHAR(100)    NOT NULL,
    Email               VARCHAR(150)    NOT NULL,
    MembershipType      VARCHAR(20)     NOT NULL,
    SignupDate          DATE            NOT NULL    -- for cohort + retention analysis
);

-- 3. Geography (Indian cities + regions)
CREATE TABLE geography (
    GeographyID         SERIAL PRIMARY KEY,
    City                VARCHAR(100)    NOT NULL,
    State               VARCHAR(100)    NOT NULL,
    Region              VARCHAR(20)     NOT NULL    -- North / South / East / West
);

-- ============================================
-- STEP 4: FACT TABLES (messy — raw data)
-- ============================================

-- 4. Customer Journey (has issues: dupes, casing, NULLs)
CREATE TABLE customer_journey (
    JourneyID           INT             PRIMARY KEY,
    CustomerID          INT             REFERENCES customers(CustomerID),
    ProductID           INT             REFERENCES products(ProductID),
    VisitDate           DATE            NOT NULL,
    Stage               VARCHAR(50),    -- intentional casing issues: Homepage/homepage/HOMEPAGE
    Action              VARCHAR(50),    -- intentional casing issues: View/view/VIEW
    Duration            NUMERIC(8, 1)   -- NULL for all Drop-off rows (intentional)
);

-- 5. Customer Reviews (has issues: whitespace in ReviewText)
CREATE TABLE customer_reviews (
    ReviewID            INT             PRIMARY KEY,
    CustomerID          INT             REFERENCES customers(CustomerID),
    ProductID           INT             REFERENCES products(ProductID),
    ReviewDate          DATE            NOT NULL,
    Rating              INT             NOT NULL,   -- 1 to 5
    ReviewText          TEXT                        -- leading/trailing spaces + double spaces
);

-- 6. Engagement Data (has issues: casing, combined column)
CREATE TABLE engagement_data (
    EngagementID        INT             PRIMARY KEY,
    ContentID           VARCHAR(20)     NOT NULL,
    ContentType         VARCHAR(50),    -- intentional casing: Blog/blog/BLOG
    Likes               INT,
    EngagementDate      DATE            NOT NULL,
    CampaignID          VARCHAR(20),
    ProductID           INT             REFERENCES products(ProductID),
    ViewsClicksCombined VARCHAR(50)     -- "15000-300" — needs to be split into Views + Clicks
);

-- ============================================
-- STEP 5: IMPORT CSV DATA
-- In pgAdmin: right-click each table → Import/Export
-- OR use the COPY commands below
-- Update the file paths to where you saved your CSVs
-- ============================================

/*
COPY products(ProductID, ProductName, Brand, Category, Price, MRP, DiscountPercent, AvgRating, NumberOfRatings)
FROM 'C:/your_path/products.csv'
DELIMITER ','
CSV HEADER;

COPY customers(CustomerID, CustomerName, Age, Gender, City, State, Email, MembershipType, SignupDate)
FROM 'C:/your_path/customers.csv'
DELIMITER ','
CSV HEADER;

COPY geography(GeographyID, City, State, Region)
FROM 'C:/your_path/geography.csv'
DELIMITER ','
CSV HEADER;

COPY customer_journey(JourneyID, CustomerID, ProductID, VisitDate, Stage, Action, Duration)
FROM 'C:/your_path/customer_journey.csv'
DELIMITER ','
CSV HEADER;

COPY customer_reviews(ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText)
FROM 'C:/your_path/customer_reviews.csv'
DELIMITER ','
CSV HEADER;

COPY engagement_data(EngagementID, ContentID, ContentType, Likes, EngagementDate, CampaignID, ProductID, ViewsClicksCombined)
FROM 'C:/your_path/engagement_data.csv'
DELIMITER ','
CSV HEADER;
*/

-- ============================================
-- STEP 6: VERIFY IMPORTS
-- Run after importing to confirm row counts
-- ============================================

SELECT 'products'         AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'customers',                       COUNT(*)             FROM customers
UNION ALL
SELECT 'geography',                       COUNT(*)             FROM geography
UNION ALL
SELECT 'customer_journey',                COUNT(*)             FROM customer_journey
UNION ALL
SELECT 'customer_reviews',                COUNT(*)             FROM customer_reviews
UNION ALL
SELECT 'engagement_data',                 COUNT(*)             FROM engagement_data;

/*
Expected output:
  products          →  50
  customers         → 500
  geography         →  20
  customer_journey  → 4000
  customer_reviews  → 1400
  engagement_data   → 4500
*/
