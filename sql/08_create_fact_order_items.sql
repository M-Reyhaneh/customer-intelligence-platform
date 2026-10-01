-- ============================================================
-- Order item fact
-- Grain: one row per (order_id, order_item_id)
-- ============================================================

CREATE TABLE analytics.fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,

    o.customer_id,
    oi.product_id,
    oi.seller_id,

    o.order_purchase_timestamp::date AS order_purchase_date,
    o.order_purchase_timestamp,
    o.order_status,

    oi.shipping_limit_date,

    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS item_total_value

FROM staging.order_items oi
JOIN staging.orders o
    ON oi.order_id = o.order_id;


ALTER TABLE analytics.fact_order_items
    ADD PRIMARY KEY (order_id, order_item_id);


ALTER TABLE analytics.fact_order_items
    ADD CONSTRAINT fk_fact_order_items_customer
    FOREIGN KEY (customer_id)
    REFERENCES analytics.dim_customers (customer_id);


ALTER TABLE analytics.fact_order_items
    ADD CONSTRAINT fk_fact_order_items_product
    FOREIGN KEY (product_id)
    REFERENCES analytics.dim_products (product_id);


ALTER TABLE analytics.fact_order_items
    ADD CONSTRAINT fk_fact_order_items_seller
    FOREIGN KEY (seller_id)
    REFERENCES analytics.dim_sellers (seller_id);


ALTER TABLE analytics.fact_order_items
    ADD CONSTRAINT fk_fact_order_items_purchase_date
    FOREIGN KEY (order_purchase_date)
    REFERENCES analytics.dim_date (date_day);