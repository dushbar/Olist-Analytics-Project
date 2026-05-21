CREATE VIEW analytics.vw_category_performance AS
SELECT
    COALESCE(product_category_name_english, 'unknown') AS product_category_name_english,

    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,

    SUM(price) AS product_revenue,
    SUM(freight_value) AS freight_revenue,
    SUM(price + freight_value) AS total_revenue,

    AVG(CAST(price AS DECIMAL(10,2))) AS avg_item_price,
    AVG(CAST(freight_value AS DECIMAL(10,2))) AS avg_freight_value,

    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,
    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,

    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(10,2)
    ) AS late_item_rate_pct
FROM analytics.vw_sales_order_items
WHERE order_status = 'delivered'
GROUP BY COALESCE(product_category_name_english, 'unknown');


--test the view
SELECT TOP 10
    product_category_name_english,
    total_orders,
    total_order_items,
    total_revenue,
    avg_review_score,
    avg_delivery_days,
    late_item_rate_pct
FROM analytics.vw_category_performance
ORDER BY total_revenue DESC;

SELECT TOP 10
    product_category_name_english,
    total_orders,
    total_revenue,
    avg_review_score,
    late_item_rate_pct,
    avg_delivery_days
FROM analytics.vw_category_performance
WHERE total_orders >= 100
ORDER BY avg_review_score ASC;


