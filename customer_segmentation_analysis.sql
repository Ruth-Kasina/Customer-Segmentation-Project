-- ============================================================
--  Customer Segmentation Analysis — Retail / E-commerce
--  Author  : Ruth Kasina
--  Tool    : MySQL / PostgreSQL compatible
--  Dataset : customer_transactions (500 records, 2022–2024)
--  Purpose : RFM-based customer segmentation to identify
--            Champions, Loyal, At-Risk, and Lost customers
--            and recommend targeted retention strategies.
-- ============================================================


-- ============================================================
-- SECTION 0 : DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS customer_segmentation;
USE customer_segmentation;

DROP TABLE IF EXISTS customer_transactions;

CREATE TABLE customer_transactions (
    transaction_id      VARCHAR(12)     PRIMARY KEY,
    customer_id         VARCHAR(12)     NOT NULL,
    customer_name       VARCHAR(80)     NOT NULL,
    age                 INT,
    gender              VARCHAR(10),
    region              VARCHAR(50),
    transaction_date    DATE            NOT NULL,
    product_category    VARCHAR(50),
    product_name        VARCHAR(80),
    quantity            INT             NOT NULL,
    unit_price_usd      DECIMAL(10,2)   NOT NULL,
    total_amount_usd    DECIMAL(10,2)   NOT NULL,
    payment_method      VARCHAR(30),
    return_flag         VARCHAR(3)      DEFAULT 'No'
);

-- NOTE: Import data from Customer_Segmentation_Dataset.xlsx
--       (Customer_Transactions sheet) before running sections 1–7.


-- ============================================================
-- SECTION 1 : DATA EXPLORATION & QUALITY CHECKS
-- ============================================================

-- 1.1  Basic dataset shape
SELECT
    COUNT(*)                            AS total_transactions,
    COUNT(DISTINCT customer_id)         AS unique_customers,
    COUNT(DISTINCT product_category)    AS product_categories,
    MIN(transaction_date)               AS earliest_date,
    MAX(transaction_date)               AS latest_date,
    ROUND(SUM(total_amount_usd), 2)     AS total_revenue_usd
FROM customer_transactions;

-- 1.2  Check for NULLs in key columns
SELECT
    SUM(CASE WHEN customer_id       IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN transaction_date  IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN total_amount_usd  IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN product_category  IS NULL THEN 1 ELSE 0 END) AS null_category
FROM customer_transactions;

-- 1.3  Returns overview
SELECT
    return_flag,
    COUNT(*)                            AS transactions,
    ROUND(SUM(total_amount_usd), 2)     AS value_affected
FROM customer_transactions
GROUP BY return_flag;

-- 1.4  Transactions per year
SELECT
    YEAR(transaction_date)              AS year,
    COUNT(*)                            AS transactions,
    COUNT(DISTINCT customer_id)         AS active_customers,
    ROUND(SUM(total_amount_usd), 2)     AS annual_revenue
FROM customer_transactions
GROUP BY YEAR(transaction_date)
ORDER BY year;


-- ============================================================
-- SECTION 2 : REVENUE & PURCHASE BEHAVIOUR
-- ============================================================

-- 2.1  Revenue by product category
SELECT
    product_category,
    COUNT(*)                                    AS transactions,
    SUM(quantity)                               AS units_sold,
    ROUND(SUM(total_amount_usd), 2)             AS total_revenue,
    ROUND(AVG(total_amount_usd), 2)             AS avg_order_value,
    ROUND(SUM(total_amount_usd) * 100.0 /
          SUM(SUM(total_amount_usd)) OVER(), 1) AS pct_of_revenue
FROM customer_transactions
WHERE return_flag = 'No'
GROUP BY product_category
ORDER BY total_revenue DESC;

-- 2.2  Revenue by region
SELECT
    region,
    COUNT(DISTINCT customer_id)         AS customers,
    COUNT(*)                            AS transactions,
    ROUND(SUM(total_amount_usd), 2)     AS total_revenue,
    ROUND(AVG(total_amount_usd), 2)     AS avg_order_value
FROM customer_transactions
GROUP BY region
ORDER BY total_revenue DESC;

-- 2.3  Top 10 highest-spending customers
SELECT
    customer_id,
    customer_name,
    COUNT(*)                            AS total_orders,
    ROUND(SUM(total_amount_usd), 2)     AS lifetime_value,
    ROUND(AVG(total_amount_usd), 2)     AS avg_order_value,
    MIN(transaction_date)               AS first_purchase,
    MAX(transaction_date)               AS last_purchase
