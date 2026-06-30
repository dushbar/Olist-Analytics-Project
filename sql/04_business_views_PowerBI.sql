--Monthly KPIs
--Order-grain monthly KPIs
CREATE OR ALTER VIEW analytics.vw_monthly_kpis AS
SELECT
    DATEFROMPARTS(YEAR(order_purchase_date), MONTH(order_purchase_date), 1) AS month_start_date,
    YEAR(order_purchase_date) AS order_year,
    MONTH(order_purchase_date) AS order_month,

    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,

    SUM(item_price_total) AS total_product_revenue,
    SUM(freight_total) AS total_freight_value,
    SUM(order_item_total) AS total_order_value,
    SUM(total_payment_value) AS total_payment_value,

    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(delivery_delay_days AS DECIMAL(10,2))) AS avg_delivery_delay_days,
    AVG(CAST(is_late_delivery AS DECIMAL(10,4))) AS late_delivery_rate,

    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

    AVG(CAST(item_rows AS DECIMAL(10,2))) AS avg_items_per_order,
    AVG(CAST(distinct_sellers AS DECIMAL(10,2))) AS avg_sellers_per_order

FROM analytics.vw_fact_orders
WHERE order_purchase_date IS NOT NULL
GROUP BY 
    DATEFROMPARTS(YEAR(order_purchase_date), MONTH(order_purchase_date), 1),
    YEAR(order_purchase_date),
    MONTH(order_purchase_date);
GO

--Delivery Performance
--Order-grain delivery view
CREATE OR ALTER VIEW analytics.vw_delivery_performance AS
SELECT
    order_id,
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    order_status,
    order_purchase_date,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    delivery_days,
    estimated_delivery_days,
    delivery_delay_days,
    is_late_delivery,
    review_score,
    order_item_total
FROM analytics.vw_fact_orders;
GO


--Delivery and review impact
--Order-grain
CREATE OR ALTER VIEW analytics.vw_delivery_review_impact AS
SELECT
    order_id,
    order_purchase_date,
    customer_state,
    order_status,
    delivery_days,
    delivery_delay_days,
    is_late_delivery,
    review_score,
    order_item_total,
    CASE
        WHEN delivery_delay_days IS NULL THEN 'Unknown'
        WHEN delivery_delay_days <= 0 THEN 'On time / early'
        WHEN delivery_delay_days BETWEEN 1 AND 3 THEN '1-3 days late'
        WHEN delivery_delay_days BETWEEN 4 AND 7 THEN '4-7 days late'
        ELSE '8+ days late'
    END AS delivery_delay_bucket
FROM analytics.vw_fact_orders
WHERE review_score IS NOT NULL;
GO


--State logistics risk
--order-grain by customer state
CREATE OR ALTER VIEW analytics.vw_state_logistics_risk AS
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(order_item_total) AS total_order_value,
    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(delivery_delay_days AS DECIMAL(10,2))) AS avg_delivery_delay_days,
    AVG(CAST(is_late_delivery AS DECIMAL(10,4))) AS late_delivery_rate,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score
FROM analytics.vw_fact_orders
WHERE customer_state IS NOT NULL
GROUP BY customer_state;
GO



--Category performance
--We do not calcualte review score by directly
--joining item rows to reviews and averaging
--instead create an order-category bridge first
CREATE OR ALTER VIEW analytics.vw_order_category_rollup AS
SELECT
    oi.order_id,
    COALESCE(oi.product_category_name_english, oi.product_category_name, 'Unknown') AS product_category,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT oi.product_id) AS distinct_products,
    COUNT(DISTINCT oi.seller_id) AS distinct_sellers,
    SUM(oi.price) AS product_revenue,
    SUM(oi.freight_value) AS freight_value,
    SUM(oi.item_total_value) AS total_value
FROM analytics.vw_fact_order_items oi
GROUP BY
    oi.order_id,
    COALESCE(oi.product_category_name_english, oi.product_category_name, 'Unknown');
GO
--now category performance
CREATE OR ALTER VIEW analytics.vw_category_performance AS
SELECT
    oc.product_category,

    COUNT(DISTINCT oc.order_id) AS total_orders,
    SUM(oc.item_rows) AS total_item_rows,
    SUM(oc.distinct_products) AS product_order_touchpoints,
    SUM(oc.product_revenue) AS product_revenue,
    SUM(oc.freight_value) AS freight_value,
    SUM(oc.total_value) AS total_value,

    AVG(CAST(fo.review_score AS DECIMAL(10,2))) AS avg_review_score,
    AVG(CAST(fo.delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(fo.is_late_delivery AS DECIMAL(10,4))) AS late_delivery_rate

FROM analytics.vw_order_category_rollup oc
LEFT JOIN analytics.vw_fact_orders fo
    ON oc.order_id = fo.order_id
GROUP BY oc.product_category;
GO


--Seller performance
--create an order-seller rollup first
CREATE OR ALTER VIEW analytics.vw_order_seller_rollup AS
SELECT
    oi.order_id,
    oi.seller_id,
    oi.seller_city,
    oi.seller_state,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT oi.product_id) AS distinct_products,
    SUM(oi.price) AS product_revenue,
    SUM(oi.freight_value) AS freight_value,
    SUM(oi.item_total_value) AS total_value
