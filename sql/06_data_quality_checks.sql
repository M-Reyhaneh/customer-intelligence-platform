-- ============================================================
-- Data Quality Contract
-- Returns one row per quality rule.
--
-- severity:
--   ERROR   = violates a rule required for reliable analytics
--   WARNING = suspicious but retained for investigation/use-case decisions
-- ============================================================

SELECT
    'orders_duplicate_order_id' AS check_name,
    'ERROR' AS severity,
    COUNT(*) - COUNT(DISTINCT order_id) AS failed_rows
FROM staging.orders

UNION ALL

SELECT
    'order_items_duplicate_grain',
    'ERROR',
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
FROM staging.order_items

UNION ALL

SELECT
    'orders_missing_customer',
    'ERROR',
    COUNT(*) FILTER (WHERE c.customer_id IS NULL)
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id

UNION ALL

SELECT
    'order_items_missing_order',
    'ERROR',
    COUNT(*) FILTER (WHERE o.order_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.orders o
    ON oi.order_id = o.order_id

UNION ALL

SELECT
    'order_items_missing_product',
    'ERROR',
    COUNT(*) FILTER (WHERE p.product_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id

UNION ALL

SELECT
    'order_items_missing_seller',
    'ERROR',
    COUNT(*) FILTER (WHERE s.seller_id IS NULL)
FROM staging.order_items oi
LEFT JOIN staging.sellers s
    ON oi.seller_id = s.seller_id

UNION ALL

SELECT
    'negative_item_price',
    'ERROR',
    COUNT(*) FILTER (WHERE price < 0)
FROM staging.order_items

UNION ALL

SELECT
    'negative_payment_value',
    'ERROR',
    COUNT(*) FILTER (WHERE payment_value < 0)
FROM staging.order_payments

UNION ALL

SELECT
    'invalid_review_score',
    'ERROR',
    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    )
FROM staging.order_reviews

UNION ALL

SELECT
    'delivered_before_purchase',
    'ERROR',
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
          AND order_delivered_customer_date < order_purchase_timestamp
    )
FROM staging.orders

UNION ALL

SELECT
    'customer_delivery_before_carrier',
    'WARNING',
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
          AND order_delivered_carrier_date IS NOT NULL
          AND order_delivered_customer_date < order_delivered_carrier_date
    )
FROM staging.orders

UNION ALL

SELECT
    'carrier_before_approval',
    'WARNING',
    COUNT(*) FILTER (
        WHERE order_approved_at IS NOT NULL
          AND order_delivered_carrier_date IS NOT NULL
          AND order_delivered_carrier_date < order_approved_at
    )
FROM staging.orders

UNION ALL

SELECT
    'delivered_missing_delivery_timestamp',
    'WARNING',
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NULL
    )
FROM staging.orders

UNION ALL

SELECT
    'zero_payment_value',
    'WARNING',
    COUNT(*) FILTER (
        WHERE payment_value = 0
    )
FROM staging.order_payments

UNION ALL

SELECT
    'zero_credit_card_installments',
    'WARNING',
    COUNT(*) FILTER (
        WHERE payment_type = 'credit_card'
          AND payment_installments = 0
    )
FROM staging.order_payments

ORDER BY severity, check_name;