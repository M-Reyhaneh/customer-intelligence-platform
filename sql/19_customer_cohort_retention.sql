-- ============================================================
-- Customer Cohort Retention
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- Cohort:
-- month of customer's first delivered purchase
--
-- Retention:
-- percentage of the original cohort that makes another
-- delivered purchase N months after first purchase
--
-- Comparable cohort window:
-- Feb 2017 through Feb 2018
--
-- Why stop at Feb 2018?
-- Dataset has reliable activity through Aug 2018,
-- so each selected cohort has at least six months
-- of follow-up opportunity.
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
            EXTRACT(YEAR FROM AGE(
                d.activity_month,
                fp.cohort_month
            )) * 12

            +

            EXTRACT(MONTH FROM AGE(
                d.activity_month,
                fp.cohort_month
            ))
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
)


SELECT
    ca.cohort_month,
    ca.months_since_first_purchase,

    cs.cohort_size,

    ca.active_customers,

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

ORDER BY
    ca.cohort_month,
    ca.months_since_first_purchase;