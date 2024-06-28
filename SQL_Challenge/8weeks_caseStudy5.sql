---1. What day of the week is used for each week_date value?
SELECT DISTINCT(TO_CHAR(week_date, 'day')) AS week_day 
FROM clean_weekly_sales;
---2 What range of week numbers are missing from the dataset?
with week_range as (
SELECT GENERATE_SERIES (1, 52) as week_num
)
SELECT week_num 
FROM week_range  Left JOIN clean_weekly_sales
on week_num =  week_number
WHERE week_number IS NULL;  
-- 3.How many total transactions were there for each year in the dataset?
SELECT EXTRACT(YEAR FROM week_date) AS year, COUNT(*) AS total_transactions
FROM data_mart.clean_weekly_sales 
GROUP BY year
---4. What is the total sales for each region for each month?
SELECT
region, EXTRACT(MONTH FROM week_date) AS month, SUM(sales) AS total_sales
FROM 
data_mart.clean_weekly_sales
GROUP BY region, EXTRACT(MONTH FROM week_date)


---5. What is the total count of transactions for each platform
SELECT platform, COUNT(*) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform
--6.What is the percentage of sales for Retail vs Shopify for each month?
SELECT
EXTRACT(MONTH FROM week_date) AS month, platform, SUM(sales) AS total_sales,
Round (SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY EXTRACT(MONTH FROM week_date)) * 100, 2) AS percentage_sales
FROM data_mart.clean_weekly_sales   
GROUP BY EXTRACT(MONTH FROM week_date), platform
---7.What is the percentage of sales by demographic for each year in the dataset?
SELECT
EXTRACT(YEAR FROM week_date) AS year, demographic, SUM(sales) AS total_sales,
Round (SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY EXTRACT(YEAR FROM week_date)) * 100, 2) AS percentage_sales
FROM data_mart.clean_weekly_sales
GROUP BY EXTRACT(YEAR FROM week_date), demographic
--8. Which age_band and demographic values contribute the most to Retail sales?
Select age_band, demographic, SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic


--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
EXTRACT(YEAR FROM week_date) AS year, platform, AVG(transactions) AS avg_transaction
FROM data_mart.clean_weekly_sales
GROUP BY EXTRACT(YEAR FROM week_date), platform
