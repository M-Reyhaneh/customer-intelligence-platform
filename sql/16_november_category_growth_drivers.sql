-- ============================================================
-- November 2017 Category Growth Drivers
--
-- Question:
-- Which product categories contributed most to the increase
-- in delivered merchandise value from October to November 2017?
--
-- Population:
-- delivered order items only
-- ============================================================


WITH category_monthly AS (

    SELECT
        DATE_TRUNC(
            'month',
            f.order_purchase_date
        )::date AS month,

        p.product_category_name_display AS category,

        SUM(f.price) AS merchandise_value

    FROM analytics.fact_order_items f

    JOIN analytics.dim_products p
        ON f.product_id = p.product_id

    WHERE f.order_status = 'delivered'
      AND f.order_purchase_date >= DATE '2017-10-01'
      AND f.order_purchase_date <  DATE '2017-12-01'

    GROUP BY
        DATE_TRUNC('month', f.order_purchase_date)::date,
        p.product_category_name_display
),


categories AS (

    SELECT DISTINCT category
    FROM category_monthly
),


category_comparison AS (

    SELECT
        c.category,

        COALESCE(oct.merchandise_value, 0)
            AS october_value,

        COALESCE(nov.merchandise_value, 0)
            AS november_value

    FROM categories c

    LEFT JOIN category_monthly oct
        ON c.category = oct.category
       AND oct.month = DATE '2017-10-01'

    LEFT JOIN category_monthly nov
        ON c.category = nov.category
       AND nov.month = DATE '2017-11-01'
),


with_changes AS (

    SELECT
        category,

        october_value,
        november_value,

        november_value - october_value
            AS merchandise_value_change

    FROM category_comparison
),


with_total_change AS (

    SELECT
        *,

        SUM(merchandise_value_change) OVER ()
            AS total_merchandise_value_change

    FROM with_changes
)


SELECT
    category,

    ROUND(
        october_value,
        2
    ) AS october_value,

    ROUND(
        november_value,
        2
    ) AS november_value,

    ROUND(
        merchandise_value_change,
        2
    ) AS merchandise_value_change,

    ROUND(
        merchandise_value_change
        /
        NULLIF(total_merchandise_value_change, 0)
        * 100,
        2
    ) AS contribution_to_total_growth_pct

FROM with_total_change

ORDER BY
    merchandise_value_change DESC;