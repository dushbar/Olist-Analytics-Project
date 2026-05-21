--create customers orders view
CREATE VIEW analytics.vw_customer_orders AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,

    CAST(
        DATEFROMPARTS(
            YEAR(o.order_purchase_timestamp),
            MONTH(o.order_purchase_timestamp),
            1
        ) AS DATE
    ) AS purchase_month,

    c.customer_city,
    c.customer_state
FROM staging.orders o
JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE 
    o.order_status = 'delivered'
    AND o.order_purchase_timestamp IS NOT NULL;


--test the view
SELECT TOP 20 *
FROM analytics.vw_customer_orders
ORDER BY order_purchase_timestamp;

SELECT COUNT(*) AS delivered_order_count
FROM analytics.vw_customer_orders;




--create cohort base view
--identifies each customer's first purchase month
CREATE VIEW analytics.vw_customer_cohorts AS
WITH first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month
    FROM analytics.vw_customer_orders
    GROUP BY customer_unique_id
)
SELECT
    co.customer_unique_id,
    co.order_id,
    co.purchase_month,
    fp.cohort_month,

    DATEDIFF(
        MONTH,
        fp.cohort_month,
        co.purchase_month
    ) AS cohort_index,

    co.customer_state
FROM analytics.vw_customer_orders co
JOIN first_purchase fp
    ON co.customer_unique_id = fp.customer_unique_id;



--cohort retention counts
SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_unique_id) AS retained_customers
FROM analytics.vw_customer_cohorts
GROUP BY
    cohort_month,
    cohort_index
ORDER BY
    cohort_month,
    cohort_index;


--cohort retention percentage
WITH cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS retained_customers
    FROM analytics.vw_customer_cohorts
    GROUP BY
        cohort_month,
        cohort_index
),
cohort_sizes AS (
    SELECT
        cohort_month,
        retained_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    cc.cohort_month,
    cc.cohort_index,
    cs.cohort_size,
    cc.retained_customers,
    CAST(
        100.0 * cc.retained_customers / cs.cohort_size
        AS DECIMAL(10,2)
    ) AS retention_rate_pct
FROM cohort_counts cc
JOIN cohort_sizes cs
    ON cc.cohort_month = cs.cohort_month
ORDER BY
    cc.cohort_month,
    cc.cohort_index;


--save final cohort retention view
CREATE VIEW analytics.vw_cohort_retention AS
WITH cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS retained_customers
    FROM analytics.vw_customer_cohorts
    GROUP BY
        cohort_month,
        cohort_index
),
cohort_sizes AS (
    SELECT
        cohort_month,
        retained_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    cc.cohort_month,
    cc.cohort_index,
    cs.cohort_size,
    cc.retained_customers,
    CAST(
        100.0 * cc.retained_customers / cs.cohort_size
        AS DECIMAL(10,2)
    ) AS retention_rate_pct
FROM cohort_counts cc
JOIN cohort_sizes cs
    ON cc.cohort_month = cs.cohort_month;


--test the view
SELECT *
FROM analytics.vw_cohort_retention
ORDER BY cohort_month, cohort_index;



--create pivoted retention matrix
SELECT
    cohort_month,
    cohort_size,

    MAX(CASE WHEN cohort_index = 0 THEN retention_rate_pct END) AS month_0,
    MAX(CASE WHEN cohort_index = 1 THEN retention_rate_pct END) AS month_1,
    MAX(CASE WHEN cohort_index = 2 THEN retention_rate_pct END) AS month_2,
    MAX(CASE WHEN cohort_index = 3 THEN retention_rate_pct END) AS month_3,
    MAX(CASE WHEN cohort_index = 4 THEN retention_rate_pct END) AS month_4,
    MAX(CASE WHEN cohort_index = 5 THEN retention_rate_pct END) AS month_5,
    MAX(CASE WHEN cohort_index = 6 THEN retention_rate_pct END) AS month_6,
    MAX(CASE WHEN cohort_index = 7 THEN retention_rate_pct END) AS month_7,
    MAX(CASE WHEN cohort_index = 8 THEN retention_rate_pct END) AS month_8,
    MAX(CASE WHEN cohort_index = 9 THEN retention_rate_pct END) AS month_9,
    MAX(CASE WHEN cohort_index = 10 THEN retention_rate_pct END) AS month_10,
    MAX(CASE WHEN cohort_index = 11 THEN retention_rate_pct END) AS month_11,
    MAX(CASE WHEN cohort_index = 12 THEN retention_rate_pct END) AS month_12
FROM analytics.vw_cohort_retention
GROUP BY
    cohort_month,
    cohort_size
ORDER BY cohort_month;



--create cohort matrix view
CREATE VIEW analytics.vw_cohort_retention_matrix AS
SELECT
    cohort_month,
    cohort_size,

    MAX(CASE WHEN cohort_index = 0 THEN retention_rate_pct END) AS month_0,
    MAX(CASE WHEN cohort_index = 1 THEN retention_rate_pct END) AS month_1,
    MAX(CASE WHEN cohort_index = 2 THEN retention_rate_pct END) AS month_2,
    MAX(CASE WHEN cohort_index = 3 THEN retention_rate_pct END) AS month_3,
    MAX(CASE WHEN cohort_index = 4 THEN retention_rate_pct END) AS month_4,
    MAX(CASE WHEN cohort_index = 5 THEN retention_rate_pct END) AS month_5,
    MAX(CASE WHEN cohort_index = 6 THEN retention_rate_pct END) AS month_6,
    MAX(CASE WHEN cohort_index = 7 THEN retention_rate_pct END) AS month_7,
    MAX(CASE WHEN cohort_index = 8 THEN retention_rate_pct END) AS month_8,
    MAX(CASE WHEN cohort_index = 9 THEN retention_rate_pct END) AS month_9,
    MAX(CASE WHEN cohort_index = 10 THEN retention_rate_pct END) AS month_10,
    MAX(CASE WHEN cohort_index = 11 THEN retention_rate_pct END) AS month_11,
    MAX(CASE WHEN cohort_index = 12 THEN retention_rate_pct END) AS month_12
FROM analytics.vw_cohort_retention
GROUP BY
    cohort_month,
    cohort_size;


--check
SELECT TOP 20 *
FROM analytics.vw_customer_cohorts
ORDER BY cohort_month, customer_unique_id;

SELECT *
FROM analytics.vw_cohort_retention
ORDER BY cohort_month, cohort_index;

SELECT *
FROM analytics.vw_cohort_retention_matrix
ORDER BY cohort_month;

--
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END) AS repeat_customers,
    CAST(
        100.0 * COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END)
        / COUNT(DISTINCT customer_unique_id)
        AS DECIMAL(10,2)
    ) AS repeat_customer_rate_pct
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM analytics.vw_customer_orders
    GROUP BY customer_unique_id
) x;


SELECT *
FROM analytics.vw_cohort_retention
WHERE cohort_index = 0
ORDER BY cohort_month;


SELECT
    order_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM analytics.vw_customer_orders
    GROUP BY customer_unique_id
) x
GROUP BY order_count
ORDER BY order_count;