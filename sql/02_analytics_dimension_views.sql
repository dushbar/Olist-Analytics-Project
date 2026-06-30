--customer dimension
CREATE OR ALTER VIEW analytics.vw_dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.clean_customers;
GO

--product dimension
CREATE OR ALTER VIEW analytics.vw_dim_products AS
SELECT
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM staging.clean_products;
GO

--seller dimension
CREATE OR ALTER VIEW analytics.vw_dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.clean_sellers;
GO