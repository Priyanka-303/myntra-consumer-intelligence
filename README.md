# Myntra Consumer Intelligence — Funnel & Sentiment Analysis | End-to-End Behavioral Analysis
**PostgreSQL · Python · Power BI · NLP Sentiment Analysis**

---

## Executive Snapshot (3-Minute Read)

**Business Context**
Myntra's leadership identified a gap between marketing investment and actual purchase conversion. Despite strong top-funnel engagement, revenue growth was not keeping pace with traffic. This analysis was commissioned to diagnose where customers were dropping off, why sentiment was declining, and which products were silently underperforming — before these issues became visible in the P&L.

## Key Findings ##
- **49% of all drop-offs occur at Checkout** (465 of 861 total drop-offs) — the business has a bottom-funnel problem, not a traffic problem
- Homepage and ProductPage drop-off rates are under 21% — awareness and interest are not the problem
- Combined negative sentiment is **14%** — but Unmet Expectations drives 31% of all complaints — a product description gap, not a product quality problem
- **37.6% of customers are Potential Loyalists** — the largest segment and the biggest untapped opportunity
- Tamil Nadu has the highest purchase rate at **35.67%** despite fewer visits — high intent customers being underserved
- All 4 content types cluster between 15.01–15.26% CTR — channel mix is not the problem, campaign strategy is

**Why This Matters**
A business can appear healthy on topline metrics while hiding structural problems underneath. This analysis joins three data sources — journey behavior, review language, and engagement data — to surface the hidden signals that aggregate dashboards miss.

## Actionable Recommendations ##
- Audit and simplify checkout UX — improving Checkout conversion by just 10% generates ~46 additional purchases per cycle
- Rewrite product descriptions for high-complaint products — reducing Unmet Expectations by 50% shifts ~17 customers from negative to neutral/positive sentiment
- Invest in Tamil Nadu and Maharashtra — both show purchase rates above 32% with room to scale
- Activate win-back campaigns for 72 At Risk customers before they become Lost

> *Note: This project uses a partially simulated dataset. Products sourced from real Myntra listing data (Kaggle). Journey, review, and engagement data simulated to reflect realistic ecommerce patterns with intentional data quality issues for cleaning demonstration. Figures should be interpreted directionally.*

---

## 📌 Project Overview

This project delivers an end-to-end consumer behavior analysis for Myntra, India's leading fashion ecommerce platform, using PostgreSQL, Python, and Power BI.

The business question: *"How can Myntra leverage consumer shopping data to identify conversion bottlenecks, improve engagement, and optimize product and marketing strategy?"*

As the analyst on this project, the focus was on three goals — diagnosing funnel drop-off, understanding what drives negative sentiment, and building a composite product health framework that no single metric could produce alone.

---

## 📊 Executive Summary

### Conversion Funnel

| Stage | Visits | Drop-offs | Drop-off Rate |
|---|---|---|---|
| Homepage | 961 | 189 | 19.67% |
| ProductPage | 995 | 207 | 20.80% |
| **Checkout** | **949** | **465** | **49.00%** |
| Purchase | 1,015 | 0 | 0.00% |

- Homepage and ProductPage are performing well — customers find and browse without friction
- **Checkout collapses at 49%** — nearly 1 in 2 customers who intend to buy never complete the purchase
- The awareness problem is solved. The purchase completion problem is not.

---

### Marketing Performance
- Total reach: **114M+ views, 17.4M+ clicks** across 4,500 engagement records
- CTR is consistent across all channels: SocialMedia (15.26%), Blog (15.23%), Newsletter (15.16%), Video (15.01%)
- No single channel outperforms others — channel mix is not the problem
- Budget allocation should shift toward cost efficiency, not CTR chasing

Implication: Engagement is healthy across all content types. The problem is converting that engagement into purchases at the bottom of the funnel.

---

### Customer Sentiment

