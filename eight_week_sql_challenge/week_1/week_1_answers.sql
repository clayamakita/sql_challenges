/* --------------------
   Link to original challenge - https://8weeksqlchallenge.com/case-study-1/
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	sales.customer_id, 
    SUM(menu.price) AS amount_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu 
	ON menu.product_id = sales.product_id
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?
WITH customer_days_visited AS (
	SELECT DISTINCT
  		customer_id, 
  		order_date
  	FROM dannys_diner.sales
)
SELECT
	customer_id, 
    COUNT(order_date) as days_visited
FROM customer_days_visited
GROUP BY 1
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?
WITH added_row_number AS (
  SELECT 
      sales.customer_id, 
      menu.product_name, 
      ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS row_number_product
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
      ON menu.product_id = sales.product_id
)
SELECT
	customer_id, 
    product_name
FROM added_row_number
WHERE row_number_product = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH purchases_item AS (
  SELECT
      product_id, 
      COUNT(product_id) as number_purchases
  FROM dannys_diner.sales
  GROUP BY 1
  ORDER BY 1 DESC
  LIMIT 1
)
SELECT 
	menu.product_name, 
    purchases.number_purchases
FROM purchases_item AS purchases
JOIN dannys_diner.menu 
	ON menu.product_id = purchases.product_id;

-- 5. Which item was the most popular for each customer?
WITH customer_purchases AS (
  SELECT
  	sales.customer_id, 
  	menu.product_name, 
  	COUNT(sales.product_id) AS number_purchases, 
  	ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) as row_number_purchases
  FROM dannys_diner.sales
  JOIN dannys_diner.menu 
  	ON menu.product_id = sales.product_id
  GROUP BY 1, 2
  ORDER BY 1
)
SELECT
	customer_id, 
    product_name, 
    number_purchases
FROM customer_purchases
WHERE row_number_purchases = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH purchases_members AS (
  SELECT 
  	sales.customer_id, 
  	menu.product_name, 
  	sales.order_date, 
  	ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS row_number_purchase
  FROM dannys_diner.sales
  JOIN dannys_diner.members
  	ON members.customer_id = sales.customer_id
  	AND sales.order_date > members.join_date
  JOIN dannys_diner.menu
  	ON menu.product_id = sales.product_id
)
SELECT
	customer_id, 
    product_name, 
    order_date
FROM purchases_members
WHERE row_number_purchase = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH purchases_members AS (
  SELECT 
  	sales.customer_id, 
  	menu.product_name, 
  	sales.order_date, 
  	ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS row_number_purchase
  FROM dannys_diner.sales
  JOIN dannys_diner.members
  	ON members.customer_id = sales.customer_id
  	AND sales.order_date <= members.join_date
  JOIN dannys_diner.menu
  	ON menu.product_id = sales.product_id
)
SELECT
	customer_id, 
    product_name, 
    order_date
FROM purchases_members
WHERE row_number_purchase = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	sales.customer_id, 
    COUNT(sales.product_id) as items_purchased, 
    SUM(menu.price) as amount_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
	ON menu.product_id = sales.product_id
JOIN dannys_diner.members
	ON members.customer_id = sales.customer_id
    AND sales.order_date < members.join_date
GROUP BY 1
ORDER BY 1
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_table AS (
  SELECT
  	*, 
  	CASE 
  		WHEN product_name = 'sushi' THEN price * 20
  		ELSE price * 10
  	END AS points
  FROM dannys_diner.menu

)
SELECT
	sales.customer_id, 
    SUM(points_table.points) as total_points
FROM dannys_diner.sales
JOIN points_table
	ON points_table.product_id = sales.product_id
GROUP BY 1
ORDER BY 1
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH points_table AS (
  SELECT
  	*, 
  	CASE 
  		WHEN product_name = 'sushi' THEN price * 20
  		ELSE price * 10
  	END AS points_not_member, 
	price * 20 AS points_member 
  FROM dannys_diner.menu
),
purchases_points AS (
  SELECT 
  	sales.customer_id, 
  	sales.order_date, 
  	members.join_date, 
  	points_table.points_not_member, 
  	points_table.points_member,
      CASE
          WHEN join_date IS NULL THEN points_not_member
          WHEN sales.order_date < members.join_date THEN points_not_member
          WHEN sales.order_date < members.join_date + INTERVAL '7 day' THEN points_member
          ELSE points_not_member
      END as final_points
  FROM dannys_diner.sales
  JOIN points_table
      ON points_table.product_id = sales.product_id
  JOIN dannys_diner.members
      ON members.customer_id = sales.customer_id
  --ORDER BY sales.customer_id, sales.order_date
)
SELECT 
	customer_id, 
    SUM(final_points) as total_points
FROM purchases_points
WHERE EXTRACT(MONTH FROM order_date) = 1
GROUP BY 1
ORDER BY 1
;