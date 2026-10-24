-- ============================================================
-- Monthly E-commerce KPIs
--
-- Grain:
-- one row per calendar month
--
-- Order date:
-- order purchase date
--
-- Primary commercial metric:
-- delivered merchandise value
-- ============================================================


WITH purchase_bounds AS (

    SELECT
        MIN(order_purchase_date) AS min_purchase_date,
        MAX(order_purchase_date) AS max_purchase_date

    FROM analytics.fact_orders
),


monthly AS (

    SELECT
        DATE_TRUNC('month', d.date_day)::date AS month,


        -- ----------------------------------------------------
        -- Order volume
        -- ----------------------------------------------------

        COUNT(f.order_id) AS total_orders,

        COUNT(f.order_id) FILTER (
            WHERE f.order_status = 'delivered'
        ) AS delivered_orders,

        COUNT(f.order_id) FILTER (
            WHERE f.order_status = 'canceled'
        ) AS canceled_orders,


        -- ----------------------------------------------------
        -- Merchandise value
        -- Product value only
        -- ----------------------------------------------------

        COALESCE(
            SUM(f.item_value) FILTER (
                WHERE f.order_status = 'delivered'
            ),
            0
        ) AS delivered_merchandise_value,


        -- ----------------------------------------------------
        -- Freight charged
        -- ----------------------------------------------------

        COALESCE(
            SUM(f.freight_value) FILTER (
                WHERE f.order_status = 'delivered'
            ),
            0
        ) AS delivered_freight_charged,


        -- ----------------------------------------------------
        -- Checkout value
        -- Merchandise + freight
        -- ----------------------------------------------------

        COALESCE(
            SUM(f.item_plus_freight_value) FILTER (
                WHERE f.order_status = 'delivered'
            ),
            0
        ) AS delivered_checkout_value,


        -- ----------------------------------------------------
        -- Recorded payments
        -- Kept separate from checkout value
        -- ----------------------------------------------------

        COALESCE(
            SUM(f.payment_value) FILTER (
                WHERE f.order_status = 'delivered'
            ),
            0
        ) AS delivered_recorded_payment_value


    FROM analytics.dim_date d

    CROSS JOIN purchase_bounds b

    LEFT JOIN analytics.fact_orders f
        ON d.date_day = f.order_purchase_date

    WHERE d.date_day BETWEEN
        b.min_purchase_date
        AND b.max_purchase_date

    GROUP BY
        DATE_TRUNC('month', d.date_day)::date
),


monthly_with_previous AS (

    SELECT
        *,

        LAG(delivered_merchandise_value) OVER (
            ORDER BY month
        ) AS previous_month_merchandise_value

    FROM monthly
)


SELECT
    month,

    total_orders,
    delivered_orders,
    canceled_orders,


    -- --------------------------------------------------------
    -- Commercial KPIs
    -- --------------------------------------------------------

    ROUND(
        delivered_merchandise_value,
        2
    ) AS delivered_merchandise_value,

    ROUND(
        delivered_freight_charged,
        2
    ) AS delivered_freight_charged,

    ROUND(
        delivered_checkout_value,
        2
    ) AS delivered_checkout_value,

    ROUND(
        delivered_recorded_payment_value,
        2
    ) AS delivered_recorded_payment_value,


    -- --------------------------------------------------------
    -- Merchandise AOV
    -- Freight intentionally excluded
    -- --------------------------------------------------------

    ROUND(
        delivered_merchandise_value
        /
        NULLIF(delivered_orders, 0),
        2
    ) AS delivered_merchandise_aov,


    -- --------------------------------------------------------
    -- Cancellation rate
    -- --------------------------------------------------------

    ROUND(
        canceled_orders::numeric
        /
        NULLIF(total_orders, 0)
        * 100,
        2
    ) AS cancellation_rate_pct,


    -- --------------------------------------------------------
    -- Previous month merchandise value
    -- --------------------------------------------------------

    ROUND(
        previous_month_merchandise_value,
        2
    ) AS previous_month_merchandise_value,


    -- --------------------------------------------------------
    -- Month-over-month merchandise growth
    -- --------------------------------------------------------

    ROUND(
        (
            delivered_merchandise_value
            - previous_month_merchandise_value
        )
        /
        NULLIF(previous_month_merchandise_value, 0)
        * 100,
        2
    ) AS merchandise_mom_growth_pct


FROM monthly_with_previous

ORDER BY month;