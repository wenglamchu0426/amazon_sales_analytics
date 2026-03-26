-- Data used: fictitious Amazon sales dataset (columns: Order ID, Date, Product, Category, Price, Quantity, Total Sales, Customer Name, Customer Location, Payment Method, Status). 

RENAME TABLE `amazon_sales_data 2025` TO sales;
SELECT * FROM sales;

-- customize columns and set primary key
ALTER TABLE sales
CHANGE `Order ID` order_id VARCHAR(7),
CHANGE `Date` `date` VARCHAR(20),
CHANGE `Product` product VARCHAR(20),
CHANGE `Category` category VARCHAR(20),
CHANGE `Price` price DECIMAL(10,2),
CHANGE `Quantity` quantity INT,
CHANGE `Total Sales` total_sales DECIMAL(20),
CHANGE `Customer Name` customer_name VARCHAR(100),
CHANGE `Customer Location` customer_location VARCHAR(50),
CHANGE `Payment Method` payment_method VARCHAR(50),
CHANGE `Status` `status` VARCHAR(20),
ADD PRIMARY KEY (order_id);

-- standardize date
UPDATE sales 
SET `date` = STR_TO_DATE(REPLACE(`Date`, '/', '-'), '%d-%m-%y');

-- drop columns that I want to modify 
ALTER TABLE sales 
DROP COLUMN category,
DROP COLUMN total_sales;

-- categorize products into larger categories
ALTER TABLE sales
ADD COLUMN category VARCHAR(20) AFTER product;

UPDATE sales
SET category = CASE
	When product LIKE '%phone%' OR product LIKE '%smart%' OR product = 'Laptop' THEN 'Electronics'
    WHEN product LIKE '%shirt%' OR product LIKE '%jeans' THEN 'Clothing'
    WHEN product LIKE '%shoe%' THEN 'Footwear'
    WHEN product LIKE '%book%' THEN 'Books'
    WHEN  product LIKE '%machine%' OR product = 'refrigerator' THEN 'Appliances'
    ELSE category
END;

-- calculate order totals (price * quantity + sales tax)
ALTER TABLE sales
ADD COLUMN sales_tax DECIMAL(10,2) AFTER quantity;

ALTER TABlE sales
ADD COLUMN order_total DECIMAL(10,2) AFTER sales_tax;

UPDATE sales 
SET sales_tax = CASE
	WHEN customer_location IN ('Chicago', 'Seattle') THEN 0.10
    WHEN customer_location IN ('Los Angeles', 'New York', 'San Francisco') THEN 0.09
    WHEN customer_location IN ('Houston') THEN 0.08
    WHEN customer_location IN ('Dallas', 'Denver', 'Miami') THEN 0.07
    WHEN customer_location IN ('Boston') THEN 0.06
    ELSE 0.06
END;

UPDATE sales
SET order_total = (price * quantity) * (1 + sales_tax);

-- create a separate table for customer info, and link the two tables
DROP TABLE customers;

CREATE TABLE customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100),
    location VARCHAR(100),
    payment_method VARCHAR(20)
);

INSERT INTO customers(full_name, location, payment_method)
SELECT DISTINCT customer_name, customer_location, payment_method FROM SALES;

SELECT * FROM customers;

ALTER TABLE sales 
DROP COLUMN customer_location,
DROP COLUMN payment_method;

ALTER TABLE customers
ADD COLUMN first_name VARCHAR(20) AFTER full_name,
ADD COLUMN last_name VARCHAR(20) AFTER first_name;

UPDATE customers
SET 
  first_name = SUBSTRING_INDEX(full_name, ' ', 1),
  last_name = SUBSTRING_INDEX(full_name, ' ', -1);

ALTER TABLE sales
ADD COLUMN customer_id INT;

UPDATE sales
JOIN customers
ON sales.customer_name = customers.full_name SET sales.customer_id = customers.customer_id;

ALTER TABLE sales 
DROP COLUMN customer_name;

-- find total number of orders
SELECT COUNT(order_id) FROM sales;

-- find out how many orders are in each product category
SELECT category, COUNT(category) AS number_of_orders FROM sales 
GROUP BY(category) 
ORDER BY COUNT(category) DESC;

-- find product categories with more than 50 orders
SELECT category, COUNT(order_id) AS total_orders FROM sales
GROUP BY category HAVING COUNT(order_id) > 50 
ORDER BY total_orders DESC;

-- find total sales across all orders
SELECT SUM(order_total) FROM sales;

-- find the average quantity of each order
SELECT AVG(quantity) FROM sales;

-- find total sales per month
SELECT DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(order_total) as total_sales FROM sales
GROUP BY `month` 
ORDER BY `month`;

-- find total_sales by category AND month
SELECT category, DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(order_total) AS total_sales FROM sales
GROUP BY category, `month`
ORDER BY category, `month`;

-- find all electronics orders placed in Feburary
SELECT * FROM sales WHERE `date` LIKE '____-02___' AND category = 'Electronics';

-- find the largest and smallest orders in terms of price
SELECT MAX(order_total) AS largest_order, MIN(order_total) AS smallest_order FROM sales;

-- find all orders that cost more than $1000
SELECT * FROM sales WHERE order_total > 1000 
ORDER BY order_total DESC;

-- find average order value per customer 
SELECT customers.full_name, AVG(sales.order_total) AS avg_order_value FROM customers
JOIN sales ON customers.customer_id = sales.customer_id
GROUP BY customers.full_name
ORDER BY avg_order_value DESC;

-- Find how many orders each customer has placed 
SELECT customers.full_name, COUNT(sales.order_id) AS total_orders FROM customers
JOIN sales ON customers.customer_id = sales.customer_id
GROUP BY customers.full_name
ORDER BY total_orders DESC;

-- find the top 5 customers by total spending 
SELECT customers.full_name, SUM(sales.order_total) AS total_spent FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
GROUP BY customers.full_name 
ORDER BY total_spent DESC
LIMIT 5;

-- find all customers that placed 20 orders or less
SELECT * FROM customers WHERE customer_id IN (
	SELECT customer_id FROM sales 
    GROUP BY customer_id HAVING COUNT(order_id) <= 20
);

-- find the order status of Emma Clark's most recent order
SELECT status FROM sales WHERE customer_id IN (
	SELECT customer_id FROM customers WHERE full_name = 'Emma Clark'
)
ORDER BY `date` desc
LIMIT 1;


