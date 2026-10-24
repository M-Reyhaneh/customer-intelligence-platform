-- ============================================================
-- Comparable Monthly Trend Analysis
--
-- Comparable window:
-- February 2017 through August 2018
--
-- Why this window?
-- These months have stable/full purchase-date coverage,
-- unlike the sparse boundary periods of the dataset.
--
-- Goal:
-- Decompose merchandise-value changes into:
--   1. order-volume change
--   2. AOV change
-- ============================================================


WITH monthly_base AS (

    SELECT
        DATE_TRUNC('month', order_purchase_date)::date AS month,

        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,

        COALESCE(
            SUM(item_value) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) AS delivered_merchandise_value

    FROM analytics.fact_orders

    WHERE order_purchase_date >= DATE '2017-02-01'
      AND order_purchase_date <  DATE '2018-09-01'

    GROUP BY
        DATE_TRUNC('month', order_purchase_date)::date
),


monthly_metrics AS (

    SELECT
        month,
        delivered_orders,
        delivered_merchandise_value,

        delivered_merchandise_value
        /
        NULLIF(delivered_orders, 0)
            AS delivered_merchandise_aov

    FROM monthly_base
),


with_previous AS (

    SELECT
        *,

        LAG(delivered_orders) OVER (
            ORDER BY month
        ) AS previous_delivered_orders,

        LAG(delivered_merchandise_value) OVER (
            ORDER BY month
        ) AS previous_merchandise_value,

        LAG(delivered_merchandise_aov) OVER (
            ORDER BY month
        ) AS previous_merchandise_aov

    FROM monthly_metrics
)


SELECT
    month,

    delivered_orders,

    ROUND(
        delivered_merchandise_value,
        2
    ) AS delivered_merchandise_value,

    ROUND(
        delivered_merchandise_aov,
        2
    ) AS delivered_merchandise_aov,


    -- --------------------------------------------------------
    -- Absolute changes
    -- --------------------------------------------------------

    delivered_orders
        - previous_delivered_orders
        AS delivered_orders_change,

    ROUND(
        delivered_merchandise_value
        - previous_merchandise_value,
        2
    ) AS merchandise_value_change,

    ROUND(
        delivered_merchandise_aov
        - previous_merchandise_aov,
        2
    ) AS merchandise_aov_change,


    -- --------------------------------------------------------
    -- Relative / MoM changes
    -- --------------------------------------------------------

    ROUND(
        (
            delivered_orders
            - previous_delivered_orders
        )::numeric
        /
        NULLIF(previous_delivered_orders, 0)
        * 100,
        2
    ) AS delivered_orders_mom_growth_pct,

    ROUND(
        (
            delivered_merchandise_value
            - previous_merchandise_value
        )
        /
        NULLIF(previous_merchandise_value, 0)
        * 100,
        2
    ) AS merchandise_mom_growth_pct,

    ROUND(
        (
            delivered_merchandise_aov
            - previous_merchandise_aov
        )
        /
        NULLIF(previous_merchandise_aov, 0)
        * 100,
        2
    ) AS merchandise_aov_mom_growth_pct

FROM with_previous

ORDER BY month;