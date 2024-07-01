---1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS user_count
FROM clique_bait.users;


--- 2. How many cookies does each user have on average?
SELECT AVG(cookie_count) AS avg_cookies_per_user
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM clique_bait.users
    GROUP BY user_id
) AS cookie_counts;

--3. What is the unique number of visits by all users per month?
SELECT DATE_TRUNC('month', event_time) AS month, COUNT(DISTINCT visit_id) AS unique_visits
FROM clique_bait.events
GROUP BY month
ORDER BY month;

---4. What is the number of events for each event type?
SELECT event_type, COUNT(*) AS event_count
FROM clique_bait.events
GROUP BY event_type

---5. What is the percentage of visits which have a purchase event?
SELECT
    ROUND(
        (COUNT(DISTINCT events.visit_id) * 100.0) /
        (SELECT COUNT( DISTINCT visit_id) FROM clique_bait.events), 2
    ) AS purchase_percentage
FROM
    clique_bait.events
JOIN
    clique_bait.event_identifier ON events.event_type = event_identifier.event_type
WHERE
    event_identifier.event_name = 'Purchase';





---6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH checkout_purchase AS (
    SELECT 
        visit_id,
        MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
        MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
    FROM clique_bait.events
    GROUP BY visit_id
)


SELECT 
    ROUND(
        100.0 * SUM(CASE WHEN checkout = 1 AND purchase = 0 THEN 1 ELSE 0 END) / 
        COUNT(*), 
        2
    ) AS percentage_checkout_view_with_no_purchase
FROM checkout_purchase
WHERE checkout = 1

---7. What are the top 3 pages by number of views?
WITH RankedPages AS (
    SELECT 
        page_id, 
        COUNT(page_id) AS view_count,
        DENSE_RANK() OVER (ORDER BY COUNT(page_id) DESC) AS rank
    FROM 
        clique_bait.events 
        WHERE event_type = 1 
    GROUP BY 
        page_id
)
SELECT 
    page_id, 
    view_count, 
    rank
FROM 
    RankedPages
WHERE 
    rank <= 3



---8. What is the number of views and cart adds for each product category?  
SELECT
page_hierarchy.product_category,
SUM (CASE WHEN event_identifier.event_name ='Page View' then 1 else 0 END) as views, 
SUM (CASE WHEN event_identifier.event_name = 'Add to Cart ' then 1 else 0 END) as carts_add
FROM 
clique_bait.events join clique_bait.page_hierarchy 
on events.page_id = page_hierarchy.page_id
join clique_bait.event_identifier on 
event_identifier.event_type = events.event_type 
GROUP BY page_hierarchy.product_category ;

---9. What are the top 3 products by purchases?
WITH product_purchases AS (
    SELECT 
        ph.product_id,
        ph.product_category,
        COUNT(*) AS purchase_count
    FROM 
        clique_bait.events e
    JOIN 
        clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    WHERE 
        e.event_type = 3
    GROUP BY 
        ph.product_id, ph.product_category
),
ranked_products AS (
    SELECT 
        product_id,
        product_category,
        purchase_count,
        DENSE_RANK() OVER (ORDER BY purchase_count DESC) AS rank
    FROM 
       product_purchases
)
SELECT 
    product_id,
    product_category,
    purchase_count,
    rank
FROM 
   ranked_products
WHERE 
    rank <= 3;

--- #B

WITH product_events AS (
    SELECT
        ph.product_id,
        ph.product_category,
        ei.event_name
    FROM
        events e
        JOIN page_hierarchy ph ON e.page_id = ph.page_id
        JOIN event_identifier ei ON e.event_type = ei.event_type
),
product_summary AS (
    SELECT
        product_id,
        product_category,
        COUNT(CASE WHEN event_name = 'Product Viewed' THEN 1 END) AS views,
        COUNT(CASE WHEN event_name = 'Product Added to Cart' THEN 1 END) AS added_to_cart,
        COUNT(CASE WHEN event_name = 'Product Added to Cart' AND NOT EXISTS (
            SELECT 1 FROM product_events pe2
            WHERE pe2.product_id = pe.product_id
            AND pe2.event_name = 'Product Purchased') THEN 1 END) AS abandoned,
        COUNT(CASE WHEN event_name = 'Product Purchased' THEN 1 END) AS purchased
    FROM
        product_events pe
    GROUP BY
        product_id, product_category    
),
category_summary AS (
    SELECT
        product_category,
        COUNT(CASE WHEN event_name = 'Product Viewed' THEN 1 END) AS views,
        COUNT(CASE WHEN event_name = 'Product Added to Cart' THEN 1 END) AS added_to_cart,
        COUNT(CASE WHEN event_name = 'Product Added to Cart' AND NOT EXISTS (
            SELECT 1 FROM product_events pe2
            WHERE pe2.product_category = pe.product_category
            AND pe2.event_name = 'Product Purchased') THEN 1 END) AS abandoned,
        COUNT(CASE WHEN event_name = 'Product Purchased' THEN 1 END) AS purchased
    FROM
        product_events pe
    GROUP BY
        product_category
)
--- 1.Which product had the most views, cart adds and purchases?
-- Most views
SELECT product_id, views
FROM product_summary
ORDER BY views DESC
LIMIT 1;

-- Most cart adds
SELECT product_id, added_to_cart
FROM product_summary
ORDER BY added_to_cart DESC
LIMIT 1;

-- Most purchases
SELECT product_id, purchased
FROM product_summary
ORDER BY purchased DESC
LIMIT 1;

---2. Which product was most likely to be abandoned?
SELECT product_id, abandoned
FROM product_summary
ORDER BY abandoned DESC
LIMIT 1;
---3.Which product had the highest view to purchase percentage?
SELECT product_id, 
       (CAST(purchased AS FLOAT) / NULLIF(views, 0)) * 100 AS view_to_purchase_percentage
FROM product_summary
ORDER BY view_to_purchase_percentage DESC
LIMIT 1;
---4.What is the average conversion rate from view to cart add?

-- Average conversion rate from view to cart add
SELECT AVG(CAST(added_to_cart AS FLOAT) / NULLIF(views, 0)) * 100 AS avg_view_to_cart_add_conversion_rate
FROM product_summary;


---5.What is the average conversion rate from cart add to purchase?
-- Average conversion rate from cart add to purchase
SELECT AVG(CAST(purchased AS FLOAT) / NULLIF(added_to_cart, 0)) * 100 AS avg_cart_add_to_purchase_conversion_rate
FROM product_summary;



