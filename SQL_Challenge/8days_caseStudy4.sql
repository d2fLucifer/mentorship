---1.-- Number of unique nodes
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

---2. -- Number of nodes per region
SELECT region_id, COUNT(DISTINCT node_id) AS nodes_per_region
FROM customer_nodes
GROUP BY region_id;

---3. -- Number of customers allocated to each region
SELECT region_id, COUNT(DISTINCT customer_id) AS customers_per_region
FROM customer_nodes
GROUP BY region_id;

---4. -- Average number of days customers are allocated to a different node
SELECT AVG(end_date - start_date) AS avg_reallocation_days
FROM customer_nodes
WHERE end_date IS NOT NULL;

---5 What is the median, 80th and 95th percentile for this same reallocation days metric for each region?






----B 
---1.What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT( customer_id) AS unique_count, SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
group by txn_type



--2.  What is the average total historical deposit counts and amounts for all customers?
with total_deposit as (
select 
sum(txn_amount) as total_deposit_amount,count( customer_id) as total_deposit_count
from data_bank.customer_transactions
where txn_type = 'deposit'
group by customer_id, txn_type
)
select 
ROUND (avg(total_deposit_amount)) as avg_total_deposit_amount,ROUND (avg(total_deposit_count)) as avg_total_deposit_count
from total_deposit
 

---3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH Deposits AS (
    SELECT 
        customer_id, 
        EXTRACT(MONTH FROM txn_date) AS month, 
        COUNT(*) AS deposit_count
    FROM 
        data_bank.customer_transactions
    WHERE 
        txn_type = 'deposit'
    GROUP BY 
        customer_id, 
        EXTRACT(MONTH FROM txn_date)
    HAVING 
        COUNT(*) > 1
),
PurchasesWithdrawals AS (
    SELECT 
        customer_id, 
        EXTRACT(MONTH FROM txn_date) AS month
    FROM 
        data_bank.customer_transactions
    WHERE 
        txn_type IN ('purchase', 'withdrawal')
    GROUP BY 
        customer_id, 
        EXTRACT(MONTH FROM txn_date)
    HAVING 
        COUNT(*) >= 1
)
SELECT 
    D.month, 
    COUNT(DISTINCT D.customer_id) AS customer_count
FROM 
    Deposits D
JOIN 
    PurchasesWithdrawals PW
ON 
    D.customer_id = PW.customer_id 
    AND D.month = PW.month
GROUP BY 
    D.month
ORDER BY 
    D.month;




---4. What is the closing balance for each customer at the end of the month?
---5. What is the percentage of customers who increase their closing balance by more than 5%?

