-- 01_basic_kpis.sql
-- Basic KPI queries for the Customer Intelligence Platform

-- 1. Dataset validation
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customer_orders;


-- 2. Core business KPIs
SELECT
    ROUND(SUM(product_revenue), 2) AS total_product_revenue,
    ROUND(SUM(shipping_revenue), 2) AS customer_paid_freight_charges,
    ROUND(SUM(total_order_value), 2) AS total_order_value,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(SUM(product_revenue) / COUNT(DISTINCT order_id), 2) AS average_product_revenue_per_order
FROM customer_orders;


-- 3. Order status distribution
SELECT
    order_status,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT order_id) / (
        SELECT COUNT(DISTINCT order_id) FROM customer_orders
    ), 2) AS order_percent
FROM customer_orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 4. Revenue by customer state
SELECT
    customer_state,
    ROUND(SUM(product_revenue), 2) AS product_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(product_revenue) / COUNT(DISTINCT order_id), 2) AS avg_product_revenue_per_order
FROM customer_orders
WHERE customer_state IS NOT NULL
GROUP BY customer_state
ORDER BY product_revenue DESC;


-- 5. Monthly product revenue trend
SELECT
    STRFTIME('%Y-%m', order_purchase_timestamp) AS order_month,
    ROUND(SUM(COALESCE(product_revenue, 0)), 2) AS product_revenue,
    ROUND(SUM(COALESCE(total_order_value, 0)), 2) AS total_order_value,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(COALESCE(product_revenue, 0)) / COUNT(DISTINCT order_id), 2) AS avg_product_revenue_per_order
FROM customer_orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
HAVING order_month BETWEEN '2017-01' AND '2018-08'
ORDER BY order_month;