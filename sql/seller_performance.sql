--seller performance view
CREATE VIEW analytics.vw_seller_performance AS
SELECT
    seller_id,

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
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS late_item_rate_pct,

    CAST(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS low_review_item_rate_pct

FROM analytics.vw_sales_order_items
WHERE order_status = 'delivered'
GROUP BY seller_id;

--test the view
SELECT TOP 20 *
FROM analytics.vw_seller_performance
ORDER BY total_revenue DESC;

--identify high-revenue poor-experience sellers
SELECT TOP 20
    seller_id,
    total_orders,
    total_order_items,
    total_revenue,
    avg_review_score,
    late_item_rate_pct,
    low_review_item_rate_pct
FROM analytics.vw_seller_performance
WHERE total_orders >= 50
ORDER BY
    total_revenue DESC;


--seller risk segmentation view
CREATE VIEW analytics.vw_seller_risk_segments AS
SELECT
    seller_id,
    total_orders,
    total_order_items,
    unique_customers,
    product_revenue,
    freight_revenue,
    total_revenue,
    avg_review_score,
    avg_delivery_days,
    late_item_rate_pct,
    low_review_item_rate_pct,

    CASE
        WHEN total_orders >= 50
             AND total_revenue >= 10000
             AND (
                 avg_review_score < 4.0
                 OR late_item_rate_pct >= 15
                 OR low_review_item_rate_pct >= 20
             )
        THEN 'High Revenue / High Risk'

        WHEN total_orders >= 50
             AND avg_review_score >= 4.5
             AND late_item_rate_pct < 10
        THEN 'Reliable Seller'

        WHEN total_orders < 10
        THEN 'Low Volume Seller'

        ELSE 'Standard Seller'
    END AS seller_segment

FROM analytics.vw_seller_performance;


--test the view
SELECT
    seller_segment,
    COUNT(*) AS seller_count,
    SUM(total_revenue) AS segment_revenue,
    AVG(avg_review_score) AS avg_segment_review_score,
    AVG(late_item_rate_pct) AS avg_late_item_rate_pct
FROM analytics.vw_seller_risk_segments
GROUP BY seller_segment
ORDER BY segment_revenue DESC;

--Insight
--Seller-level analysis identified a subset 
--of high-revenue sellers with elevated 
--late-delivery rates and weaker review scores. 
--These sellers represent operational risk 
--because they contribute meaningful revenue 
--while potentially damaging customer satisfaction.


