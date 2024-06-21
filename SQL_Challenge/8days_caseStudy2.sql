--1.How many pizzas were ordered?
select count(1)  as total_pizza_ordered 
from customer_orders
--2.How many unique customer orders were made?
select 
count ( distinct order_id)  as count_unique_customer_order
from  customer_orders 
--3.How many successful orders were delivered by each runner?
SELECT 
    runner_id, 
    COUNT(runner_orders.order_id) AS success_orders
FROM 
    runner_orders

WHERE 
    TRY_CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL) != 0 
GROUP BY 
    runner_id;

--4.How many of each type of pizza was delivered?
select 
pizza_id,count (pizza_id) as pizza_delivered
from 
customer_orders join runner_orders 
on customer_orders.order_id = runner_orders.order_id 
WHERE  TRY_CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL) != 0 
group by pizza_id

--5.How many Vegetarian and Meatlovers were ordered by each customer?
select 
   customer_id ,customer_orders.pizza_id,pizza_name ,count(order_id)
from customer_orders join pizza_names 
on customer_orders.pizza_id = pizza_names.pizza_id
group by  customer_id,customer_orders.pizza_id, pizza_name

--6What was the maximum number of pizzas delivered in a single order?



--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--How many pizzas were delivered that had both exclusions and extras?
--What was the total volume of pizzas ordered for each hour of the day?
--What was the volume of orders for each day of the week?