create database ecomm;
use ecomm;

"""Data Import"""

select * from customer;
select * from orders;
select * from products;
select * from sales;
select * from [transaction];

"""Check Row Counts"""

select count(*) as customer_rows from customer;
select count(*) as order_rows from orders;
select count(*) as product_rows from products;
select count(*) as sales_rows from sales;
select count(*) as transaction_rows from [transaction];

"""Check Duplicates"""
select customer_id, count(*)as duplicate_count from customer group by customer_id having count(*) >1;
select product_id, count(*)as duplicate_count from products group by product_id having count(*) >1;
select order_id,product_id, count(*)as duplicate_count from orders group by order_id,product_id having count(*) >1;

"""Null Analysis"""
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN delivery_days IS NULL THEN 1 ELSE 0 END) 
        AS missing_delivery_days,

    SUM(CASE WHEN customer_rating IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_rating,

    SUM(CASE WHEN campaign_name IS NULL THEN 1 ELSE 0 END)
        AS missing_campaign,

    SUM(CASE WHEN coupon_code IS NULL THEN 1 ELSE 0 END)
        AS missing_coupon
FROM sales;

"""Joins"""
"""Missing values from sales"""

SELECT COUNT(*) AS unmatched_customers
FROM sales s
LEFT JOIN customer c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

"""Missing values from orders"""

SELECT COUNT(*) AS unmatched_products
FROM orders o
LEFT JOIN products p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;

"""Calculations"""
"total revenue"
SELECT SUM(net_sales) AS total_revenue FROM sales;
 
"total profit"
SELECT SUM(profit) AS total_profit FROM sales;

"avg order value"
SELECT AVG(net_sales) AS average_order_value FROM sales;

"total orders"
SELECT COUNT(DISTINCT order_id) AS total_orders FROM sales;

"total customers"
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM sales;

"profit margin"
SELECT SUM(profit) / NULLIF(SUM(net_sales), 0) * 100 AS overall_profit_margin FROM sales;

 
