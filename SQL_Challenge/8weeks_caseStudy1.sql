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
SELECT 
    s.customer_id, 
    m.product_name
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
WHERE 
    (s.customer_id, s.order_date) IN (
        SELECT 
            customer_id, 
            MIN(order_date) 
        FROM 
            sales 
        GROUP BY 
            customer_id
    );

--  4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 
    m.product_name, 
    COUNT(*) AS purchase_count
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
GROUP BY 
    m.product_name
ORDER BY 
    purchase_count DESC

----5. Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT 
    sales.customer_id, 
    menu.product_name, 
    COUNT(menu.product_id) AS order_count,
    DENSE_RANK() OVER (
      PARTITION BY sales.customer_id 
      ORDER BY COUNT(sales.customer_id) DESC) AS rank
  FROM menu
  INNER JOIN sales
    ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE rank = 1;

---6 Which item was purchased first by the customer after they became a member?
SELECT s.customer_id, s.product_id, s.order_date
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date > m.join_date
ORDER BY s.customer_id, s.order_date
LIMIT 1;
--7 Which item was purchased just before the customer became a member?
SELECT s.customer_id, s.product_id, s.order_date
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
ORDER BY s.customer_id, s.order_date DESC
LIMIT 1;
---8 What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) AS total_items, SUM(mn.price) AS total_amount
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
JOIN menu mn ON s.product_id = mn.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

---9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
SELECT s.customer_id, 
       SUM(CASE 
           WHEN mn.product_name = 'sushi' THEN mn.price * 20 
           ELSE mn.price * 10 
       END) AS total_points
FROM sales s
JOIN menu mn ON s.product_id = mn.product_id
GROUP BY s.customer_id;

---10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
SELECT s.customer_id, 
       SUM(CASE 
           WHEN s.order_date BETWEEN m.join_date AND m.join_date + INTERVAL '7 DAY' THEN mn.price * 20 
           WHEN mn.product_name = 'sushi' THEN mn.price * 20 
           ELSE mn.price * 10 
       END) AS total_points
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
JOIN menu mn ON s.product_id = mn.product_id
WHERE s.order_date <= '2024-01-31'
GROUP BY s.customer_id;