| Category | Count | % |
|---|---|---|
| Positive | 962 | 68.7% |
| Neutral | 135 | 9.6% |
| Negative | 118 | 8.4% |
| Mixed Positive | 107 | 7.6% |
| Mixed Negative | 78 | 5.6% |

- Combined negative signal: **14%** — 1 in 7 customers flagging real dissatisfaction
- Average rating directionally positive — but Mixed Negative customers (text negative, rating acceptable) represent a hidden churn risk star ratings alone would miss
- **Unmet Expectations = #1 complaint** — product not matching description drives more complaints than quality, delivery, or price combined

### Product Health Scorecard
Built a composite score across Conversion Rate, Average Rating, and % Positive Sentiment — because no single metric fully captures product health.

| Status | Description |
|---|---|
| 🔴 At Risk | High drop-off, low rating, high negative sentiment |
| 🟡 Needs Attention | Mixed signals across at least one dimension |
| 🟢 Healthy | Strong conversion, rating, and positive sentiment |

---

### Customer Segmentation (RFM)

| Segment | Customers | % |
|---|---|---|
| Potential Loyalists | 188 | 37.6% |
| Loyal Customers | 143 | 28.6% |
| Champions | 94 | 18.8% |
| At Risk | 72 | 14.4% |
| Lost | 3 | 0.6% |

- **56.4% are Loyal Customers or Champions** — a strong base to protect
- **37.6% Potential Loyalists** — the highest-value growth opportunity
- Only 3 customers fully lost — early intervention is working

---

### Geographic Intelligence

| State | Visits | Purchases | Purchase Rate |
|---|---|---|---|
| Gujarat | 578 | 185 | 32.01% |
| Tamil Nadu | 485 | 173 | **35.67%** |
| Uttar Pradesh | 450 | 136 | 30.22% |
| Maharashtra | 416 | 143 | 34.38% |
| Madhya Pradesh | 407 | 129 | 31.70% |

Tamil Nadu converts at 35.67% with fewer visits than Gujarat — highest intent customers in the dataset. Underinvested relative to potential.

---

### Cohort Analysis
Conversion rates across signup cohorts consistently hit **82–100%** — customers who sign up are highly likely to eventually purchase. The problem is not acquisition quality. The problem is checkout friction at the moment of conversion.

---

## 🔍 Insights Deep Dive

### Conversion
- Checkout is the single biggest revenue leak — fixing it does not require more marketing spend
- Customers are reaching Checkout with intent — something at the final step is breaking the experience

### Marketing
- All content types perform within 0.25% CTR of each other — diversified content strategy is working
- Seasonal patterns in engagement should be mapped to inform campaign timing

### Sentiment
- Dissatisfaction is concentrated in product description accuracy — not product quality
- Mixed Negative customers (politely low ratings with negative text) are an underdetected churn signal

---

## ✅ Recommendations

### Short-Term (Conversion & Checkout)
- Audit checkout UX — simplify payment steps, add trust signals, offer guest checkout
- A/B test checkout flow to identify specific friction points
- Improving Checkout conversion by 10% generates ~46 additional purchases per cycle

### Medium-Term (Sentiment & Product)
- Rewrite product descriptions and add realistic sizing guides for high-complaint products
- Flag any product with >20% negative reviews for mandatory supplier review
- Introduce a "Does this match the description?" rating on every review submission

### Long-Term (Retention & Geographic)
- Build cohort-specific onboarding sequences — early engagement predicts long-term conversion
- Increase marketing investment in Tamil Nadu and Maharashtra — both outperform on purchase rate
- Activate win-back campaigns for 72 At Risk customers with time-limited personalised offers

---

## 🧠 Key Analytical Decisions

*The judgement calls that shaped this analysis — not just what was done, but why.*

- **Negative review theme extraction grounded in word frequency** — Filtered negative reviews and ran word frequency analysis to identify dominant complaint vocabulary before building keyword categories. Categories are data-driven — not assumed. Keyword matching does not handle sarcasm; TF-IDF or BERTopic would be more accurate at scale.

