-- ============================================================
-- Historical LTV-style Customer Value Metrics
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- Value definition:
-- delivered merchandise value
-- freight excluded
--
-- Important:
-- This is observed historical customer value inside the
-- dataset window. It is NOT predictive lifetime CLV.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Overall historical customer value
-- ------------------------------------------------------------

WITH customer_value AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT f.order_id)
            AS delivered_orders,

        SUM(f.item_value)
            AS historical_merchandise_value

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS customers,

    ROUND(
        AVG(delivered_orders),
        2
    ) AS avg_delivered_orders_per_customer,

    ROUND(
        AVG(historical_merchandise_value),
        2
    ) AS avg_historical_customer_value,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY historical_merchandise_value
        )::numeric,
        2
    ) AS median_historical_customer_value,

    ROUND(
        SUM(historical_merchandise_value),
        2
    ) AS total_historical_merchandise_value

FROM customer_value;



-- ------------------------------------------------------------
-- 2. One-time vs repeat customer value
-- ------------------------------------------------------------

WITH customer_value AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT f.order_id)
            AS delivered_orders,

        SUM(f.item_value)
            AS historical_merchandise_value

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),


customer_type AS (

    SELECT
        *,

        CASE
            WHEN delivered_orders = 1
                THEN 'One-time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type

    FROM customer_value
),


type_summary AS (

    SELECT
        customer_type,

        COUNT(*) AS customers,

        AVG(delivered_orders)
            AS avg_delivered_orders,

        AVG(historical_merchandise_value)
            AS avg_historical_customer_value,

        SUM(historical_merchandise_value)
            AS total_historical_merchandise_value

    FROM customer_type

    GROUP BY
        customer_type
)

SELECT
    customer_type,

    customers,

    ROUND(
        customers::numeric
        /
        SUM(customers) OVER ()
        * 100,
        2
    ) AS customer_share_pct,

    ROUND(
        avg_delivered_orders,
        2
    ) AS avg_delivered_orders,

    ROUND(
        avg_historical_customer_value,
        2
    ) AS avg_historical_customer_value,

    ROUND(
        total_historical_merchandise_value,
        2
    ) AS total_historical_merchandise_value,

    ROUND(
        total_historical_merchandise_value
        /
        SUM(total_historical_merchandise_value) OVER ()
        * 100,
        2
    ) AS merchandise_value_share_pct

FROM type_summary

ORDER BY
    avg_historical_customer_value DESC;