FROM analytics.vw_fact_order_items oi
GROUP BY
    oi.order_id,
    oi.seller_id,
    oi.seller_city,
    oi.seller_state;
GO
--now seller performance
CREATE OR ALTER VIEW analytics.vw_seller_performance AS
SELECT
    os.seller_id,
    os.seller_city,
    os.seller_state,

    COUNT(DISTINCT os.order_id) AS total_orders,
    SUM(os.item_rows) AS total_item_rows,
    SUM(os.distinct_products) AS product_order_touchpoints,
    SUM(os.product_revenue) AS product_revenue,
    SUM(os.freight_value) AS freight_value,
    SUM(os.total_value) AS total_value,

    AVG(CAST(fo.review_score AS DECIMAL(10,2))) AS avg_review_score,
    AVG(CAST(fo.delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(fo.delivery_delay_days AS DECIMAL(10,2))) AS avg_delivery_delay_days,
    AVG(CAST(fo.is_late_delivery AS DECIMAL(10,4))) AS late_delivery_rate

FROM analytics.vw_order_seller_rollup os
LEFT JOIN analytics.vw_fact_orders fo
    ON os.order_id = fo.order_id
GROUP BY
    os.seller_id,
    os.seller_city,
    os.seller_state;
GO



--Seller risk segments
CREATE OR ALTER VIEW analytics.vw_seller_risk_segments AS
SELECT
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    total_item_rows,
    product_revenue,
    total_value,
    avg_review_score,
    avg_delivery_days,
    avg_delivery_delay_days,
    late_delivery_rate,
    CASE
        WHEN total_orders < 20 THEN 'Low volume'
        WHEN avg_review_score < 3.5 AND late_delivery_rate >= 0.20 THEN 'High risk'
        WHEN avg_review_score < 4.0 OR late_delivery_rate >= 0.15 THEN 'Medium risk'
        ELSE 'Low risk'
    END AS seller_risk_segment
FROM analytics.vw_seller_performance;
GO



--Customer orders
--order-grain customer behaviour
CREATE OR ALTER VIEW analytics.vw_customer_orders AS
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    MIN(order_purchase_date) AS first_order_date,
    MAX(order_purchase_date) AS last_order_date,
    SUM(order_item_total) AS total_order_value,
    AVG(order_item_total) AS avg_order_value,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,
    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days
FROM analytics.vw_fact_orders
WHERE customer_unique_id IS NOT NULL
GROUP BY customer_unique_id;
GO


--Cohort retention base
--Use order grain not item grain
CREATE OR ALTER VIEW analytics.vw_customer_order_cohort_base AS
WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        DATEFROMPARTS(YEAR(order_purchase_date), MONTH(order_purchase_date), 1) AS order_month
    FROM analytics.vw_fact_orders
    WHERE customer_unique_id IS NOT NULL
      AND order_purchase_date IS NOT NULL
),
first_orders AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY customer_unique_id
)
SELECT
    co.customer_unique_id,
    co.order_id,
    fo.cohort_month,
    co.order_month,
    DATEDIFF(MONTH, fo.cohort_month, co.order_month) AS cohort_index
FROM customer_orders co
INNER JOIN first_orders fo
    ON co.customer_unique_id = fo.customer_unique_id;
GO


--Retention view
CREATE OR ALTER VIEW analytics.vw_cohort_retention AS
SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_unique_id) AS active_customers
FROM analytics.vw_customer_order_cohort_base
GROUP BY cohort_month, cohort_index;
GO


--Retention Matrix
CREATE OR ALTER VIEW analytics.vw_cohort_retention_matrix AS
WITH cohort_sizes AS (
    SELECT
        cohort_month,
        active_customers AS cohort_size
    FROM analytics.vw_cohort_retention
    WHERE cohort_index = 0
)
SELECT
    cr.cohort_month,
    cr.cohort_index,
    cr.active_customers,
    cs.cohort_size,
    CAST(cr.active_customers AS DECIMAL(10,4)) / NULLIF(cs.cohort_size, 0) AS retention_rate
FROM analytics.vw_cohort_retention cr
INNER JOIN cohort_sizes cs
    ON cr.cohort_month = cs.cohort_month;
GO