use foodie_fi;
--- 1. How many customers has Foodie-Fi ever had?
select 
count (distinct customer_id)
from subscriptions;

--- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
  DATEPART(month, sub.start_date) AS month_date, -- Extract month part from start_date
  COUNT(sub.customer_id) AS trial_plan_subscriptions
FROM subscriptions AS sub
JOIN plans p
  ON sub.plan_id = p.plan_id
WHERE sub.plan_id = 0 -- Trial plan ID is 0
GROUP BY DATEPART(month, sub.start_date)
ORDER BY month_date;




-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
SELECT 
  p.plan_id,
  p.plan_name,
  COUNT(s.customer_id) AS event_count
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name;





 ---4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
 SELECT
  COUNT(DISTINCT sub.customer_id) AS churned_customers,
  ROUND(100.0 * COUNT(sub.customer_id)
    / (SELECT COUNT(DISTINCT customer_id) 
    	FROM subscriptions)
  ,1) AS churn_percentage
FROM subscriptions AS sub
JOIN plans
  ON sub.plan_id = plans.plan_id
WHERE plans.plan_id = 4; 


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH ranked_cte AS (
  SELECT 
    sub.customer_id, 
    plans.plan_id, 
    plans.plan_name,
    ROW_NUMBER() OVER (
      PARTITION BY sub.customer_id 
      ORDER BY sub.start_date) AS row_num
  FROM subscriptions AS sub
  JOIN plans 
    ON sub.plan_id = plans.plan_id
)
SELECT 
  SUM(CASE 
    WHEN row_num = 2 AND plan_name = 'churn' THEN 1 
    ELSE 0 
  END) AS churned_customers,
  ROUND(
    100.0 * SUM(CASE 
      WHEN row_num = 2 AND plan_name = 'churn' THEN 1 
      ELSE 0 
    END) 
    / (SELECT COUNT(DISTINCT customer_id) 
       FROM subscriptions),
    0
  ) AS churn_percentage
FROM ranked_cte;





-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH next_plans AS (
  SELECT 
    customer_id, 
    plan_id, 
    LEAD(plan_id) OVER (
      PARTITION BY customer_id 
      ORDER BY start_date) AS next_plan_id
  FROM subscriptions
)

SELECT 
  next_plan_id AS plan_id, 
  COUNT(customer_id) AS converted_customers,
  ROUND(
    100.0 * COUNT(customer_id) 
    / (SELECT COUNT(DISTINCT customer_id) 
       FROM subscriptions),
    1
  ) AS conversion_percentage
FROM next_plans
WHERE next_plan_id IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan_id
ORDER BY next_plan_id;




 ---7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with next_dates as  (
	 select customer_id, p.plan_id ,s.start_date ,
	LEAD (s.start_date ) over (
	PARTITION BY customer_id 
	order by start_date 
	) as next_date 
	 from plans p join subscriptions s 
	 on  p.plan_id = s.plan_id
	 where s.start_date <= '2020-12-31'
 ) 
 select 
 plan_id, count ( distinct customer_id),  ROUND(
 100.0 * COUNT( distinct customer_id)/ (
 select 
 COUNT (distinct customer_id) 
 from subscriptions
 ),1 
 
 )
 from next_dates 
 where next_date is  NULL 
 group by plan_id;

 


 ---8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS num_of_customers
FROM subscriptions
WHERE plan_id = 3
  AND start_date <= '2020-12-31';





 ---9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?
WITH customer_annual_plan AS (
    SELECT customer_id, start_date AS annual_start_date
    FROM subscriptions
    WHERE plan_id = 3
),
customer_other_plans AS (
    SELECT customer_id, start_date AS initial_start_date
    FROM subscriptions
    WHERE plan_id != 3
),
customer_upgrade_times AS (
    SELECT 
        co.customer_id,
        ca.annual_start_date,
        co.initial_start_date,
        DATEDIFF(day, co.initial_start_date, ca.annual_start_date) AS days_to_upgrade
    FROM customer_other_plans co 
    JOIN customer_annual_plan ca ON co.customer_id = ca.customer_id
)	

SELECT AVG(CAST(days_to_upgrade AS FLOAT)) AS average_days_to_upgrade
FROM customer_upgrade_times;







 ---10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial_plan AS (
    -- Filter results to include only the customers subscribed to the trial plan.
    SELECT 
        customer_id, 
        start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), 
annual_plan AS (
    -- Filter results to only include the customers subscribed to the pro annual plan.
    SELECT 
        customer_id, 
        start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
), 
bins AS (
    -- Calculate the difference in days between the trial and annual plan start dates,
    -- and categorize the results into 30-day buckets.
    SELECT 
        DATEDIFF(DAY, trial.trial_date, annual.annual_date) AS days_to_upgrade,
        FLOOR(DATEDIFF(DAY, trial.trial_date, annual.annual_date) / 30.0) + 1 AS avg_days_to_upgrade_bin
    FROM trial_plan AS trial
    JOIN annual_plan AS annual
        ON trial.customer_id = annual.customer_id
)
  
SELECT 
    CAST((avg_days_to_upgrade_bin - 1) * 30 AS VARCHAR) + ' - ' + 
    CAST(avg_days_to_upgrade_bin * 30 AS VARCHAR) + ' days' AS bucket, 
    COUNT(*) AS num_of_customers
FROM bins
GROUP BY avg_days_to_upgrade_bin
ORDER BY avg_days_to_upgrade_bin;






 ----11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
 WITH pro_monthly AS (
    SELECT 
        customer_id, 
        start_date AS pro_start_date,
        LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date
    FROM subscriptions
    WHERE plan_id = 2 AND YEAR(start_date) = 2020
), 
basic_monthly AS (
    SELECT 
        customer_id, 
        start_date AS basic_start_date
    FROM subscriptions
    WHERE plan_id = 1 AND YEAR(start_date) = 2020
)
  
SELECT 
    COUNT(DISTINCT p.customer_id) AS num_of_downgrades
FROM 
    pro_monthly p
JOIN 
    basic_monthly b ON p.customer_id = b.customer_id
WHERE 
    b.basic_start_date > p.pro_start_date
    AND (p.next_start_date IS NULL OR b.basic_start_date < p.next_start_date);
