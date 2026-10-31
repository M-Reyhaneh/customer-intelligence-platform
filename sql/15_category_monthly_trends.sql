-- ============================================================
-- Monthly Trends for Top Product Categories
--
-- Comparable window:
-- February 2017 through August 2018
--
-- Population:
-- delivered orders only
--
-- Goal:
-- identify which categories drive merchandise-value growth
-- ============================================================


WITH top_categories AS (

    SELECT
        p.product_category_name_display AS category,
        SUM(f.price) AS total_merchandise_value

    FROM analytics.fact_order_items f

    JOIN analytics.dim_products p
        ON f.product_id = p.product_id

    WHERE f.order_status = 'delivered'
      AND f.order_purchase_date >= DATE '2017-02-01'
      AND f.order_purchase_date <  DATE '2018-09-01'

    GROUP BY
        p.product_category_name_display

    ORDER BY
        total_merchandise_value DESC

    LIMIT 5
),


months AS (

    SELECT
        generate_series(
            DATE '2017-02-01',
            DATE '2018-08-01',
            INTERVAL '1 month'
        )::date AS month
),


category_monthly_base AS (

    SELECT
        DATE_TRUNC(
            'month',
            f.order_purchase_date
        )::date AS month,

        p.product_category_name_display AS category,

        COUNT(*) AS delivered_item_count,

        COUNT(DISTINCT f.order_id) AS delivered_orders,

        SUM(f.price) AS merchandise_value

    FROM analytics.fact_order_items f

    JOIN analytics.dim_products p
        ON f.product_id = p.product_id

    JOIN top_categories tc
        ON p.product_category_name_display = tc.category

    WHERE f.order_status = 'delivered'
      AND f.order_purchase_date >= DATE '2017-02-01'
      AND f.order_purchase_date <  DATE '2018-09-01'

    GROUP BY
        DATE_TRUNC('month', f.order_purchase_date)::date,
        p.product_category_name_display
),


complete_month_category_grid AS (

    SELECT
        m.month,
        tc.category,

        COALESCE(c.delivered_item_count, 0)
            AS delivered_item_count,

        COALESCE(c.delivered_orders, 0)
            AS delivered_orders,

        COALESCE(c.merchandise_value, 0)
            AS merchandise_value

    FROM months m

    CROSS JOIN top_categories tc

    LEFT JOIN category_monthly_base c
        ON m.month = c.month
       AND tc.category = c.category
),


with_month_totals AS (

    SELECT
        *,

        SUM(merchandise_value) OVER (
            PARTITION BY month
        ) AS top5_monthly_merchandise_value,

        LAG(merchandise_value) OVER (
            PARTITION BY category
            ORDER BY month
        ) AS previous_month_merchandise_value

    FROM complete_month_category_grid
)


SELECT
    month,
    category,

    delivered_item_count,
    delivered_orders,

    ROUND(
        merchandise_value,
        2
    ) AS merchandise_value,

    ROUND(
        merchandise_value
        /
        NULLIF(top5_monthly_merchandise_value, 0)
        * 100,
        2
    ) AS top5_value_share_pct,

    ROUND(
        merchandise_value
        - previous_month_merchandise_value,
        2
    ) AS merchandise_value_change,

    ROUND(
        (
            merchandise_value
            - previous_month_merchandise_value
        )
        /
        NULLIF(previous_month_merchandise_value, 0)
        * 100,
        2
    ) AS merchandise_mom_growth_pct

FROM with_month_totals

ORDER BY
    month,
    merchandise_value DESC;