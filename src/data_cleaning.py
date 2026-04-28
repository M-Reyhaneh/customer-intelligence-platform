"""
Data loading and cleaning utilities for the Customer Intelligence Platform.
"""

from pathlib import Path
import pandas as pd
import numpy as np


def get_project_paths():
    """
    Return main project paths.
    Works whether code is executed from root or notebooks folder.
    """
    base_dir = Path.cwd().parent if Path.cwd().name == "notebooks" else Path.cwd()
    data_raw = base_dir / "data" / "raw"
    data_processed = base_dir / "data" / "processed"

    return base_dir, data_raw, data_processed


def load_raw_data(data_raw):
    """
    Load the main Olist raw datasets.
    """
    orders = pd.read_csv(data_raw / "olist_orders_dataset.csv")
    items = pd.read_csv(data_raw / "olist_order_items_dataset.csv")
    customers = pd.read_csv(data_raw / "olist_customers_dataset.csv")
    products = pd.read_csv(data_raw / "olist_products_dataset.csv")
    payments = pd.read_csv(data_raw / "olist_order_payments_dataset.csv")

    return {
        "orders": orders,
        "items": items,
        "customers": customers,
        "products": products,
        "payments": payments,
    }


def missing_summary(df):
    """
    Return missing value count and percentage for a dataframe.
    """
    summary = pd.DataFrame({
        "missing_count": df.isna().sum(),
        "missing_percent": df.isna().mean() * 100
    })

    return summary.sort_values("missing_percent", ascending=False)


def convert_order_dates(orders):
    """
    Convert order timestamp columns to datetime.
    """
    orders = orders.copy()

    date_cols = [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ]

    for col in date_cols:
        orders[col] = pd.to_datetime(orders[col], errors="coerce")

    return orders


def duplicate_summary(tables):
    """
    Return duplicate row summary for multiple tables.
    """
    summary = []

    for name, df in tables.items():
        summary.append({
            "table": name,
            "rows": df.shape[0],
            "duplicate_rows": df.duplicated().sum(),
            "duplicate_percent": round(df.duplicated().mean() * 100, 3),
        })

    return pd.DataFrame(summary)


def check_key_uniqueness(orders, items, customers, products, payments):
    """
    Check whether expected primary keys are unique.
    """
    return {
        "orders_order_id_unique": orders["order_id"].is_unique,
        "customers_customer_id_unique": customers["customer_id"].is_unique,
        "products_product_id_unique": products["product_id"].is_unique,
        "items_order_id_unique": items["order_id"].is_unique,
        "payments_order_id_unique": payments["order_id"].is_unique,
    }


def get_primary_category(group):
    """
    Return the product category with the highest item revenue within an order.
    """
    category_revenue = (
        group.dropna(subset=["product_category_name"])
        .groupby("product_category_name")["price"]
        .sum()
        .sort_values(ascending=False)
    )

    if category_revenue.empty:
        return np.nan

    return category_revenue.index[0]


def build_item_order_aggregation(items, products):
    """
    Aggregate item-level data to order level and add product/category features.
    """
    items_enriched = items.merge(
        products[
            [
                "product_id",
                "product_category_name",
                "product_weight_g",
                "product_length_cm",
                "product_height_cm",
                "product_width_cm",
            ]
        ],
        on="product_id",
        how="left",
    )

    item_order_agg = (
        items_enriched
        .groupby("order_id")
        .agg(
            product_revenue=("price", "sum"),
            shipping_revenue=("freight_value", "sum"),
            total_items=("order_item_id", "count"),
            unique_products=("product_id", "nunique"),
            unique_sellers=("seller_id", "nunique"),
            unique_categories=("product_category_name", "nunique"),
            avg_item_price=("price", "mean"),
            max_item_price=("price", "max"),
            avg_freight_value=("freight_value", "mean"),
        )
        .reset_index()
    )

    primary_categories = (
        items_enriched
        .groupby("order_id")
        .apply(get_primary_category)
        .reset_index(name="primary_product_category")
    )

    item_order_agg = item_order_agg.merge(
        primary_categories,
        on="order_id",
        how="left",
    )

    item_order_agg["total_order_value"] = (
        item_order_agg["product_revenue"] + item_order_agg["shipping_revenue"]
    )

    item_order_agg["freight_ratio"] = (
        item_order_agg["shipping_revenue"]
        / item_order_agg["product_revenue"].replace(0, np.nan)
    )

    return item_order_agg


def get_main_payment_type(group):
    """
    Return the payment type with the highest total payment value for an order.
    """
    payment_by_type = (
        group.groupby("payment_type")["payment_value"]
        .sum()
        .sort_values(ascending=False)
    )

    if payment_by_type.empty:
        return np.nan

    return payment_by_type.index[0]


def build_payment_order_aggregation(payments):
    """
    Aggregate payment-level data to order level.
    """
    payment_order_agg = (
        payments
        .groupby("order_id")
        .agg(
            total_payment_value=("payment_value", "sum"),
            payment_installments=("payment_installments", "max"),
            number_of_payment_records=("payment_sequential", "count"),
            number_of_payment_types=("payment_type", "nunique"),
        )
        .reset_index()
    )

    main_payment_type = (
        payments
        .groupby("order_id")
        .apply(get_main_payment_type)
        .reset_index(name="main_payment_type")
    )

    payment_order_agg = payment_order_agg.merge(
        main_payment_type,
        on="order_id",
        how="left",
    )

    return payment_order_agg


def build_order_level_dataset(orders, customers, item_order_agg, payment_order_agg):
    """
    Build the final order-level analytical dataset.
    """
    order_base = orders.merge(
        customers,
        on="customer_id",
        how="left",
    )

    order_level = (
        order_base
        .merge(item_order_agg, on="order_id", how="left")
        .merge(payment_order_agg, on="order_id", how="left")
    )

    return order_level


def add_order_time_features(order_level):
    """
    Add time-based and delivery-related features to the order-level dataset.
    """
    order_level = order_level.copy()

    order_level["order_date"] = order_level["order_purchase_timestamp"].dt.date
    order_level["order_month"] = order_level["order_purchase_timestamp"].dt.to_period("M").astype(str)
    order_level["order_year"] = order_level["order_purchase_timestamp"].dt.year
    order_level["order_quarter"] = order_level["order_purchase_timestamp"].dt.quarter
    order_level["order_day_of_week"] = order_level["order_purchase_timestamp"].dt.day_name()

    order_level["delivery_days"] = (
        order_level["order_delivered_customer_date"]
        - order_level["order_purchase_timestamp"]
    ).dt.days

    order_level["estimated_delivery_days"] = (
        order_level["order_estimated_delivery_date"]
        - order_level["order_purchase_timestamp"]
    ).dt.days

    order_level["delivery_delay"] = (
        order_level["order_delivered_customer_date"]
        - order_level["order_estimated_delivery_date"]
    ).dt.days

    order_level["is_late_delivery"] = np.where(
        order_level["delivery_delay"] > 0,
        1,
        0,
    )

    order_level["is_delivered"] = np.where(
        order_level["order_status"] == "delivered",
        1,
        0,
    )

    return order_level