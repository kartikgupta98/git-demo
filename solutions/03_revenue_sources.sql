-- DA-02 SQL for Data Analytics
-- Report part 3: Where revenue comes from (videos V16 to V21, plus V27)
-- Revenue = net revenue: product lines, price above zero, cancellations included

-- Q34: Top 10 products by revenue, with names
SELECT l.stock_code,
       p.description,
       ROUND(SUM(l.quantity * l.unit_price), 2) AS revenue
FROM invoice_lines AS l
INNER JOIN products AS p
        ON l.stock_code = p.stock_code
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0
GROUP BY l.stock_code, p.description
ORDER BY revenue DESC
LIMIT 10;

-- Q35: Revenue by country
SELECT c.country,
       ROUND(SUM(l.quantity * l.unit_price), 2) AS revenue
FROM invoice_lines AS l
INNER JOIN invoices  AS i ON l.invoice_no  = i.invoice_no
INNER JOIN customers AS c ON i.customer_id = c.customer_id
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0
GROUP BY c.country
ORDER BY revenue DESC;

-- Q36: Does it add up?
SELECT ROUND(SUM(l.quantity * l.unit_price), 2) AS revenue
FROM invoice_lines AS l
INNER JOIN invoices  AS i ON l.invoice_no  = i.invoice_no
INNER JOIN customers AS c ON i.customer_id = c.customer_id
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0;

-- Q37: Revenue by country, keeping unknown customers
SELECT COALESCE(c.country, 'Unknown') AS country,
       ROUND(SUM(l.quantity * l.unit_price), 2) AS revenue
FROM invoice_lines AS l
INNER JOIN invoices  AS i ON l.invoice_no  = i.invoice_no
LEFT JOIN  customers AS c ON i.customer_id = c.customer_id
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0
GROUP BY COALESCE(c.country, 'Unknown')
ORDER BY revenue DESC;

-- Q38: What were the non-product lines worth?
SELECT CASE
         WHEN stock_code ~ '^[0-9]{5}'                               THEN 'Product'
         WHEN stock_code IN ('POST', 'DOT', 'C2')                     THEN 'Postage and carriage'
         WHEN stock_code IN ('M', 'm', 'ADJUST', 'ADJUST2', 'B', 'D') THEN 'Manual, adjustment or discount'
         WHEN stock_code IN ('AMAZONFEE', 'BANK CHARGES', 'CRUK')     THEN 'Fees and commission'
         ELSE 'Other'
       END AS line_type,
       COUNT(*) AS lines,
       ROUND(SUM(quantity * unit_price), 2) AS net_value
FROM invoice_lines
GROUP BY line_type
ORDER BY net_value DESC;

-- Q39: UK, international, or unknown?
SELECT CASE
         WHEN c.country = 'United Kingdom' THEN 'UK'
         WHEN c.country IS NULL            THEN 'Unknown customer'
         ELSE 'International'
       END AS market,
       ROUND(SUM(l.quantity * l.unit_price), 2) AS revenue
FROM invoice_lines AS l
INNER JOIN invoices  AS i ON l.invoice_no  = i.invoice_no
LEFT JOIN  customers AS c ON i.customer_id = c.customer_id
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0
GROUP BY market
ORDER BY revenue DESC;

-- Q40: One place for our cleaning rules
-- (In the video this is CREATE VIEW. OR REPLACE lets you rerun it safely.)
CREATE OR REPLACE VIEW clean_sales AS
SELECT l.line_id,
       l.invoice_no,
       i.invoice_date,
       i.customer_id,
       COALESCE(c.country, 'Unknown') AS country,
       l.stock_code,
       p.description,
       l.quantity,
       l.unit_price,
       l.quantity * l.unit_price      AS line_total,
       l.invoice_no LIKE 'C%'         AS is_cancellation
FROM invoice_lines AS l
INNER JOIN invoices  AS i ON l.invoice_no  = i.invoice_no
INNER JOIN products  AS p ON l.stock_code  = p.stock_code
LEFT JOIN  customers AS c ON i.customer_id = c.customer_id
WHERE l.stock_code ~ '^[0-9]{5}'
  AND l.unit_price > 0;

-- Q41: Use it like a table
SELECT *
FROM clean_sales
ORDER BY line_id
LIMIT 5;

-- Q42: The headline KPIs, now in one short query
SELECT COUNT(*)                                                       AS lines,
       ROUND(SUM(line_total), 2)                                      AS net_revenue,
       COUNT(DISTINCT invoice_no)  FILTER (WHERE NOT is_cancellation) AS orders,
       COUNT(DISTINCT customer_id) FILTER (WHERE NOT is_cancellation) AS customers,
       ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation), 2) AS avg_order_value
FROM clean_sales;

-- Q43: Each country's share of revenue
SELECT country,
       ROUND(SUM(line_total), 2) AS revenue,
       ROUND(100 * SUM(line_total) / (SELECT SUM(line_total) FROM clean_sales), 1) AS pct_of_total
FROM clean_sales
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

-- Q44: Where are the customers who bought our best-seller?
SELECT country,
       COUNT(*) AS customers
FROM customers
WHERE customer_id IN (SELECT customer_id
                      FROM clean_sales
                      WHERE stock_code = '22423'
                        AND NOT is_cancellation)
GROUP BY country
ORDER BY customers DESC
LIMIT 5;

-- Q54: Top 3 products in each of the four biggest international markets (V27)
WITH product_country AS (
    SELECT country,
           description,
           SUM(line_total) AS revenue
    FROM clean_sales
    WHERE country IN ('EIRE', 'Netherlands', 'Germany', 'France')
    GROUP BY country, description
),
ranked AS (
    SELECT country,
           description,
           ROUND(revenue, 2) AS revenue,
           RANK() OVER (PARTITION BY country ORDER BY revenue DESC) AS rnk
    FROM product_country
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY country, rnk;

-- Q55: The biggest customer in each country, and their share of it (V27)
WITH customer_country AS (
    SELECT country,
           customer_id,
           SUM(line_total) AS revenue
    FROM clean_sales
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
ranked AS (
    SELECT country,
           customer_id,
           ROUND(revenue, 2) AS revenue,
           ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY country), 1) AS pct_of_country,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY revenue DESC)      AS rn
    FROM customer_country
)
SELECT country, customer_id, revenue, pct_of_country
FROM ranked
WHERE rn = 1
ORDER BY revenue DESC
LIMIT 5;
