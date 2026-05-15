/********************************************************************************
  PROJECT: Olist E-Commerce Analytics Pipeline
  SCRIPT: 01_Table_Definitions.sql
  DESCRIPTION: Initializing the Snowflake environment and defining the Raw schema.
********************************************************************************/

-- 1. ENVIRONMENT SETUP
-- Creating the main container and schema layers
CREATE DATABASE IF NOT EXISTS OLIST_DB;
CREATE SCHEMA IF NOT EXISTS OLIST_DB.RAW;
CREATE SCHEMA IF NOT EXISTS OLIST_DB.ANALYTICS;

USE DATABASE OLIST_DB;
USE SCHEMA RAW;

-- 2. FILE FORMAT DEFINITION
-- Standardized format for ingesting Kaggle CSV datasets
CREATE OR REPLACE FILE FORMAT olist_csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL')
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- 3. RAW DATA INGESTION TABLES (Bronze Layer)

-- Customers: Mapping unique customer IDs to locations
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id STRING,
    customer_unique_id STRING,
    customer_zip_code_prefix INT,
    customer_city STRING,
    customer_state STRING
);

-- Orders: Core transaction headers
CREATE OR REPLACE TABLE ORDERS (
    order_id STRING,
    customer_id STRING,
    order_status STRING,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Order Items: Line-level transaction details
CREATE OR REPLACE TABLE ORDER_ITEMS (
    order_id STRING,
    order_item_id INT,
    product_id STRING,
    seller_id STRING,
    shipping_limit_date TIMESTAMP,
    price FLOAT,
    freight_value FLOAT
);

-- Products: Metadata regarding product dimensions and categories
CREATE OR REPLACE TABLE PRODUCTS (
    product_id STRING,
    product_category_name STRING,
    product_name_lenght INT, -- Preserving original dataset nomenclature
    product_description_lenght INT,
    product_photos_qty INT,
    weight_g INT,
    length_cm INT,
    height_cm INT,
    width_cm INT
);

-- Category Translation: Mapping Portuguese category names to English
CREATE OR REPLACE TABLE PRODUCT_CATEGORY_NAME_TRANSLATION (
    product_category_name STRING,
    product_category_name_english STRING
);

-- 4. INITIAL QUALITY ASSURANCE (QA)
-- These checks ensure data loaded correctly before building analytical views
SELECT 'CUSTOMERS' as table_name, COUNT(*) as row_cnt FROM CUSTOMERS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS;