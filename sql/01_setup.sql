CREATE DATABASE OlistAnalytics;
GO

USE OlistAnalytics;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA analytics;
GO


CREATE INDEX IX_clean_orders_order_id
ON staging.clean_orders(order_id);

CREATE INDEX IX_clean_orders_customer_id
ON staging.clean_orders(customer_id);

CREATE INDEX IX_clean_order_items_order_id
ON staging.clean_order_items(order_id);

CREATE INDEX IX_clean_order_items_product_id
ON staging.clean_order_items(product_id);

CREATE INDEX IX_clean_order_items_seller_id
ON staging.clean_order_items(seller_id);

CREATE INDEX IX_clean_products_product_id
ON staging.clean_products(product_id);

CREATE INDEX IX_clean_customers_customer_id
ON staging.clean_customers(customer_id);

CREATE INDEX IX_clean_customers_customer_unique_id
ON staging.clean_customers(customer_unique_id);

CREATE INDEX IX_clean_sellers_seller_id
ON staging.clean_sellers(seller_id);

CREATE INDEX IX_clean_payments_order_id
ON staging.clean_payments(order_id);

CREATE INDEX IX_clean_reviews_order_id
ON staging.clean_reviews(order_id);