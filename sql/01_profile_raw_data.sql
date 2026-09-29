-- ============================================================
-- 1. CASTABILITY CHECKS
-- Checks whether non-empty TEXT values can safely be converted
-- to the intended staging data types.
-- ============================================================

SELECT
    'orders.order_purchase_timestamp' AS field_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_purchase_timestamp), '') IS NULL
    ) AS null_or_blank,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_purchase_timestamp), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              order_purchase_timestamp,
              'timestamp without time zone'
          )
    ) AS invalid_values
FROM raw.orders

UNION ALL

SELECT
    'orders.order_approved_at',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_approved_at), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_approved_at), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              order_approved_at,
              'timestamp without time zone'
          )
    )
FROM raw.orders

UNION ALL

SELECT
    'orders.order_delivered_carrier_date',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_delivered_carrier_date), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_delivered_carrier_date), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              order_delivered_carrier_date,
              'timestamp without time zone'
          )
    )
FROM raw.orders

UNION ALL

SELECT
    'orders.order_delivered_customer_date',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_delivered_customer_date), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_delivered_customer_date), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              order_delivered_customer_date,
              'timestamp without time zone'
          )
    )
FROM raw.orders

UNION ALL

SELECT
    'orders.order_estimated_delivery_date',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_estimated_delivery_date), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_estimated_delivery_date), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              order_estimated_delivery_date,
              'timestamp without time zone'
          )
    )
FROM raw.orders

UNION ALL

SELECT
    'order_items.order_item_id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_item_id), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(order_item_id), '') IS NOT NULL
          AND NOT pg_input_is_valid(order_item_id, 'integer')
    )
FROM raw.order_items

UNION ALL

SELECT
    'order_items.shipping_limit_date',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(shipping_limit_date), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(shipping_limit_date), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              shipping_limit_date,
              'timestamp without time zone'
          )
    )
FROM raw.order_items

UNION ALL

SELECT
    'order_items.price',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(price), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(price), '') IS NOT NULL
          AND NOT pg_input_is_valid(price, 'numeric')
    )
FROM raw.order_items

UNION ALL

SELECT
    'order_items.freight_value',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(freight_value), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(freight_value), '') IS NOT NULL
          AND NOT pg_input_is_valid(freight_value, 'numeric')
    )
FROM raw.order_items

UNION ALL

SELECT
    'order_payments.payment_sequential',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_sequential), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_sequential), '') IS NOT NULL
          AND NOT pg_input_is_valid(payment_sequential, 'integer')
    )
FROM raw.order_payments

UNION ALL

SELECT
    'order_payments.payment_installments',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_installments), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_installments), '') IS NOT NULL
          AND NOT pg_input_is_valid(payment_installments, 'integer')
    )
FROM raw.order_payments

UNION ALL

SELECT
    'order_payments.payment_value',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_value), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payment_value), '') IS NOT NULL
          AND NOT pg_input_is_valid(payment_value, 'numeric')
    )
FROM raw.order_payments

UNION ALL

SELECT
    'order_reviews.review_score',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_score), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_score), '') IS NOT NULL
          AND NOT pg_input_is_valid(review_score, 'smallint')
    )
FROM raw.order_reviews

UNION ALL

SELECT
    'geolocation.geolocation_lat',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(geolocation_lat), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(geolocation_lat), '') IS NOT NULL
          AND NOT pg_input_is_valid(geolocation_lat, 'numeric')
    )
FROM raw.geolocation

UNION ALL

SELECT
    'geolocation.geolocation_lng',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(geolocation_lng), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(geolocation_lng), '') IS NOT NULL
          AND NOT pg_input_is_valid(geolocation_lng, 'numeric')
    )
FROM raw.geolocation

ORDER BY field_name;


-- ============================================================
-- 2. CANDIDATE KEY CHECKS
-- ============================================================

SELECT
    'orders.order_id' AS candidate_key,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE order_id IS NULL OR BTRIM(order_id) = ''
    ) AS null_key_rows,
    COUNT(DISTINCT order_id) AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_key_rows
FROM raw.orders

