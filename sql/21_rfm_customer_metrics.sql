-- ============================================================
-- RFM Customer Metrics - Base Profiling
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- R = Recency
--     days since customer's latest delivered purchase
--
-- F = Frequency
--     number of delivered orders
--
-- M = Monetary
--     total delivered merchandise value
--     freight excluded
--
-- Important:
-- analysis_date is historical and derived from the dataset.
-- CURRENT_DATE must not be used for this historical snapshot.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Historical analysis date
-- ------------------------------------------------------------

WITH analysis_snapshot AS (

    SELECT
        MAX(order_purchase_date) + 1
            AS analysis_date

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
)

SELECT
    analysis_date

FROM analysis_snapshot;



-- ------------------------------------------------------------
-- 2. Build customer-level RFM metrics
-- ------------------------------------------------------------

WITH analysis_snapshot AS (

    SELECT
        MAX(order_purchase_date) + 1
            AS analysis_date

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
),


customer_rfm AS (

    SELECT
        c.customer_unique_id,

        MAX(f.order_purchase_date)
            AS last_purchase_date,

        a.analysis_date
            - MAX(f.order_purchase_date)
            AS recency_days,

        COUNT(DISTINCT f.order_id)
            AS frequency,

        SUM(f.item_value)
            AS monetary_value

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    CROSS JOIN analysis_snapshot a

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id,
        a.analysis_date
)


SELECT
    COUNT(*) AS customers,

    MIN(recency_days)
        AS min_recency_days,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY recency_days
        ) AS median_recency_days,

    MAX(recency_days)
        AS max_recency_days,


    MIN(frequency)
        AS min_frequency,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY frequency
        ) AS median_frequency,

    MAX(frequency)
        AS max_frequency,


    ROUND(
        MIN(monetary_value),
        2
    ) AS min_monetary_value,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_monetary_value,

    ROUND(
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (
                ORDER BY monetary_value
            )::numeric,
        2
    ) AS median_monetary_value,

    ROUND(
        MAX(monetary_value),
        2
    ) AS max_monetary_value

FROM customer_rfm;



-- ------------------------------------------------------------
-- 3. Frequency distribution
--
-- Important before designing F scores because this dataset
-- contains a very large number of one-time customers.
-- ------------------------------------------------------------

WITH customer_rfm AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT f.order_id)
            AS frequency

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)


SELECT
    frequency,

    COUNT(*) AS customer_count,

    ROUND(
        COUNT(*)::numeric
        /
        SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct

FROM customer_rfm

GROUP BY
    frequency

ORDER BY
    frequency;