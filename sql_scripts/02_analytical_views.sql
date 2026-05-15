/********************************************************************************
  PROJECT: Olist E-Commerce Analytics Pipeline
  SCRIPT: 02_Analytical_Views.sql
  DESCRIPTION: Creating the Gold Layer views for Power BI consumption.
               Includes Fact Sales, Retention Status, and RFM Segmentation.
********************************************************************************/

USE DATABASE OLIST_DB;
USE SCHEMA ANALYTICS;

-- 1. FACT_SALES: The central transaction view
-- Consolidates orders, items, and product translations for comprehensive sales reporting.
CREATE OR REPLACE VIEW OLIST_DB.ANALYTICS.FACT_SALES AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    -- Calculation for logistics latency performance
    DATEDIFF('day', o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_time_days,
    t.product_category_name_english,
    -- Financial aggregations per order
    SUM(i.price) AS total_item_value,
    SUM(i.freight_value) AS total_freight_value,
    COUNT(i.product_id) AS total_items_count
FROM OLIST_DB.RAW.ORDERS o
JOIN OLIST_DB.RAW.CUSTOMERS c ON o.customer_id = c.customer_id
JOIN OLIST_DB.RAW.ORDER_ITEMS i ON o.order_id = i.order_id
JOIN OLIST_DB.RAW.PRODUCTS p ON i.product_id = p.product_id
JOIN OLIST_DB.RAW.PRODUCT_CATEGORY_NAME_TRANSLATION t ON p.product_category_name = t.product_category_name
GROUP BY 1,2,3,4,5,6,7,8,9,10;

-- 2. CUSTOMER_RETENTION: Identifying churned vs active users
-- Based on a 90-day inactivity threshold relative to the latest dataset entry (2018-09-03).
CREATE OR REPLACE VIEW OLIST_DB.ANALYTICS.CUSTOMER_RETENTION AS
WITH last_purchase AS (
    SELECT 
        customer_unique_id,
        MAX(order_purchase_timestamp) as latest_order,
        COUNT(order_id) as total_orders
    FROM OLIST_DB.ANALYTICS.FACT_SALES
    GROUP BY 1
)
SELECT 
    *,
    CASE 
        WHEN DATEDIFF('day', latest_order, '2018-09-03') > 90 THEN 'Inactive'
        ELSE 'Active'
    END AS churn_status
FROM last_purchase;

-- 3. CUSTOMER_SEGMENTATION: RFM-based Behavioral Analysis
-- Categorizing customers to drive targeted marketing and strategic growth.
CREATE OR REPLACE VIEW OLIST_DB.ANALYTICS.CUSTOMER_SEGMENTATION AS
WITH customer_metrics AS (
    SELECT 
        customer_unique_id,
        MAX(order_purchase_timestamp) as last_order_date,
        COUNT(order_id) as total_orders,
        SUM(total_item_value) as total_spent
    FROM OLIST_DB.ANALYTICS.FACT_SALES
    GROUP BY 1
)
SELECT 
    *,
    CASE 
        WHEN total_orders > 1 AND total_spent > 500 THEN 'Champion'
        WHEN total_orders > 1 AND total_spent <= 500 THEN 'Loyal Customer'
        WHEN total_orders = 1 AND total_spent > 500 THEN 'Big Spender'
        ELSE 'One-Time Buyer'
    END AS customer_segment
FROM customer_metrics;

-- 4. VALIDATION QUERY
-- Final check to ensure views are populating and accessible
SELECT 'FACT_SALES' as view_name, COUNT(*) as row_count FROM FACT_SALES
UNION ALL
SELECT 'CUSTOMER_SEGMENTATION', COUNT(*) FROM CUSTOMER_SEGMENTATION;