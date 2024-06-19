use my_database;

--1. What is the total amount each customer spent at the restaurant?
SELECT
s.customer_id,
SUM(price) as total_price
FROM sales s JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id 
Order By s.customer_id asc;
-- 2. How many days has each customer visited the restaurant?

Select customer_id , count( distinct DAY(s.order_date)) as "customer_visit"
from sales s 
group by customer_id;
-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchased AS (
 SELECT 
 customer_id,
 order_date,
 product_name,
 DENSE_RANK() OVER (
 PARTITION  BY sales.customer_id
 order by sales.order_date
 ) as rank
 FROM 
 sales  JOIN menu 
 on sales.product_id = menu.product_id 
)

select 
customer_id, product_name
from first_purchased
where  rank =1
group by customer_id,product_name
--  4. What is the most purchased item on the menu and how many times was it purchased by all customers?


