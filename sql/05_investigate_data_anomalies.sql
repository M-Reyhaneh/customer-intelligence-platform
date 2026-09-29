-- ============================================================
-- Investigation of unusual domain / timestamp observations
-- No data is modified here.
-- ============================================================


-- 1. Zero-value payments
SELECT
    payment_type,
    payment_installments,
    COUNT(*) AS row_count,
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment
FROM staging.order_payments
WHERE payment_value = 0
GROUP BY
    payment_type,
    payment_installments
ORDER BY row_count DESC;


-- 2. Zero-installment payments
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM staging.order_payments
WHERE payment_installments = 0
ORDER BY order_id;


-- 3. Zero freight: inspect whether it looks systematic
SELECT
    o.order_status,
    COUNT(*) AS row_count
FROM staging.order_items oi
JOIN staging.orders o
    ON oi.order_id = o.order_id
WHERE oi.freight_value = 0
GROUP BY o.order_status
ORDER BY row_count DESC;


-- 4. Orders sent to carrier before approval
SELECT
    order_status,
    COUNT(*) AS row_count,
    MIN(order_approved_at - order_delivered_carrier_date) AS smallest_difference,
    MAX(order_approved_at - order_delivered_carrier_date) AS largest_difference
FROM staging.orders
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at
GROUP BY order_status
ORDER BY row_count DESC;


-- Sample examples
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_approved_at - order_delivered_carrier_date AS approval_after_carrier_by
FROM staging.orders
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at
ORDER BY approval_after_carrier_by DESC
LIMIT 10;


-- 5. Customer delivery timestamp before carrier timestamp
SELECT
    order_status,
    COUNT(*) AS row_count,
    MIN(order_delivered_carrier_date - order_delivered_customer_date)
        AS smallest_difference,
    MAX(order_delivered_carrier_date - order_delivered_customer_date)
        AS largest_difference
FROM staging.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date
GROUP BY order_status
ORDER BY row_count DESC;


-- Sample examples
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_delivered_carrier_date - order_delivered_customer_date
        AS carrier_after_customer_by
FROM staging.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date
ORDER BY carrier_after_customer_by DESC
LIMIT 10;


-- 6. Missing timestamp patterns by order status
SELECT
    order_status,
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL)
        AS missing_approval,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL)
        AS missing_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
        AS missing_customer_delivery
FROM staging.orders
GROUP BY order_status
ORDER BY orders DESC;