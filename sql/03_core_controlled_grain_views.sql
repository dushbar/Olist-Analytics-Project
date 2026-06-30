--one review per order view
CREATE OR ALTER VIEW analytics.vw_one_review_per_order AS
WITH ranked_reviews AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id
            ORDER BY 
                r.review_creation_date DESC,
                r.review_answer_timestamp DESC,
                r.review_id DESC
        ) AS rn
    FROM staging.clean_reviews r
)
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM ranked_reviews
WHERE rn = 1;
GO

--Validation: Expected 0 rows
--SELECT order_id, COUNT(*) AS row_count
--FROM analytics.vw_one_review_per_order
--GROUP BY order_id
--HAVING COUNT(*) > 1;


--Payment summary per order
CREATE OR ALTER VIEW analytics.vw_payment_summary_order AS
SELECT
    order_id,
    COUNT(*) AS payment_rows,
    COUNT(DISTINCT payment_type) AS payment_type_count,
    SUM(payment_value) AS total_payment_value,
    MAX(payment_installments) AS max_payment_installments,
    SUM(CASE WHEN payment_type = 'credit_card' THEN payment_value ELSE 0 END) AS credit_card_payment_value,
    SUM(CASE WHEN payment_type = 'boleto' THEN payment_value ELSE 0 END) AS boleto_payment_value,
    SUM(CASE WHEN payment_type = 'voucher' THEN payment_value ELSE 0 END) AS voucher_payment_value,
    SUM(CASE WHEN payment_type = 'debit_card' THEN payment_value ELSE 0 END) AS debit_card_payment_value
FROM staging.clean_payments
GROUP BY order_id;
GO

--Order item summary per order
CREATE OR ALTER VIEW analytics.vw_order_item_summary_order AS
SELECT
    order_id,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    SUM(price) AS item_price_total,
    SUM(freight_value) AS freight_total,
    SUM(price + freight_value) AS order_item_total
FROM staging.clean_order_items
GROUP BY order_id;
GO


--payment reconciliation view
CREATE OR ALTER VIEW analytics.vw_payment_reconciliation AS
SELECT
    o.order_id,
    o.order_status,
    oi.item_rows,
    oi.distinct_products,
    oi.distinct_sellers,
    oi.item_price_total,
    oi.freight_total,
    oi.order_item_total,
    ps.payment_rows,
    ps.payment_type_count,
    ps.total_payment_value,
    ps.max_payment_installments,
    ps.credit_card_payment_value,
    ps.boleto_payment_value,
    ps.voucher_payment_value,
    ps.debit_card_payment_value,
    COALESCE(ps.total_payment_value, 0) - COALESCE(oi.order_item_total, 0) AS payment_minus_order_total,
    CASE
        WHEN ps.order_id IS NULL THEN 'Missing payment'
        WHEN oi.order_id IS NULL THEN 'Missing order items'
        WHEN ABS(COALESCE(ps.total_payment_value, 0) - COALESCE(oi.order_item_total, 0)) <= 0.05 THEN 'Reconciled'
        ELSE 'Mismatch'
    END AS reconciliation_status
FROM staging.clean_orders o
LEFT JOIN analytics.vw_order_item_summary_order oi
    ON o.order_id = oi.order_id
LEFT JOIN analytics.vw_payment_summary_order ps
    ON o.order_id = ps.order_id;
GO



--order level fact view
CREATE OR ALTER VIEW analytics.vw_fact_orders AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,

    CAST(o.order_purchase_timestamp AS DATE) AS order_purchase_date,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) AS estimated_delivery_days,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_delay_days,

    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_late_delivery,

    oi.item_rows,
    oi.distinct_products,
    oi.distinct_sellers,
    oi.item_price_total,
    oi.freight_total,
    oi.order_item_total,

    ps.payment_rows,
    ps.payment_type_count,
    ps.total_payment_value,
    ps.max_payment_installments,

    r.review_id,
    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp

FROM staging.clean_orders o
LEFT JOIN staging.clean_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN analytics.vw_order_item_summary_order oi
    ON o.order_id = oi.order_id
LEFT JOIN analytics.vw_payment_summary_order ps
    ON o.order_id = ps.order_id
LEFT JOIN analytics.vw_one_review_per_order r
    ON o.order_id = r.order_id;
GO

--Validation--Both numbers should match
--SELECT 
--    COUNT(*) AS rows_in_fact_orders,
--    COUNT(DISTINCT order_id) AS distinct_orders
--FROM analytics.vw_fact_orders;

--order-item-level fact view
CREATE OR ALTER VIEW analytics.vw_fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,
    c.customer_unique_id,

    CAST(o.order_purchase_timestamp AS DATE) AS order_purchase_date,
    o.order_purchase_timestamp,
    o.order_status,

    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS item_total_value,

    p.product_category_name,
    p.product_category_name_english,

    s.seller_city,
    s.seller_state,

    c.customer_city,
    c.customer_state

FROM staging.clean_order_items oi
LEFT JOIN staging.clean_orders o
    ON oi.order_id = o.order_id
LEFT JOIN staging.clean_products p
    ON oi.product_id = p.product_id
LEFT JOIN staging.clean_sellers s
    ON oi.seller_id = s.seller_id
LEFT JOIN staging.clean_customers c
    ON o.customer_id = c.customer_id;
GO


--Validation--duplicate_item_keys should be 0
--SELECT 
--    COUNT(*) AS rows_in_fact_order_items,
--    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS duplicate_item_keys
--FROM analytics.vw_fact_order_items;