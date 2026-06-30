--Fact order grain
--expected duplicate_order_rows=0
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM analytics.vw_fact_orders;



--Fact order item grain
--expected duplicate_order_item_rows=0
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS distinct_order_items,
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS duplicate_order_item_rows
FROM analytics.vw_fact_order_items;



--One review per order
--expecte duplicate_review_order_rows=0
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_reviewed_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_review_order_rows
FROM analytics.vw_one_review_per_order;



--Payment reconciliation rows
--expected duplicate_order_rows=0
SELECT
    COUNT(*) AS payment_reconciliation_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM analytics.vw_payment_reconciliation;



--Compare staging order count with order fact count
--expected same count
SELECT
    (SELECT COUNT(*) FROM staging.clean_orders) AS staging_orders,
    (SELECT COUNT(*) FROM analytics.vw_fact_orders) AS fact_orders;


--Compare staging item count with item fact count
--expected same count
SELECT
    (SELECT COUNT(*) FROM staging.clean_order_items) AS staging_order_items,
    (SELECT COUNT(*) FROM analytics.vw_fact_order_items) AS fact_order_items;

--Payment reconciliation status summary
SELECT
    reconciliation_status,
    COUNT(*) AS orders,
    SUM(order_item_total) AS order_item_total,
    SUM(total_payment_value) AS total_payment_value,
    SUM(payment_minus_order_total) AS total_difference
FROM analytics.vw_payment_reconciliation
GROUP BY reconciliation_status
ORDER BY orders DESC;


--duplication safety check:review average
--order grain vs naive item grain
--this shows why you should not use item-level joins for 
--review KPIs
--We see difference between avg_review_score
--which proves item-level duplication affects
--review KPIs
SELECT
    'Order grain - correct' AS method,
    AVG(CAST(review_score AS DECIMAL(10,4))) AS avg_review_score
FROM analytics.vw_fact_orders
WHERE review_score IS NOT NULL

UNION ALL

SELECT
    'Item grain - naive / duplicated' AS method,
    AVG(CAST(r.review_score AS DECIMAL(10,4))) AS avg_review_score
FROM analytics.vw_fact_order_items oi
LEFT JOIN analytics.vw_one_review_per_order r
    ON oi.order_id = r.order_id
WHERE r.review_score IS NOT NULL;