- **VADER + Star Rating hybrid sentiment** — Pure VADER scored "The quality is top-notch" as 0.0000. Hybrid categorisation adds star rating context, producing five categories including Mixed types that pure NLP misses.

- **Composite Product Health Score** — No single metric fully captures product risk. Conversion Rate, Average Rating, and % Positive Sentiment combined surface products that look fine on one dimension but are failing on others.

- **Logical duplicate detection over primary key trust** — JourneyID guarantees no technical duplicates, not business ones. ROW_NUMBER() over CustomerID + ProductID + VisitDate + Stage + Action found 80 duplicates the PK would have missed.

- **NULL Duration preserved, not imputed** — 877 NULLs in Duration. Validation confirmed 100% belong to Drop-off rows — system does not record duration when a user exits. Imputing would have invented data that never existed.

- **Physical cleaned tables over views** — Views re-execute on every access. Physical _cleaned tables provide a stable, auditable base for both Python and Power BI connections.

- **SignupDate added to customers** — Enables cohort analysis not possible in most similar projects. Confirms that conversion quality is strong and the problem is behavioral, not demographic.

---

## 🔍 Data Quality Audit Summary

| Table | Issue | Finding | Action |
|---|---|---|---|
| customer_journey | Logical duplicates | 80 (PK-invisible) | Removed via ROW_NUMBER() |
| customer_journey | NULL Duration | 877 — all Drop-offs | Preserved — intentional system behavior |
| customer_journey | Stage casing | 12 variants (3 per value) | CASE WHEN LOWER() |
| customer_journey | Action casing | 15 variants | CASE WHEN LOWER() |
| customer_reviews | ReviewText whitespace | 709 rows | TRIM() + REGEXP_REPLACE() |
| engagement_data | ContentType casing | 12 variants | CASE WHEN LOWER() |
| engagement_data | Combined metric column | "15000-300" string | SPLIT_PART() → Views INT + Clicks INT |

| Table | Raw | Cleaned | Change |
|---|---|---|---|
| customer_journey_cleaned | 4,000 | 3,920 | −80 logical duplicates |
| customer_reviews_cleaned | 1,400 | 1,400 | Structural cleaning only |
| engagement_data_cleaned | 4,500 | 4,500 | Casing + column split |

SQL files: [00_create_tables.sql](sql/00_create_tables.sql) · [01_validation.sql](sql/01_validation.sql) · [02_cleaning_transformation.sql](sql/02_cleaning_transformation.sql) · [03_business_analysis.sql](sql/03_business_analysis.sql)

---

## 🛠️ Tools Used

- **PostgreSQL** — Schema design, data validation, cleaning, and advanced business analysis
- **Python** — NLP sentiment pipeline (VADER + hybrid scoring + keyword theme extraction + GenAI recommendations)
- **Power BI** — Interactive 7-page dashboard with DAX measures and composite product scoring
- **PyTest** — Unit and integration testing for NLP pipeline

---

## ⚠️ Assumptions & Caveats

- Products sourced from real Myntra listing data — all other tables are simulated
- Figures should be interpreted directionally, not as exact Myntra metrics
- Product Health Score uses equal weighting across three metrics — real-world scoring would apply business-weighted priorities
- VADER lexicon gaps addressed via hybrid categorisation — Mixed categories are estimates, not ground truth
- LTV approximated using product price as revenue proxy — actual order value would produce more precise figures

---

## 📬 Contact

**Priyanka Mohapatra** | Data Analyst

**LinkedIn:** [Profile](#) | **GitHub:** [Priyanka-303](https://github.com/Priyanka-303)

---

*Analysis Period: 2023–2024 | Data Source: Myntra (partial real + simulated) | Tools: PostgreSQL · Python · Power BI*
