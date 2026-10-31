-- ============================================================
-- Customer Identity Profile
--
-- Goal:
-- understand the difference between:
--   customer_id
--   customer_unique_id
--
-- This is required before repeat purchase,
-- retention, cohorts, and RFM analysis.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Overall identity counts
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT f.customer_id)
        AS distinct_customer_ids,

    COUNT(DISTINCT c.customer_unique_id)
        AS distinct_unique_customers

FROM analytics.fact_orders f

JOIN analytics.dim_customers c
    ON f.customer_id = c.customer_id;



-- ------------------------------------------------------------
-- 2. Check whether one customer_id appears in multiple orders
-- ------------------------------------------------------------

SELECT
    customer_id,
    COUNT(*) AS order_count

FROM analytics.fact_orders

GROUP BY
    customer_id

HAVING COUNT(*) > 1

ORDER BY
    order_count DESC

LIMIT 20;



-- ------------------------------------------------------------
-- 3. Count orders per persistent customer identity
-- ------------------------------------------------------------

WITH customer_order_counts AS (

    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    GROUP BY
        c.customer_unique_id
)


SELECT
    COUNT(*) AS unique_customers,

    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_count > 1
        )::numeric
        /
        NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS repeat_customer_rate_pct,

    MAX(order_count)
        AS max_orders_per_customer

FROM customer_order_counts;



-- ------------------------------------------------------------
-- 4. Distribution of order frequency
-- ------------------------------------------------------------

WITH customer_order_counts AS (

    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    GROUP BY
        c.customer_unique_id
)


SELECT
    order_count,
    COUNT(*) AS customer_count

FROM customer_order_counts

GROUP BY
    order_count

ORDER BY
    order_count;