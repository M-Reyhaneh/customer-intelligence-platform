# Data Dictionary

This file documents the main tables, columns, derived features, and business definitions used in the project.

# Data Dictionary

This file documents the main raw tables, derived analytical datasets, key columns, and business definitions used in the Customer Intelligence Platform.

---

## 1. Raw Tables

### orders
Contains order-level status and timestamp information.

| Column | Description |
|---|---|
| `order_id` | Unique identifier for each order |
| `customer_id` | Customer identifier linked to the customers table |
| `order_status` | Current/final status of the order |
| `order_purchase_timestamp` | Timestamp when the customer placed the order |
| `order_approved_at` | Timestamp when the order payment was approved |
| `order_delivered_carrier_date` | Timestamp when the order was handed to the carrier |
| `order_delivered_customer_date` | Timestamp when the order was delivered to the customer |
| `order_estimated_delivery_date` | Estimated delivery date shown to the customer |

### order_items
Contains item-level order details. One order can contain multiple items.

| Column | Description |
|---|---|
| `order_id` | Order identifier |
| `order_item_id` | Item sequence number inside an order |
| `product_id` | Product identifier |
| `seller_id` | Seller identifier |
| `price` | Product item price |
| `freight_value` | Shipping/freight charge for the item |

### customers
Contains customer location and unique customer identifiers.

| Column | Description |
|---|---|
| `customer_id` | Customer identifier used in the orders table |
| `customer_unique_id` | Unique customer identifier across multiple orders |
| `customer_city` | Customer city |
| `customer_state` | Customer state |

### products
Contains product category and physical product attributes.

| Column | Description |
|---|---|
| `product_id` | Product identifier |
| `product_category_name` | Product category name |
| `product_weight_g` | Product weight in grams |
| `product_length_cm` | Product length in centimeters |
| `product_height_cm` | Product height in centimeters |
| `product_width_cm` | Product width in centimeters |

### payments
Contains payment records. One order can have multiple payment records.

| Column | Description |
|---|---|
| `order_id` | Order identifier |
| `payment_sequential` | Sequence number of payment record |
| `payment_type` | Payment method |
| `payment_installments` | Number of payment installments |
| `payment_value` | Payment amount |

---

## 2. Processed Dataset: `order_level_dataset.csv`

This dataset contains one row per order. It is created by aggregating item-level and payment-level tables before merging them with order and customer information.

| Column | Description |
|---|---|
| `order_id` | Unique order identifier |
| `customer_id` | Customer identifier |
| `customer_unique_id` | Unique customer identifier across orders |
| `order_status` | Order status |
| `customer_city` | Customer city |
| `customer_state` | Customer state |
| `product_revenue` | Sum of product item prices within the order |
| `shipping_revenue` | Sum of freight values within the order |
| `total_order_value` | Product revenue plus shipping revenue |
| `freight_ratio` | Shipping revenue divided by product revenue |
| `total_items` | Number of items in the order |
| `unique_products` | Number of unique products in the order |
| `unique_sellers` | Number of unique sellers in the order |
| `unique_categories` | Number of unique product categories in the order |
| `primary_product_category` | Product category with the highest item revenue in the order |
| `avg_item_price` | Average item price in the order |
| `max_item_price` | Maximum item price in the order |
| `avg_freight_value` | Average freight value in the order |
| `total_payment_value` | Total amount paid by the customer |
| `payment_installments` | Maximum number of installments used for the order |
| `number_of_payment_records` | Number of payment records linked to the order |
| `number_of_payment_types` | Number of distinct payment types used for the order |
| `main_payment_type` | Payment type with the highest total payment value |
| `order_date` | Date of order purchase |
| `order_month` | Purchase month in YYYY-MM format |
| `order_year` | Purchase year |
| `order_quarter` | Purchase quarter |
| `order_day_of_week` | Purchase day of week |
| `delivery_days` | Days between purchase and customer delivery |
| `estimated_delivery_days` | Days between purchase and estimated delivery date |
| `delivery_delay` | Days between actual delivery and estimated delivery |
| `is_late_delivery` | 1 if order was delivered after estimated date, otherwise 0 |
| `is_delivered` | 1 if order status is delivered, otherwise 0 |

---

## 3. Business Metric Definitions

### Product Revenue
`product_revenue = sum(price)`

Used as the main revenue metric for KPI and customer value analysis.

### Shipping Revenue
`shipping_revenue = sum(freight_value)`

Kept separately because freight is related to logistics and may not represent product sales.

### Total Order Value
`total_order_value = product_revenue + shipping_revenue`

Used when analyzing the full amount associated with an order.

### Total Payment Value
`total_payment_value = sum(payment_value)`

Represents the total amount paid by the customer.

### Freight Ratio
`freight_ratio = shipping_revenue / product_revenue`

Used to identify orders or categories where shipping cost is high relative to product value.

### Delivery Delay
`delivery_delay = order_delivered_customer_date - order_estimated_delivery_date`

Positive values indicate late delivery.

---

## 4. Important Analytical Decisions

- Item-level data is aggregated to order level before merging to avoid duplicated revenue.
- Payment-level data is aggregated to order level before merging to avoid duplicated payment values.
- `product_revenue` is used as the main revenue metric for customer value and KPI analysis.
- `shipping_revenue`, `total_order_value`, and `freight_ratio` are kept for operational and pricing analysis.
- Delivery-time analysis should focus mainly on delivered orders because non-delivered orders do not have valid customer delivery dates.