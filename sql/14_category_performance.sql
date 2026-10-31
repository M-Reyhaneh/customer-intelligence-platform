-- ============================================================
-- Category Performance
--
-- Source grain:
-- analytics.fact_order_items = one row per order item
--
-- Population:
-- delivered orders only
--
-- Primary value metric:
-- merchandise value (product price only, freight excluded)
-- ============================================================


WITH category_metrics AS (

    SELECT
        p.product_category_name_display AS category,

        COUNT(*) AS delivered_item_count,

        COUNT(DISTINCT f.order_id) AS delivered_orders,

        SUM(f.price) AS merchandise_value,

        AVG(f.price) AS average_item_price

    FROM analytics.fact_order_items f

    JOIN analytics.dim_products p
        ON f.product_id = p.product_id

    WHERE f.order_status = 'delivered'

    GROUP BY
        p.product_category_name_display
),


category_with_share AS (

    SELECT
        *,

        merchandise_value
        /
        NULLIF(
            SUM(merchandise_value) OVER (),
            0
        )
        * 100
            AS merchandise_share_pct

    FROM category_metrics
)


SELECT
    category,

    delivered_item_count,

    delivered_orders,

    ROUND(
        merchandise_value,
        2
    ) AS merchandise_value,

    ROUND(
        average_item_price,
        2
    ) AS average_item_price,

    ROUND(
        merchandise_share_pct,
        2
    ) AS merchandise_share_pct,

    RANK() OVER (
        ORDER BY merchandise_value DESC
    ) AS merchandise_value_rank

FROM category_with_share

ORDER BY
    merchandise_value DESC;