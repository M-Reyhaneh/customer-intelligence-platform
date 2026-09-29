-- ============================================================
-- Domain and business-rule profiling
-- ============================================================


-- 1. Monetary values

SELECT
    'order_items.price' AS field_name,
    MIN(price) AS min_value,
    MAX(price) AS max_value,
    COUNT(*) FILTER (WHERE price < 0) AS negative_count,
    COUNT(*) FILTER (WHERE price = 0) AS zero_count
FROM staging.order_items

UNION ALL

SELECT
    'order_items.freight_value',
    MIN(freight_value),
    MAX(freight_value),
    COUNT(*) FILTER (WHERE freight_value < 0),
    COUNT(*) FILTER (WHERE freight_value = 0)
FROM staging.order_items

UNION ALL

SELECT
    'order_payments.payment_value',
    MIN(payment_value),
    MAX(payment_value),
    COUNT(*) FILTER (WHERE payment_value < 0),
    COUNT(*) FILTER (WHERE payment_value = 0)
FROM staging.order_payments;


-- 2. Review score domain

SELECT
    review_score,
    COUNT(*) AS row_count
FROM staging.order_reviews
GROUP BY review_score
ORDER BY review_score;


-- 3. Payment installments

SELECT
    payment_installments,
    COUNT(*) AS row_count
FROM staging.order_payments
GROUP BY payment_installments
ORDER BY payment_installments;


-- 4. Order status domain

SELECT
    order_status,
    COUNT(*) AS row_count
FROM staging.orders
GROUP BY order_status
ORDER BY row_count DESC;


-- 5. Timestamp consistency

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NOT NULL
          AND order_approved_at < order_purchase_timestamp
    ) AS approved_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NOT NULL
          AND order_approved_at IS NOT NULL
          AND order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
          AND order_delivered_carrier_date IS NOT NULL
          AND order_delivered_customer_date < order_delivered_carrier_date
    ) AS customer_before_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
          AND order_delivered_customer_date < order_purchase_timestamp
    ) AS delivered_before_purchase

FROM staging.orders;