-- ============================================================
-- Referential integrity / orphan checks
-- ============================================================

SELECT
    'orders.customer_id -> customers.customer_id' AS relationship,
    COUNT(*) AS child_rows,
    COUNT(*) FILTER (WHERE c.customer_id IS NULL) AS orphan_rows
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id

UNION ALL

SELECT
    'order_items.order_id -> orders.order_id',
    COUNT(*),
    COUNT(*) FILTER (WHERE o.order_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.orders o
    ON oi.order_id = o.order_id

UNION ALL

SELECT
    'order_items.product_id -> products.product_id',
    COUNT(*),
    COUNT(*) FILTER (WHERE p.product_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id

UNION ALL

SELECT
    'order_items.seller_id -> sellers.seller_id',
    COUNT(*),
    COUNT(*) FILTER (WHERE s.seller_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.sellers s
    ON oi.seller_id = s.seller_id

UNION ALL

SELECT
    'order_payments.order_id -> orders.order_id',
    COUNT(*),
    COUNT(*) FILTER (WHERE o.order_id IS NULL)
FROM staging.order_payments op
LEFT JOIN staging.orders o
    ON op.order_id = o.order_id

UNION ALL

SELECT
    'order_reviews.order_id -> orders.order_id',
    COUNT(*),
    COUNT(*) FILTER (WHERE o.order_id IS NULL)
FROM staging.order_reviews r
LEFT JOIN staging.orders o
    ON r.order_id = o.order_id

UNION ALL

SELECT
    'products.category -> category_translation',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND t.product_category_name IS NULL
    )
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
    ON p.product_category_name = t.product_category_name

ORDER BY relationship;