UNION ALL

SELECT
    'customers.customer_id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE customer_id IS NULL OR BTRIM(customer_id) = ''
    ),
    COUNT(DISTINCT customer_id),
    COUNT(*) - COUNT(DISTINCT customer_id)
FROM raw.customers

UNION ALL

SELECT
    'products.product_id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE product_id IS NULL OR BTRIM(product_id) = ''
    ),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM raw.products

UNION ALL

SELECT
    'sellers.seller_id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE seller_id IS NULL OR BTRIM(seller_id) = ''
    ),
    COUNT(DISTINCT seller_id),
    COUNT(*) - COUNT(DISTINCT seller_id)
FROM raw.sellers

UNION ALL

SELECT
    'order_items.(order_id, order_item_id)',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR order_item_id IS NULL
           OR BTRIM(order_id) = ''
           OR BTRIM(order_item_id) = ''
    ),
    COUNT(DISTINCT (order_id, order_item_id)),
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
FROM raw.order_items

UNION ALL

SELECT
    'order_payments.(order_id, payment_sequential)',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR payment_sequential IS NULL
           OR BTRIM(order_id) = ''
           OR BTRIM(payment_sequential) = ''
    ),
    COUNT(DISTINCT (order_id, payment_sequential)),
    COUNT(*) - COUNT(DISTINCT (order_id, payment_sequential))
FROM raw.order_payments

UNION ALL

SELECT
    'category_translation.product_category_name',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR BTRIM(product_category_name) = ''
    ),
    COUNT(DISTINCT product_category_name),
    COUNT(*) - COUNT(DISTINCT product_category_name)
FROM raw.product_category_name_translation

UNION ALL

SELECT
    'reviews.review_id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE review_id IS NULL OR BTRIM(review_id) = ''
    ),
    COUNT(DISTINCT review_id),
    COUNT(*) - COUNT(DISTINCT review_id)
FROM raw.order_reviews

UNION ALL

SELECT
    'reviews.(review_id, order_id)',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE review_id IS NULL
           OR order_id IS NULL
           OR BTRIM(review_id) = ''
           OR BTRIM(order_id) = ''
    ),
    COUNT(DISTINCT (review_id, order_id)),
    COUNT(*) - COUNT(DISTINCT (review_id, order_id))
FROM raw.order_reviews

ORDER BY candidate_key;

SELECT
    'products.product_name_lenght' AS field_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_name_lenght), '') IS NULL
    ) AS null_or_blank,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_name_lenght), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_name_lenght, 'integer')
    ) AS invalid_values
FROM raw.products

UNION ALL

SELECT
    'products.product_description_lenght',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_description_lenght), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_description_lenght), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_description_lenght, 'integer')
    )
FROM raw.products

UNION ALL

SELECT
    'products.product_photos_qty',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_photos_qty), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_photos_qty), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_photos_qty, 'integer')
    )
FROM raw.products

UNION ALL

SELECT
    'products.product_weight_g',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_weight_g), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_weight_g), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_weight_g, 'numeric')
    )
FROM raw.products

UNION ALL

SELECT
    'products.product_length_cm',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_length_cm), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_length_cm), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_length_cm, 'numeric')
    )
FROM raw.products

UNION ALL

SELECT
    'products.product_height_cm',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_height_cm), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_height_cm), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_height_cm, 'numeric')
    )
FROM raw.products

UNION ALL

SELECT
    'products.product_width_cm',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_width_cm), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_width_cm), '') IS NOT NULL
          AND NOT pg_input_is_valid(product_width_cm, 'numeric')
    )
FROM raw.products

UNION ALL

SELECT
    'order_reviews.review_creation_date',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_creation_date), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_creation_date), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              review_creation_date,
              'timestamp without time zone'
          )
    )
FROM raw.order_reviews

UNION ALL

SELECT
    'order_reviews.review_answer_timestamp',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_answer_timestamp), '') IS NULL
    ),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_answer_timestamp), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              review_answer_timestamp,
              'timestamp without time zone'
          )
    )
FROM raw.order_reviews

ORDER BY field_name;