FROM customer_transactions
WHERE return_flag = 'No'
GROUP BY customer_id, customer_name
ORDER BY lifetime_value DESC
LIMIT 10;

-- 2.4  Monthly revenue trend
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m')  AS month,
    COUNT(*)                                AS transactions,
    ROUND(SUM(total_amount_usd), 2)         AS monthly_revenue,
    COUNT(DISTINCT customer_id)             AS active_customers
FROM customer_transactions
WHERE return_flag = 'No'
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY month;


-- ============================================================
-- SECTION 3 : RFM SCORING
-- -- Recency  = days since last purchase (lower = better)
-- -- Frequency= total number of orders
-- -- Monetary = total spend
-- ============================================================

-- 3.1  Build RFM base table
CREATE OR REPLACE VIEW vw_rfm_base AS
SELECT
    customer_id,
    customer_name,
    COUNT(*)                                        AS frequency,
    ROUND(SUM(total_amount_usd), 2)                 AS monetary,
    ROUND(AVG(total_amount_usd), 2)                 AS avg_order_value,
    MAX(transaction_date)                           AS last_purchase_date,
    DATEDIFF('2025-01-01', MAX(transaction_date))   AS recency_days,
    MIN(transaction_date)                           AS first_purchase_date
FROM customer_transactions
WHERE return_flag = 'No'
GROUP BY customer_id, customer_name;

-- Preview RFM base
SELECT * FROM vw_rfm_base ORDER BY monetary DESC LIMIT 20;

-- 3.2  RFM score using NTILE quartiles
CREATE OR REPLACE VIEW vw_rfm_scores AS
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    avg_order_value,
    NTILE(4) OVER (ORDER BY recency_days ASC)   AS r_score,  -- lower recency = higher score
    NTILE(4) OVER (ORDER BY frequency DESC)     AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC)      AS m_score
FROM vw_rfm_base;

-- Preview scores
SELECT *, (r_score + f_score + m_score) AS rfm_total
FROM vw_rfm_scores
ORDER BY rfm_total DESC
LIMIT 20;


-- ============================================================
-- SECTION 4 : CUSTOMER SEGMENTATION
-- ============================================================

-- 4.1  Assign segments based on RFM scores
CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    avg_order_value,
    r_score, f_score, m_score,
    (r_score + f_score + m_score)   AS rfm_total,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3  THEN 'Champions'
        WHEN f_score >= 3 AND r_score >= 2                   THEN 'Loyal Customers'
        WHEN r_score <= 2 AND f_score >= 2                   THEN 'At Risk'
        ELSE                                                      'Lost Customers'
    END AS segment
FROM vw_rfm_scores;

-- 4.2  Segment overview
SELECT
    segment,
    COUNT(*)                                AS customers,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER(), 1)          AS pct_of_base,
    ROUND(SUM(monetary), 2)                 AS total_revenue,
    ROUND(AVG(monetary), 2)                 AS avg_lifetime_value,
    ROUND(AVG(avg_order_value), 2)          AS avg_order_value,
    ROUND(AVG(frequency), 1)                AS avg_orders,
    ROUND(AVG(recency_days), 0)             AS avg_days_since_purchase
FROM vw_customer_segments
GROUP BY segment
ORDER BY total_revenue DESC;

-- 4.3  Revenue contribution per segment (for 80/20 analysis)
SELECT
    segment,
    ROUND(SUM(monetary), 2)                         AS segment_revenue,
    ROUND(SUM(monetary) * 100.0 /
          SUM(SUM(monetary)) OVER(), 1)             AS pct_of_total_revenue
FROM vw_customer_segments
GROUP BY segment
ORDER BY segment_revenue DESC;


-- ============================================================
-- SECTION 5 : CHURN & RETENTION ANALYSIS
-- ============================================================

-- 5.1  Customers at risk of churning (no purchase in 180–365 days)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    ROUND(monetary, 2)  AS lifetime_value,
    segment
FROM vw_customer_segments
WHERE recency_days BETWEEN 180 AND 365
ORDER BY monetary DESC;

-- 5.2  Lost customers (no purchase in over 365 days)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    ROUND(monetary, 2)  AS lifetime_value
FROM vw_customer_segments
WHERE recency_days > 365
ORDER BY monetary DESC;

