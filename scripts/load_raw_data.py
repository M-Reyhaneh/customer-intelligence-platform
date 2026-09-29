import csv
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"

load_dotenv(BASE_DIR / ".env")


TABLES = {
    "olist_customers_dataset.csv": {
        "table": "raw.customers",
        "columns": [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state",
        ],
    },
    "olist_geolocation_dataset.csv": {
        "table": "raw.geolocation",
        "columns": [
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng",
            "geolocation_city",
            "geolocation_state",
        ],
    },
    "olist_order_items_dataset.csv": {
        "table": "raw.order_items",
        "columns": [
            "order_id",
            "order_item_id",
            "product_id",
            "seller_id",
            "shipping_limit_date",
            "price",
            "freight_value",
        ],
    },
    "olist_order_payments_dataset.csv": {
        "table": "raw.order_payments",
        "columns": [
            "order_id",
            "payment_sequential",
            "payment_type",
            "payment_installments",
            "payment_value",
        ],
    },
    "olist_order_reviews_dataset.csv": {
        "table": "raw.order_reviews",
        "columns": [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message",
            "review_creation_date",
            "review_answer_timestamp",
        ],
    },
    "olist_orders_dataset.csv": {
        "table": "raw.orders",
        "columns": [
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    },
    "olist_products_dataset.csv": {
        "table": "raw.products",
        "columns": [
            "product_id",
            "product_category_name",
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ],
    },
    "olist_sellers_dataset.csv": {
        "table": "raw.sellers",
        "columns": [
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state",
        ],
    },
    "product_category_name_translation.csv": {
        "table": "raw.product_category_name_translation",
        "columns": [
            "product_category_name",
            "product_category_name_english",
        ],
    },
}


def count_csv_rows(path: Path) -> int:
    with path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)
        next(reader)
        return sum(1 for _ in reader)


def main():
    required_env = [
        "DB_HOST",
        "DB_PORT",
        "DB_NAME",
        "DB_USER",
        "DB_PASSWORD",
    ]

    missing = [name for name in required_env if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing environment variables: {', '.join(missing)}")

    with (
        psycopg.connect(
            host=os.environ["DB_HOST"],
            port=os.environ["DB_PORT"],
            dbname=os.environ["DB_NAME"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
        ) as conn,
        conn.cursor() as cur,
    ):
        for config in TABLES.values():
            cur.execute(f"TRUNCATE TABLE {config['table']};")

        for filename, config in TABLES.items():
            path = RAW_DIR / filename
            table = config["table"]
            columns = config["columns"]

            if not path.exists():
                raise FileNotFoundError(path)

            column_sql = ", ".join(columns)
            copy_sql = (
                f"COPY {table} ({column_sql}) FROM STDIN WITH (FORMAT CSV, HEADER TRUE)"
            )

            with (
                path.open("r", encoding="utf-8-sig", newline="") as file,
                cur.copy(copy_sql) as copy,
            ):
                while chunk := file.read(1024 * 1024):
                    copy.write(chunk)

            source_count = count_csv_rows(path)

            cur.execute(f"SELECT COUNT(*) FROM {table};")
            database_count = cur.fetchone()[0]

            print(f"{table}: source={source_count:,}, database={database_count:,}")

            if source_count != database_count:
                raise RuntimeError(
                    f"Row-count mismatch for {table}: "
                    f"{source_count} != {database_count}"
                )


if __name__ == "__main__":
    main()
