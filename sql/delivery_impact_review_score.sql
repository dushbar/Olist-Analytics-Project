--late orders usually have lower average
--review scores
SELECT
    CASE 
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time or Early'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(DISTINCT order_id) AS total_orders,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

    SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS low_review_orders,
    CAST(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS low_review_rate_pct

FROM analytics.vw_delivery_performance
WHERE review_score IS NOT NULL
GROUP BY
    CASE 
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time or Early'
        ELSE 'Unknown'
    END;



--average alone is not enought. Need to bucket delay severity
--view for delivery review impact
CREATE VIEW analytics.vw_delivery_review_impact AS
SELECT
    order_id,
    customer_unique_id,
    customer_state,
    order_purchase_timestamp,
    delivery_days,
    delay_days,
    is_late,
    review_score,

    CASE 
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time or Early'
        ELSE 'Unknown'
    END AS delivery_status,

    CASE
        WHEN delay_days <= -7 THEN 'Early by 7+ days'
        WHEN delay_days BETWEEN -6 AND -1 THEN 'Early by 1-6 days'
        WHEN delay_days = 0 THEN 'Delivered on estimated date'
        WHEN delay_days BETWEEN 1 AND 3 THEN 'Late by 1-3 days'
        WHEN delay_days BETWEEN 4 AND 7 THEN 'Late by 4-7 days'
        WHEN delay_days > 7 THEN 'Late by 8+ days'
        ELSE 'Unknown'
    END AS delay_bucket,

    CASE
        WHEN delay_days <= -7 THEN 1
        WHEN delay_days BETWEEN -6 AND -1 THEN 2
        WHEN delay_days = 0 THEN 3
        WHEN delay_days BETWEEN 1 AND 3 THEN 4
        WHEN delay_days BETWEEN 4 AND 7 THEN 5
        WHEN delay_days > 7 THEN 6
        ELSE 99
    END AS delay_bucket_sort,

    CASE 
        WHEN review_score <= 2 THEN 1 ELSE 0 
    END AS is_low_review,

    CASE 
        WHEN review_score >= 4 THEN 1 ELSE 0 
    END AS is_high_review

FROM analytics.vw_delivery_performance
WHERE review_score IS NOT NULL;


--test the view
SELECT TOP 20 *
FROM analytics.vw_delivery_review_impact
ORDER BY order_purchase_timestamp;


--business query using the view
SELECT
    delay_bucket,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

    CAST(
        100.0 * SUM(is_low_review) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS low_review_rate_pct,

    CAST(
        100.0 * SUM(is_high_review) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS high_review_rate_pct

FROM analytics.vw_delivery_review_impact
GROUP BY
    delay_bucket,
    delay_bucket_sort
ORDER BY delay_bucket_sort;


--state-level delivery review impact
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(delay_days AS DECIMAL(10,2))) AS avg_delay_days,

    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate_pct,

    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

    CAST(
        100.0 * SUM(is_low_review) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS low_review_rate_pct

FROM analytics.vw_delivery_review_impact
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) >= 100
ORDER BY late_delivery_rate_pct DESC;



--Insight
--Late delivery is associated with 
--lower customer satisfaction in the Olist dataset. 
--Orders delivered after the estimated 
--delivery date show lower average review scores 
--and higher low-review rates. 
--Some states combine high late-delivery rates 
--with low review scores, indicating possible 
--regional logistics bottlenecks.


--state logistics risk view
--late_delivery_rate_pct >= 15
--avg_review_score < 4.0
--are used as thresholds to 
--segment states into logistics risk groups 
--using late-delivery rate and average review score
--thresholds.
CREATE VIEW analytics.vw_state_logistics_risk AS
SELECT
    customer_state,

    COUNT(DISTINCT order_id) AS total_orders,

    AVG(CAST(delivery_days AS DECIMAL(10,2))) AS avg_delivery_days,
    AVG(CAST(delay_days AS DECIMAL(10,2))) AS avg_delay_days,

    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate_pct,

    AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

    CAST(
        100.0 * SUM(is_low_review) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS low_review_rate_pct,

    CASE
        WHEN 
            100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*) >= 15
            AND AVG(CAST(review_score AS DECIMAL(10,2))) < 4.0
        THEN 'High Risk'

        WHEN 
            100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*) >= 10
            OR AVG(CAST(review_score AS DECIMAL(10,2))) < 4.0
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS logistics_risk_segment

FROM analytics.vw_delivery_review_impact
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) >= 100;

--test the view
SELECT *
FROM analytics.vw_state_logistics_risk
ORDER BY 
    CASE logistics_risk_segment
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        ELSE 3
    END,
    late_delivery_rate_pct DESC;
