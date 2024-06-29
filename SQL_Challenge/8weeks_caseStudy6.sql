---1. How many users are there?
SELECT COUNT ( DISTINCT users.user_id) AS total_users
FROM users;

--- 2. How many cookies does each user have on average?
SELECT AVG(cookie_count) AS avg_cookies_per_user
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM users
    GROUP BY user_id
) AS cookie_counts;

--3. What is the unique number of visits by all users per month?
SELECT DATE_TRUNC('month', event_time) AS month, COUNT(DISTINCT visit_id) AS unique_visits
FROM events
GROUP BY month
ORDER BY month;

---4. What is the number of events for each event type?
SELECT ei.event_name, COUNT(e.event_type) AS event_count
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY ei.event_name
ORDER BY event_count DESC;

---5. What is the percentage of visits which have a purchase event?
WITH purchase_visits AS (
    SELECT DISTINCT visit_id
    FROM events
    WHERE event_type = (SELECT event_type FROM event_identifier WHERE event_name = 'purchase')
)
SELECT (COUNT(pv.visit_id) * 100.0 / COUNT(DISTINCT e.visit_id)) AS purchase_visit_percentage
FROM events e
LEFT JOIN purchase_visits pv ON e.visit_id = pv.visit_id;

---6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH checkout_visits AS (
    SELECT DISTINCT visit_id
    FROM events
    WHERE page_id = (SELECT page_id FROM page_hierarchy WHERE page_name = 'checkout')
),
purchase_visits AS (
    SELECT DISTINCT visit_id
    FROM events
    WHERE event_type = (SELECT event_type FROM event_identifier WHERE event_name = 'purchase')
)
SELECT (COUNT(cv.visit_id) - COUNT(pv.visit_id)) * 100.0 / COUNT(DISTINCT e.visit_id) AS checkout_without_purchase_percentage
FROM events e
LEFT JOIN checkout_visits cv ON e.visit_id = cv.visit_id
LEFT JOIN purchase_visits pv ON e.visit_id = pv.visit_id;

---7. What are the top 3 pages by number of views?
SELECT ph.page_name, COUNT(e.page_id) AS views
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
GROUP BY ph.page_name
ORDER BY views DESC
LIMIT 3;

---8. What is the number of views and cart adds for each product category?
SELECT ph.product_category, 
       SUM(CASE WHEN ei.event_name = 'view' THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN ei.event_name = 'cart_add' THEN 1 ELSE 0 END) AS cart_adds
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY ph.product_category
ORDER BY ph.product_category;

---9. What are the top 3 products by purchases?
SELECT ph.product_id, COUNT(e.event_type) AS purchases
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = (SELECT event_type FROM event_identifier WHERE event_name = 'purchase')
GROUP BY ph.product_id
ORDER BY purchases DESC
LIMIT 3;

