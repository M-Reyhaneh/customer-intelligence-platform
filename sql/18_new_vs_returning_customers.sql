-- ============================================================
-- New vs Returning Customer Analysis
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- New customer:
-- customer is active in the same month as their first
-- delivered purchase
--
-- Returning customer:
-- customer has a delivered purchase in a later month
-- ============================================================


-- ------------------------------------------------------------
-- 1. Delivered-order repeat customer profile
-- ------------------------------------------------------------

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,
        COUNT(*) AS delivered_order_count

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS delivered_customers,

    COUNT(*) FILTER (
        WHERE delivered_order_count = 1
    ) AS one_time_delivered_customers,

    COUNT(*) FILTER (
        WHERE delivered_order_count > 1
    ) AS repeat_delivered_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE delivered_order_count > 1
        )::numeric
        /
        NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS repeat_delivered_customer_rate_pct,

    MAX(delivered_order_count)
        AS max_delivered_orders_per_customer

FROM customer_orders;



-- ------------------------------------------------------------
-- 2. Monthly new vs returning customers
-- ------------------------------------------------------------

WITH delivered_orders AS (

    SELECT
        c.customer_unique_id,
        f.order_purchase_date

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'
),


first_purchase AS (

    SELECT
        customer_unique_id,

        MIN(order_purchase_date)
            AS first_purchase_date

    FROM delivered_orders

    GROUP BY
        customer_unique_id
),


monthly_customer_activity AS (

    SELECT DISTINCT
        d.customer_unique_id,

        DATE_TRUNC(
            'month',
            d.order_purchase_date
        )::date AS activity_month,

        DATE_TRUNC(
            'month',
            fp.first_purchase_date
        )::date AS first_purchase_month

    FROM delivered_orders d

    JOIN first_purchase fp
        ON d.customer_unique_id = fp.customer_unique_id
),


monthly_summary AS (

    SELECT
        activity_month AS month,

        COUNT(*) AS active_customers,

        COUNT(*) FILTER (
            WHERE activity_month = first_purchase_month
        ) AS new_customers,

        COUNT(*) FILTER (
            WHERE activity_month > first_purchase_month
        ) AS returning_customers

    FROM monthly_customer_activity

    GROUP BY
        activity_month
)


SELECT
    month,

    active_customers,
    new_customers,
    returning_customers,

    ROUND(
        new_customers::numeric
        /
        NULLIF(active_customers, 0)
        * 100,
        2
    ) AS new_customer_share_pct,

    ROUND(
        returning_customers::numeric
        /
        NULLIF(active_customers, 0)
        * 100,
        2
    ) AS returning_customer_share_pct

FROM monthly_summary

ORDER BY month;