-- 5.3  Repeat purchase rate per region
SELECT
    t.region,
    COUNT(DISTINCT t.customer_id)                       AS total_customers,
    SUM(CASE WHEN s.frequency > 1 THEN 1 ELSE 0 END)   AS repeat_customers,
    ROUND(
        SUM(CASE WHEN s.frequency > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(DISTINCT t.customer_id), 1
    )                                                   AS repeat_rate_pct
FROM customer_transactions t
JOIN vw_rfm_base s USING (customer_id)
GROUP BY t.region
ORDER BY repeat_rate_pct DESC;

-- 5.4  Retention cohort — customers who purchased in all 3 years
SELECT
    customer_id,
    customer_name,
    SUM(CASE WHEN YEAR(transaction_date) = 2022 THEN 1 ELSE 0 END) AS purchases_2022,
    SUM(CASE WHEN YEAR(transaction_date) = 2023 THEN 1 ELSE 0 END) AS purchases_2023,
    SUM(CASE WHEN YEAR(transaction_date) = 2024 THEN 1 ELSE 0 END) AS purchases_2024
FROM customer_transactions
GROUP BY customer_id, customer_name
HAVING purchases_2022 > 0 AND purchases_2023 > 0 AND purchases_2024 > 0
ORDER BY customer_id;


-- ============================================================
-- SECTION 6 : PRODUCT & CATEGORY INSIGHTS BY SEGMENT
-- ============================================================

-- 6.1  Favourite product category per segment
SELECT
    cs.segment,
    t.product_category,
    COUNT(*)                            AS purchases,
    ROUND(SUM(t.total_amount_usd), 2)  AS revenue
FROM customer_transactions t
JOIN vw_customer_segments cs USING (customer_id)
WHERE t.return_flag = 'No'
GROUP BY cs.segment, t.product_category
ORDER BY cs.segment, revenue DESC;

-- 6.2  Average order value trend by segment per year
SELECT
    cs.segment,
    YEAR(t.transaction_date)            AS year,
    COUNT(*)                            AS orders,
    ROUND(AVG(t.total_amount_usd), 2)  AS avg_order_value
FROM customer_transactions t
JOIN vw_customer_segments cs USING (customer_id)
WHERE t.return_flag = 'No'
GROUP BY cs.segment, YEAR(t.transaction_date)
ORDER BY cs.segment, year;


-- ============================================================
-- SECTION 7 : RETENTION STRATEGY RECOMMENDATIONS
-- ============================================================

-- 7.1  Priority action list — At Risk customers with high lifetime value
SELECT
    cs.customer_id,
    cs.customer_name,
    cs.segment,
    cs.recency_days,
    cs.frequency,
    ROUND(cs.monetary, 2)               AS lifetime_value,
    ROUND(cs.avg_order_value, 2)        AS avg_order_value,
    'Send personalised win-back email with 15% discount code' AS recommended_action
FROM vw_customer_segments cs
WHERE cs.segment = 'At Risk'
  AND cs.monetary >= 200
ORDER BY cs.monetary DESC;

-- 7.2  Champions — candidates for loyalty programme upgrade
SELECT
    customer_id,
    customer_name,
    frequency                           AS total_orders,
    ROUND(monetary, 2)                  AS lifetime_value,
    recency_days,
    'Enrol in VIP loyalty tier & offer early product access'  AS recommended_action
FROM vw_customer_segments
WHERE segment = 'Champions'
ORDER BY monetary DESC;

-- 7.3  Full segment action summary (for reporting / Power BI)
SELECT
    segment,
    COUNT(*)                            AS customers,
    ROUND(AVG(monetary), 2)             AS avg_ltv,
    ROUND(AVG(recency_days), 0)         AS avg_recency_days,
    CASE segment
        WHEN 'Champions'       THEN 'Reward loyalty — VIP programme, early access, referral bonuses'
        WHEN 'Loyal Customers' THEN 'Upsell & cross-sell — premium tiers, bundled offers'
        WHEN 'At Risk'         THEN 'Win-back campaign — personalised discounts, re-engagement emails'
        WHEN 'Lost Customers'  THEN 'Reactivation offer — strong comeback incentive or sunset'
    END AS retention_strategy
FROM vw_customer_segments
GROUP BY segment
ORDER BY avg_ltv DESC;
