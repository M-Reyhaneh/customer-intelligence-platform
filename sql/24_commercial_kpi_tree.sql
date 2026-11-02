-- ============================================================
-- Commercial KPI Tree
--
-- Primary commercial metric:
-- Delivered Merchandise Value
--
-- Decomposition:
--
-- Merchandise Value
--     = Delivered Orders × Merchandise AOV
--
-- Delivered Orders
--     = Active Customers × Orders per Active Customer
--
-- Therefore:
--
-- Merchandise Value
--     = Active Customers
--       × Orders per Active Customer
--       × Merchandise AOV
--
-- Purchase definition:
-- delivered order
--
-- Customer identity:
-- customer_unique_id
-- ============================================================


WITH delivered_orders AS (

    SELECT
        f.order_id,
        c.customer_unique_id,
        f.item_value

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'
),


kpis AS (

    SELECT
        COUNT(DISTINCT order_id)
            AS delivered_orders,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers,

        SUM(item_value)
            AS merchandise_value

    FROM delivered_orders
)


SELECT
    delivered_orders,

    active_customers,

    ROUND(
        delivered_orders::numeric
        / NULLIF(active_customers, 0),
        4
    ) AS orders_per_active_customer,

    ROUND(
        merchandise_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS merchandise_aov,

    ROUND(
        merchandise_value,
        2
    ) AS delivered_merchandise_value,

    ROUND(
        active_customers
        *
        (
            delivered_orders::numeric
            / NULLIF(active_customers, 0)
        )
        *
        (
            merchandise_value
            / NULLIF(delivered_orders, 0)
        ),
        2
    ) AS reconstructed_merchandise_value

FROM kpis;