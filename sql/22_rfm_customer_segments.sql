-- ============================================================
-- RFM Customer Segmentation
--
-- Customer identity:
-- customer_unique_id
--
-- Purchase definition:
-- delivered order
--
-- R = Recency
-- F = Frequency
-- M = Monetary
--
-- Important:
-- RFM segmentation is heuristic.
-- Segment labels are designed to describe observed behavior;
-- they are not intrinsic customer identities.
-- ============================================================


WITH analysis_snapshot AS (

    SELECT
        MAX(order_purchase_date) + 1
            AS analysis_date

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
),


customer_rfm AS (

    SELECT
        c.customer_unique_id,

        a.analysis_date
            - MAX(f.order_purchase_date)
            AS recency_days,

        COUNT(DISTINCT f.order_id)
            AS frequency,

        SUM(f.item_value)
            AS monetary_value

    FROM analytics.fact_orders f

    JOIN analytics.dim_customers c
        ON f.customer_id = c.customer_id

    CROSS JOIN analysis_snapshot a

    WHERE f.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id,
        a.analysis_date
),


scored AS (

    SELECT
        *,

        -- Lower recency is better.
        -- Most recent customers receive R = 5.

        6 - NTILE(5) OVER (
            ORDER BY recency_days
        ) AS r_score,


        -- 97% of customers have only one delivered order.
        -- Quantile scoring would artificially split identical
        -- frequency behavior into different scores.

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            ELSE 5
        END AS f_score,


        -- Higher monetary value is better.

        NTILE(5) OVER (
            ORDER BY monetary_value
        ) AS m_score

    FROM customer_rfm
),


segmented AS (

    SELECT
        *,

        CASE

            -- Recent + repeat + high monetary value.
            WHEN r_score >= 4
             AND f_score >= 3
             AND m_score >= 4
                THEN 'Champions'


            -- High historical value, but not recent.
            -- Restrict High Value to the top monetary quintile.
            WHEN r_score <= 2
             AND m_score = 5
                THEN 'High Value At Risk'


            -- Repeat purchasers with at least moderate value.
            -- We intentionally avoid the stronger "Loyal"
            -- label because most repeat customers have only
            -- two purchases in this dataset.
            WHEN f_score >= 3
             AND m_score >= 3
                THEN 'Repeat Customers'


            -- Recent customers who have made only one purchase.
            WHEN r_score >= 4
             AND f_score = 1
                THEN 'Recent New Customers'


            -- Old, one-time, low-value customers.
            WHEN r_score <= 2
             AND f_score = 1
             AND m_score <= 2
                THEN 'Inactive Low Value'


            ELSE 'Other'

        END AS customer_segment

    FROM scored
)


SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*)::numeric
        /
        SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_monetary_value,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_merchandise_value

FROM segmented

GROUP BY
    customer_segment

ORDER BY
    total_merchandise_value DESC;