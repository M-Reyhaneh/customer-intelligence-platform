-- ============================================================
-- Order fact
-- Grain: one row per order_id
-- ============================================================

CREATE TABLE analytics.fact_orders AS

WITH item_summary AS (

    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT product_id) AS distinct_product_count,
        COUNT(DISTINCT seller_id) AS distinct_seller_count,
        SUM(price) AS item_value,
        SUM(freight_value) AS freight_value,
        SUM(price + freight_value) AS item_plus_freight_value

    FROM staging.order_items

    GROUP BY order_id
),

payment_summary AS (

    SELECT
        order_id,
        COUNT(*) AS payment_record_count,
        SUM(payment_value) AS payment_value

    FROM staging.order_payments

    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,

    o.order_purchase_timestamp::date AS order_purchase_date,

    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.distinct_product_count, 0) AS distinct_product_count,
    COALESCE(i.distinct_seller_count, 0) AS distinct_seller_count,

    COALESCE(i.item_value, 0) AS item_value,
    COALESCE(i.freight_value, 0) AS freight_value,
    COALESCE(i.item_plus_freight_value, 0) AS item_plus_freight_value,

    COALESCE(p.payment_record_count, 0) AS payment_record_count,
    COALESCE(p.payment_value, 0) AS payment_value

FROM staging.orders o

LEFT JOIN item_summary i
    ON o.order_id = i.order_id

LEFT JOIN payment_summary p
    ON o.order_id = p.order_id;


ALTER TABLE analytics.fact_orders
    ADD PRIMARY KEY (order_id);


ALTER TABLE analytics.fact_orders
    ADD CONSTRAINT fk_fact_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES analytics.dim_customers (customer_id);


ALTER TABLE analytics.fact_orders
    ADD CONSTRAINT fk_fact_orders_purchase_date
    FOREIGN KEY (order_purchase_date)
    REFERENCES analytics.dim_date (date_day);