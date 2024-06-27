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
group by  customer_id,customer_orders.pizza_id, pizza_name;

--6.What was the maximum number of pizzas delivered in a single order?
--6. What was the maximum number of pizzas delivered in a single order?
SELECT 
    MAX(pizza_count) AS max_pizzas_delivered
FROM (
    SELECT 
        customer_orders.order_id, 
        COUNT(customer_orders.pizza_id) AS pizza_count
    FROM 
        customer_orders
    JOIN 
        runner_orders 
    ON 
        customer_orders.order_id = runner_orders.order_id
    WHERE 
        TRY_CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL) != 0
    GROUP BY 
        customer_orders.order_id
) AS order_counts;

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    customer_orders.customer_id,
    SUM(CASE WHEN (customer_orders.exclusions IS NOT NULL AND customer_orders.exclusions != '') 
                  OR (customer_orders.extras IS NOT NULL AND customer_orders.extras != '') THEN 1 ELSE 0 END) AS pizzas_with_changes,
    SUM(CASE WHEN (customer_orders.exclusions IS NULL OR customer_orders.exclusions = '') 
                  AND (customer_orders.extras IS NULL OR customer_orders.extras = '') THEN 1 ELSE 0 END) AS pizzas_without_changes
FROM 
    customer_orders
JOIN 
    runner_orders 
ON 
    customer_orders.order_id = runner_orders.order_id
WHERE 
    TRY_CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL) != 0
GROUP BY 
    customer_orders.customer_id;
--8. How many pizzas were delivered that had both exclusions and extras?
SELECT  
  SUM(
    CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
    ELSE 0
    END) AS pizza_count_w_exclusions_extras
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
 WHERE 
        TRY_CAST(SUBSTRING(r.distance, 1, LEN(r.distance) - 2) AS DECIMAL) != 0
  AND exclusions <> ' ' 
  AND extras <> ' ';

--What was the total volume of pizzas ordered for each hour of the day?

SELECT 
  DATEPART(HOUR, [order_time]) AS hour_of_day, 
  COUNT(order_id) AS pizza_count
FROM customer_orders
GROUP BY DATEPART(HOUR, [order_time]);


--What was the volume of orders for each day of the week?

SELECT 
    DATENAME(WEEKDAY, order_time) AS day_of_week, 
    COUNT(order_id) AS order_volume
FROM 
    customer_orders
GROUP BY 
    DATENAME(WEEKDAY, order_time)


	---- # PART B
---1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    COUNT(*) AS num_runners,
    DATENAME(WEEK, registration_date) AS registration_day
FROM 
    runners 
WHERE 
    registration_date >= '2021-01-01' 
GROUP BY 
    DATENAME(WEEK, registration_date);



