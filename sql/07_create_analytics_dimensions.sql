-- ============================================================
-- Analytics dimensions
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics
AUTHORIZATION ecommerce_di_app;


-- ------------------------------------------------------------
-- Customer dimension
-- Grain: one row per customer_id
-- ------------------------------------------------------------

CREATE TABLE analytics.dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;

ALTER TABLE analytics.dim_customers
    ADD PRIMARY KEY (customer_id);


-- ------------------------------------------------------------
-- Product dimension
-- Grain: one row per product_id
-- ------------------------------------------------------------

CREATE TABLE analytics.dim_products AS
SELECT
    p.product_id,

    p.product_category_name
        AS product_category_name_original,

    t.product_category_name_english,

    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category_name_display,

    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

ALTER TABLE analytics.dim_products
    ADD PRIMARY KEY (product_id);


-- ------------------------------------------------------------
-- Seller dimension
-- Grain: one row per seller_id
-- ------------------------------------------------------------

CREATE TABLE analytics.dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;

ALTER TABLE analytics.dim_sellers
    ADD PRIMARY KEY (seller_id);


-- ------------------------------------------------------------
-- Date dimension
-- Grain: one row per calendar date
-- ------------------------------------------------------------

CREATE TABLE analytics.dim_date AS

WITH all_order_dates AS (

    SELECT order_purchase_timestamp::date AS date_value
    FROM staging.orders

    UNION ALL

    SELECT order_approved_at::date
    FROM staging.orders
    WHERE order_approved_at IS NOT NULL

    UNION ALL

    SELECT order_delivered_carrier_date::date
    FROM staging.orders
    WHERE order_delivered_carrier_date IS NOT NULL

    UNION ALL

    SELECT order_delivered_customer_date::date
    FROM staging.orders
    WHERE order_delivered_customer_date IS NOT NULL

    UNION ALL

    SELECT order_estimated_delivery_date::date
    FROM staging.orders

),

date_bounds AS (
    SELECT
        MIN(date_value) AS min_date,
        MAX(date_value) AS max_date
    FROM all_order_dates
)

SELECT
    d::date AS date_day,
    EXTRACT(YEAR FROM d)::smallint AS year,
    EXTRACT(QUARTER FROM d)::smallint AS quarter,
    EXTRACT(MONTH FROM d)::smallint AS month,
    TO_CHAR(d, 'FMMonth') AS month_name,
    EXTRACT(WEEK FROM d)::smallint AS week_of_year,
    EXTRACT(DAY FROM d)::smallint AS day_of_month,
    EXTRACT(ISODOW FROM d)::smallint AS day_of_week,
    TO_CHAR(d, 'FMDay') AS day_name,
    EXTRACT(ISODOW FROM d) IN (6, 7) AS is_weekend

FROM date_bounds
CROSS JOIN LATERAL generate_series(
    min_date,
    max_date,
    INTERVAL '1 day'
) AS d;

ALTER TABLE analytics.dim_date
    ADD PRIMARY KEY (date_day);