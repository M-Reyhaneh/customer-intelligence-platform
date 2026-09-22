-- 02_customer_behavior.sql
-- Customer behavior queries for repeat purchase and customer value analysis

-- 1. Orders per customer
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(COALESCE(product_revenue, 0)), 2) AS total_product_revenue,
    ROUND(SUM(COALESCE(product_revenue, 0)) / COUNT(DISTINCT order_id), 2) AS avg_product_revenue_per_order
FROM customer_orders
WHERE customer_unique_id IS NOT NULL
GROUP BY customer_unique_id
ORDER BY total_product_revenue DESC;


-- 2. One-time vs repeat customers
WITH customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM customer_orders
    WHERE customer_unique_id IS NOT NULL
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (
        SELECT COUNT(*) FROM customer_order_counts
    ), 2) AS customer_percent
FROM customer_order_counts
GROUP BY customer_type
ORDER BY customer_count DESC;


-- 3. Top customers by product revenue
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(COALESCE(product_revenue, 0)), 2) AS total_product_revenue,
    ROUND(AVG(COALESCE(product_revenue, 0)), 2) AS avg_product_revenue_per_order,
    MAX(order_purchase_timestamp) AS last_order_date
FROM customer_orders
WHERE customer_unique_id IS NOT NULL
GROUP BY customer_unique_id
ORDER BY total_product_revenue DESC
LIMIT 20;


-- 4. Delivery delay by customer state
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(delivery_delay), 2) AS avg_delivery_delay,
    ROUND(100.0 * AVG(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END), 2) AS late_delivery_rate_percent
FROM customer_orders
WHERE order_status = 'delivered'
  AND customer_state IS NOT NULL
GROUP BY customer_state
HAVING delivered_orders >= 100
ORDER BY avg_delivery_delay DESC;