--Create database
CREATE DATABASE OlistAnalytics;
GO

USE OlistAnalytics;
GO

--Create schemas
CREATE SCHEMA staging;--Cleaned CSVs loaded mostly as-is
GO

CREATE SCHEMA analytics;--Views/tables for reporting and Power BI
GO


--validate imports
SELECT COUNT(*) AS row_count FROM staging.orders;
SELECT COUNT(*) AS row_count FROM staging.order_items;
SELECT COUNT(*) AS row_count FROM staging.products;
SELECT COUNT(*) AS row_count FROM staging.customers;
SELECT COUNT(*) AS row_count FROM staging.payments;
SELECT COUNT(*) AS row_count FROM staging.reviews;


--check nulls in key columns
SELECT COUNT(*) AS null_order_id
FROM staging.orders
WHERE order_id IS NULL;

SELECT COUNT(*) AS null_customer_id
FROM staging.customers
WHERE customer_id IS NULL;

SELECT COUNT(*) AS null_product_id
FROM staging.products
WHERE product_id IS NULL;

SELECT COUNT(*) AS null_order_item_id
FROM staging.order_items
WHERE order_id IS NULL;


--check relationship integrity
--orders without customers-expected 0
SELECT COUNT(*) AS orders_without_customer
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--order items without orders-expected 0
SELECT COUNT(*) AS order_items_without_order
FROM staging.order_items oi
LEFT JOIN staging.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--Order items without products-expected 0
SELECT COUNT(*) AS order_items_without_product
FROM staging.order_items oi
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

--Payments without orders-expected 0
SELECT COUNT(*) AS payments_without_order
FROM staging.payments p
LEFT JOIN staging.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

--Add basic constraints after validation
ALTER TABLE staging.orders
ADD CONSTRAINT PK_orders PRIMARY KEY (order_id);

ALTER TABLE staging.customers
ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);

ALTER TABLE staging.products
ADD CONSTRAINT PK_products PRIMARY KEY (product_id);

--composite key for order items
ALTER TABLE staging.order_items
ADD CONSTRAINT PK_order_items 
PRIMARY KEY (order_id, order_item_id);

--composite key for payments
ALTER TABLE staging.payments
ADD CONSTRAINT PK_payments
PRIMARY KEY (order_id, payment_sequential);


--for reviews inspect duplicates first
SELECT 
    review_id,
    COUNT(*) AS row_count
FROM staging.reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

--if there are duplicates remove them first
DELETE T
FROM
(
SELECT *
, DupRank = ROW_NUMBER() OVER (
              PARTITION BY review_id
              ORDER BY (SELECT NULL)
            )
FROM staging.reviews
) AS T
WHERE DupRank > 1 

--add constraint on reviews
ALTER TABLE staging.reviews
ADD CONSTRAINT PK_reviews PRIMARY KEY (review_id);


--create clean sales order-item view
CREATE VIEW analytics.vw_sales_order_items AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    o.purchase_month,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,

    p.product_category_name,
    COALESCE(p.product_category_name_english, 'unknown') 
        AS product_category_name_english,

    r.review_score,

    o.delivery_days,
    o.is_late
FROM staging.orders o
JOIN staging.customers c
    ON o.customer_id = c.customer_id
JOIN staging.order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id
LEFT JOIN staging.reviews r
    ON o.order_id = r.order_id;


--monthly KPI view
CREATE VIEW analytics.vw_monthly_kpis AS
SELECT
    purchase_month,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    SUM(price) AS product_revenue,
    SUM(freight_value) AS freight_revenue,
    SUM(price + freight_value) AS total_revenue,
    AVG(CAST(review_score AS DECIMAL(5,2))) AS avg_review_score,
    AVG(CAST(delivery_days AS DECIMAL(5,2))) AS avg_delivery_days,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_order_items,
    COUNT(*) AS total_order_items,
    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS late_item_rate_pct
FROM analytics.vw_sales_order_items
WHERE order_status = 'delivered'
GROUP BY purchase_month;

--test the view
SELECT *
FROM analytics.vw_monthly_kpis
ORDER BY purchase_month;

--delivery performance view
CREATE VIEW analytics.vw_delivery_performance AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.is_late,

    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_approved_at
    ) AS approval_days,

    DATEDIFF(
        DAY,
        o.order_approved_at,
        o.order_delivered_carrier_date
    ) AS handling_days,

    DATEDIFF(
        DAY,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date
    ) AS carrier_delivery_days,

    DATEDIFF(
        DAY,
        o.order_estimated_delivery_date,
        o.order_delivered_customer_date
    ) AS delay_days,

    r.review_score
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
LEFT JOIN staging.reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

--test the view
SELECT TOP 20 *
FROM analytics.vw_delivery_performance;


--business query using the view
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS delivered_orders,
    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(delay_days AS DECIMAL(10,2))) AS avg_delay_days,
    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS late_delivery_rate_pct,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score
FROM analytics.vw_delivery_performance
GROUP BY customer_state
ORDER BY late_delivery_rate_pct DESC;


