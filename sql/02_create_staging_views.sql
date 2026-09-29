CREATE SCHEMA IF NOT EXISTS staging
AUTHORIZATION ecommerce_di_app;


CREATE OR REPLACE VIEW staging.customers AS
SELECT
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(customer_unique_id), '') AS customer_unique_id,
    NULLIF(BTRIM(customer_zip_code_prefix), '') AS customer_zip_code_prefix,
    NULLIF(BTRIM(customer_city), '') AS customer_city,
    NULLIF(BTRIM(customer_state), '') AS customer_state
FROM raw.customers;


CREATE OR REPLACE VIEW staging.geolocation AS
SELECT
    NULLIF(BTRIM(geolocation_zip_code_prefix), '') AS geolocation_zip_code_prefix,
    NULLIF(BTRIM(geolocation_lat), '')::numeric AS geolocation_lat,
    NULLIF(BTRIM(geolocation_lng), '')::numeric AS geolocation_lng,
    NULLIF(BTRIM(geolocation_city), '') AS geolocation_city,
    NULLIF(BTRIM(geolocation_state), '') AS geolocation_state
FROM raw.geolocation;


CREATE OR REPLACE VIEW staging.order_items AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(order_item_id), '')::integer AS order_item_id,
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(shipping_limit_date), '')::timestamp AS shipping_limit_date,
    NULLIF(BTRIM(price), '')::numeric AS price,
    NULLIF(BTRIM(freight_value), '')::numeric AS freight_value
FROM raw.order_items;


CREATE OR REPLACE VIEW staging.order_payments AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(payment_sequential), '')::integer AS payment_sequential,
    NULLIF(BTRIM(payment_type), '') AS payment_type,
    NULLIF(BTRIM(payment_installments), '')::integer AS payment_installments,
    NULLIF(BTRIM(payment_value), '')::numeric AS payment_value
FROM raw.order_payments;


CREATE OR REPLACE VIEW staging.order_reviews AS
SELECT
    NULLIF(BTRIM(review_id), '') AS review_id,
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(review_score), '')::smallint AS review_score,
    NULLIF(BTRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(BTRIM(review_comment_message), '') AS review_comment_message,
    NULLIF(BTRIM(review_creation_date), '')::timestamp AS review_creation_date,
    NULLIF(BTRIM(review_answer_timestamp), '')::timestamp AS review_answer_timestamp
FROM raw.order_reviews;


CREATE OR REPLACE VIEW staging.orders AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(order_status), '') AS order_status,
    NULLIF(BTRIM(order_purchase_timestamp), '')::timestamp AS order_purchase_timestamp,
    NULLIF(BTRIM(order_approved_at), '')::timestamp AS order_approved_at,
    NULLIF(BTRIM(order_delivered_carrier_date), '')::timestamp AS order_delivered_carrier_date,
    NULLIF(BTRIM(order_delivered_customer_date), '')::timestamp AS order_delivered_customer_date,
    NULLIF(BTRIM(order_estimated_delivery_date), '')::timestamp AS order_estimated_delivery_date
FROM raw.orders;


CREATE OR REPLACE VIEW staging.products AS
SELECT
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(product_category_name), '') AS product_category_name,

    NULLIF(BTRIM(product_name_lenght), '')::integer
        AS product_name_length,

    NULLIF(BTRIM(product_description_lenght), '')::integer
        AS product_description_length,

    NULLIF(BTRIM(product_photos_qty), '')::integer
        AS product_photos_qty,

    NULLIF(BTRIM(product_weight_g), '')::numeric
        AS product_weight_g,

    NULLIF(BTRIM(product_length_cm), '')::numeric
        AS product_length_cm,

    NULLIF(BTRIM(product_height_cm), '')::numeric
        AS product_height_cm,

    NULLIF(BTRIM(product_width_cm), '')::numeric
        AS product_width_cm

FROM raw.products;


CREATE OR REPLACE VIEW staging.sellers AS
SELECT
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(seller_zip_code_prefix), '') AS seller_zip_code_prefix,
    NULLIF(BTRIM(seller_city), '') AS seller_city,
    NULLIF(BTRIM(seller_state), '') AS seller_state
FROM raw.sellers;


CREATE OR REPLACE VIEW staging.product_category_name_translation AS
SELECT
    NULLIF(BTRIM(product_category_name), '') AS product_category_name,
    NULLIF(BTRIM(product_category_name_english), '') AS product_category_name_english
FROM raw.product_category_name_translation;