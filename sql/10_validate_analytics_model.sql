-- ============================================================
-- Final analytics model validation
-- ============================================================


-- 1. fact_orders grain
SELECT
    'fact_orders_row_count' AS check_name,
    (SELECT COUNT(*) FROM staging.orders) AS expected,
    (SELECT COUNT(*) FROM analytics.fact_orders) AS actual

UNION ALL

SELECT
    'fact_orders_unique_grain',
    (SELECT COUNT(*) FROM staging.orders),
    (
        SELECT COUNT(DISTINCT order_id)
        FROM analytics.fact_orders
    )

UNION ALL

-- 2. fact_order_items grain
SELECT
    'fact_order_items_row_count',
    (SELECT COUNT(*) FROM staging.order_items),
    (SELECT COUNT(*) FROM analytics.fact_order_items)

UNION ALL

SELECT
    'fact_order_items_unique_grain',
    (SELECT COUNT(*) FROM staging.order_items),
    (
        SELECT COUNT(DISTINCT (order_id, order_item_id))
        FROM analytics.fact_order_items
    )

UNION ALL

-- 3. Item aggregation reconciliation
SELECT
    'fact_orders_total_item_count',
    (SELECT COUNT(*) FROM staging.order_items),
    (
        SELECT SUM(item_count)
        FROM analytics.fact_orders
    )

UNION ALL

-- 4. Payment aggregation reconciliation
SELECT
    'fact_orders_payment_record_count',
    (SELECT COUNT(*) FROM staging.order_payments),
    (
        SELECT SUM(payment_record_count)
        FROM analytics.fact_orders
    )

ORDER BY check_name;


-- ============================================================
-- Monetary reconciliation
-- ============================================================

SELECT
    'staging_order_items' AS source,
    SUM(price) AS item_value,
    SUM(freight_value) AS freight_value
FROM staging.order_items

UNION ALL

SELECT
    'fact_order_items',
    SUM(price),
    SUM(freight_value)
FROM analytics.fact_order_items

UNION ALL

SELECT
    'fact_orders',
    SUM(item_value),
    SUM(freight_value)
FROM analytics.fact_orders;


-- ============================================================
-- Dimension/source row counts
-- ============================================================

SELECT
    'customers' AS dimension,
    (SELECT COUNT(*) FROM staging.customers) AS staging_rows,
    (SELECT COUNT(*) FROM analytics.dim_customers) AS dimension_rows

UNION ALL

SELECT
    'products',
    (SELECT COUNT(*) FROM staging.products),
    (SELECT COUNT(*) FROM analytics.dim_products)

UNION ALL

SELECT
    'sellers',
    (SELECT COUNT(*) FROM staging.sellers),
    (SELECT COUNT(*) FROM analytics.dim_sellers);