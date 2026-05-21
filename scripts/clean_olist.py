# import
import pandas as pd
import numpy as np
from pathlib import Path
import os


print(os.getcwd())


# define paths
BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DIR = BASE_DIR / "data" / "raw"
CLEAN_DIR = BASE_DIR / "data" / "cleaned"

CLEAN_DIR.mkdir(parents=True, exist_ok=True)


# load datasets
orders = pd.read_csv(RAW_DIR / "olist_orders_dataset.csv")
order_items = pd.read_csv(RAW_DIR / "olist_order_items_dataset.csv")
products = pd.read_csv(RAW_DIR / "olist_products_dataset.csv")
category_translation = pd.read_csv(
    RAW_DIR / "product_category_name_translation.csv"
)
customers = pd.read_csv(RAW_DIR / "olist_customers_dataset.csv")
payments = pd.read_csv(RAW_DIR / "olist_order_payments_dataset.csv")
reviews = pd.read_csv(RAW_DIR / "olist_order_reviews_dataset.csv")


# Initial Inspection
# This to avoid repeating the same inspection code for every DataFrame.
datasets = {
    "orders": orders,
    "order_items": order_items,
    "products": products,
    "customers": customers,
    "payments": payments,
    "reviews": reviews
}

for name, df in datasets.items():
    print("\n" + "=" * 50)
    print(name.upper())
    print("=" * 50)

    print(df.info())
    print("\nMissing Values:")
    print(df.isna().sum())

    print("\nDuplicates:", df.duplicated().sum())


# remove duplicates
for name, df in datasets.items():
    datasets[name] = df.drop_duplicates()

orders = datasets["orders"]
order_items = datasets["order_items"]
products = datasets["products"]
customers = datasets["customers"]
payments = datasets["payments"]
reviews = datasets["reviews"]



# parse timestamp columns in orders
date_cols = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in date_cols:
    orders[col] = pd.to_datetime(orders[col])



# handle missing values
print(products.isna().sum())


products["product_category_name"] = (
    products["product_category_name"]
    .fillna("unknown")
)


# validate prices
order_items = order_items[order_items["price"] > 0]

order_items = order_items[
    order_items["freight_value"] >= 0
]


# merge category translation
products = products.merge(
    category_translation,
    on="product_category_name",
    how="left"
)

# delivery KPIs
orders["delivery_days"] = (
    orders["order_delivered_customer_date"]
    - orders["order_purchase_timestamp"]
).dt.days

orders["is_late"] = (
    orders["order_delivered_customer_date"]
    > orders["order_estimated_delivery_date"]
)

orders["is_late"] = orders["is_late"].astype("Int64")

# create purchase month: will be
# useful for cohort analysis
orders["purchase_month"] = (
    orders["order_purchase_timestamp"]
    .dt.to_period("M")
    .astype(str)
)


products = products.rename(columns={
    "product_name_lenght": "product_name_length",
    "product_description_lenght": "product_description_length"
})

# save cleaned files
orders.to_csv(
    CLEAN_DIR / "clean_orders.csv",
    index=False
)

order_items.to_csv(
    CLEAN_DIR / "clean_order_items.csv",
    index=False
)

products.to_csv(
    CLEAN_DIR / "clean_products.csv",
    index=False
)

customers.to_csv(
    CLEAN_DIR / "clean_customers.csv",
    index=False
)

payments.to_csv(
    CLEAN_DIR / "clean_payments.csv",
    index=False
)

reviews.to_csv(
    CLEAN_DIR / "clean_reviews.csv",
    index=False
)