---2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH time_taken_cte AS
(
  SELECT 
    c.order_id, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes
  FROM customer_orders AS c
  JOIN runner_orders AS r
    ON c.order_id = r.order_id
  WHERE  TRY_CAST(SUBSTRING(r.distance, 1, LEN(r.distance) - 2) AS DECIMAL) != 0
  GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT 
  AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;


---3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_cte AS
(
  SELECT 
    c.order_id, 
    COUNT(c.order_id) AS pizza_order, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time_minutes
  FROM customer_orders AS c
  JOIN runner_orders AS r
    ON c.order_id = r.order_id
  WHERE  TRY_CAST(SUBSTRING(r.distance, 1, LEN(r.distance) - 2) AS DECIMAL) != 0
  GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT 
  pizza_order, 
  AVG(prep_time_minutes) AS avg_prep_time_minutes
FROM prep_time_cte
WHERE prep_time_minutes > 1
GROUP BY pizza_order;


---4. What was the average distance travelled for each customer?
SELECT 
    customer_id, 
    AVG(CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL)) AS avg_distance
FROM 
    runner_orders
JOIN 
    customer_orders ON runner_orders.order_id = customer_orders.order_id
WHERE 
    TRY_CAST(SUBSTRING(runner_orders.distance, 1, LEN(runner_orders.distance) - 2) AS DECIMAL) IS NOT NULL
GROUP BY 
    customer_id
---5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(duration_minutes) AS longest_delivery_time_minutes,
    MIN(duration_minutes) AS shortest_delivery_time_minutes,
    MAX(duration_minutes) - MIN(duration_minutes) AS difference_minutes
FROM
    (
        SELECT
            order_id,
            CASE
                WHEN duration LIKE '%minute%' THEN CAST(REPLACE(duration, ' minutes', '') AS DECIMAL(10,2))
                WHEN duration LIKE '%min%' THEN CAST(REPLACE(duration, ' min', '') AS DECIMAL(10,2))
                WHEN duration LIKE '%second%' THEN CAST(REPLACE(duration, ' seconds', '') AS DECIMAL(10,2)) / 60
                WHEN duration LIKE '%s%' THEN CAST(REPLACE(duration, 's', '') AS DECIMAL(10,2)) / 60
                ELSE NULL
            END AS duration_minutes
        FROM
            runner_orders
        WHERE
            duration IS NOT NULL
            AND cancellation IS NULL -- Filter out cancelled orders
            AND TRY_CAST(REPLACE(duration, ' minutes', '') AS DECIMAL(10,2)) IS NOT NULL -- Ensure it can be cast to DECIMAL
            AND TRY_CAST(REPLACE(duration, ' min', '') AS DECIMAL(10,2)) IS NOT NULL
            AND TRY_CAST(REPLACE(duration, ' seconds', '') AS DECIMAL(10,2)) IS NOT NULL
            AND TRY_CAST(REPLACE(duration, 's', '') AS DECIMAL(10,2)) IS NOT NULL
    ) AS valid_durations;




---6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
  r.runner_id, 
  c.customer_id, 
  c.order_id, 
  COUNT(c.order_id) AS pizza_count, 
  r.distance, (r.duration / 60) AS duration_hr , 
  ROUND((r.distance/r.duration * 60), 2) AS avg_speed
FROM runner_orders AS r
JOIN customer_orders AS c
  ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY r.runner_id, c.customer_id, c.order_id, r.distance, r.duration
ORDER BY c.order_id;








---7.What is the successful delivery percentage for each runner?
SELECT 
  runner_id, 
  ROUND(100 * SUM(
    CASE WHEN distance = 0 THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
FROM runner_orders
GROUP BY runner_id;

---- #PART C 
---1 What are the standard ingredients for each pizza ?
SELECT pn.pizza_name, value as topping
FROM pizza_names pn
JOIN pizza_recipes pr ON pn.pizza_id = pr.pizza_id
CROSS APPLY STRING_SPLIT(pr.toppings, ',');



---2 2. What was the most commonly added extra?
WITH toppings_cte AS (
    SELECT 
        pr.pizza_id,
        TRIM(value) AS topping_name
    FROM 
        pizza_recipes pr
    CROSS APPLY 
        STRING_SPLIT(pr.toppings, ',')
)

SELECT 
    pt.topping_id,
    pt.topping_name,
    COUNT(t.topping_name) AS topping_count
FROM 
    toppings_cte t
INNER JOIN pizza_toppings pt
    ON t.topping_name = pt.topping_id
GROUP BY 
    pt.topping_id, pt.topping_name
ORDER BY 
    topping_count DESC;
--- 3.  What was the most common exclusion?

-- Step 1: Use a CTE to split the exclusions into individual rows
WITH exclusions_cte AS (
    SELECT 
        TRIM(value) AS exclusion
    FROM 
        customer_orders
    CROSS APPLY 
        STRING_SPLIT(exclusions, ',')
)

-- Step 2: Count occurrences of each exclusion and find the most common one
SELECT 
    exclusion,
    COUNT(*) AS count
FROM 
    exclusions_cte
GROUP BY 
    exclusion
ORDER BY 
    count DESC;
---4 
SELECT 
    co.order_id,
    pn.pizza_name,
    COALESCE(NULLIF(co.exclusions, ''), 'No Exclusions') AS exclusions,
    COALESCE(NULLIF(co.extras, ''), 'No Extras') AS extras,
    
    pizza_name +
    CASE 
        WHEN exclusions IS NOT NULL AND exclusions <> '' THEN ' - Exclude ' + exclusions
        ELSE ''
    END +
    CASE 
        WHEN extras IS NOT NULL AND extras <> '' THEN ' - Extra ' + extras
        ELSE ''
    END AS order_item
FROM 
    customer_orders co
JOIN 
    pizza_names pn ON co.pizza_id = pn.pizza_id
ORDER BY 
    co.order_id;
--- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- Step 1: Expand the toppings, extras, and exclusions into individual rows



	---6

WITH delivered_orders AS (
    SELECT 
        co.order_id,
        co.pizza_id
    FROM 
        customer_orders co
    JOIN 
        runner_orders ro ON co.order_id = ro.order_id
    WHERE 
        ro.cancellation IS NULL
),


toppings_expanded AS (
    SELECT 
        do.order_id,
        TRIM(value) AS topping_name
    FROM 
        delivered_orders do
    JOIN 
        pizza_recipes pr ON do.pizza_id = pr.pizza_id
    CROSS APPLY 
        STRING_SPLIT(pr.toppings, ',')
),


toppings_count AS (
    SELECT 
        topping_name,
        COUNT(topping_name) AS topping_total
    FROM 
        toppings_expanded
    GROUP BY 
        topping_name
)

-- Step 4: Order the results by the frequency of each topping
SELECT 
    topping_name,
    topping_total
FROM 
    toppings_count
ORDER BY 
    topping_total DESC;


