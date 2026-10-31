-- ============================================================
-- Customer Cohort Retention Matrix
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- Cohort:
-- month of first delivered purchase
--
-- Output grain:
-- one row per cohort
--
-- M0 = acquisition month
-- M1 = one month after first purchase
-- ...
-- M6 = six months after first purchase
-- ============================================================


WITH delivered_orders AS (

    SELECT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            f.order_purchase_date
        )::date AS activity_month

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'
),


first_purchase AS (

    SELECT
        customer_unique_id,
        MIN(activity_month) AS cohort_month

    FROM delivered_orders

    GROUP BY
        customer_unique_id
),


customer_month_activity AS (

    SELECT DISTINCT
        d.customer_unique_id,
        fp.cohort_month,
        d.activity_month,

        (
            EXTRACT(
                YEAR FROM AGE(
                    d.activity_month,
                    fp.cohort_month
                )
            ) * 12

            +

            EXTRACT(
                MONTH FROM AGE(
                    d.activity_month,
                    fp.cohort_month
                )
            )
        )::integer AS months_since_first_purchase

    FROM delivered_orders d

    JOIN first_purchase fp
        ON d.customer_unique_id = fp.customer_unique_id
),


cohort_activity AS (

    SELECT
        cohort_month,
        months_since_first_purchase,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers

    FROM customer_month_activity

    WHERE cohort_month >= DATE '2017-02-01'
      AND cohort_month <= DATE '2018-02-01'
      AND months_since_first_purchase BETWEEN 0 AND 6

    GROUP BY
        cohort_month,
        months_since_first_purchase
),


cohort_sizes AS (

    SELECT
        cohort_month,
        active_customers AS cohort_size

    FROM cohort_activity

    WHERE months_since_first_purchase = 0
),


retention AS (

    SELECT
        ca.cohort_month,
        ca.months_since_first_purchase,

        ROUND(
            ca.active_customers::numeric
            /
            NULLIF(cs.cohort_size, 0)
            * 100,
            2
        ) AS retention_rate_pct

    FROM cohort_activity ca

    JOIN cohort_sizes cs
        ON ca.cohort_month = cs.cohort_month
)


SELECT
    cohort_month,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 0
    ) AS m0_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 1
    ) AS m1_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 2
    ) AS m2_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 3
    ) AS m3_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 4
    ) AS m4_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 5
    ) AS m5_retention_pct,

    MAX(retention_rate_pct) FILTER (
        WHERE months_since_first_purchase = 6
    ) AS m6_retention_pct

FROM retention

GROUP BY
    cohort_month

ORDER BY
    cohort_month;