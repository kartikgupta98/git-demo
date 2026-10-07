-- DA-02 SQL for Data Analytics
-- Report part 2: Headline KPIs (videos V12 to V15)
-- A sale = a product line, price above zero, not a cancellation

-- Q26: Gross sales, orders, average order value, units
SELECT ROUND(SUM(quantity * unit_price), 2)                              AS gross_sales,
       COUNT(DISTINCT invoice_no)                                        AS orders,
       ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value,
       SUM(quantity)                                                     AS units
FROM invoice_lines
WHERE stock_code ~ '^[0-9]{5}'
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';

-- Q27: Top 10 products by gross sales
SELECT stock_code,
       ROUND(SUM(quantity * unit_price), 2) AS gross_sales
FROM invoice_lines
WHERE stock_code ~ '^[0-9]{5}'
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%'
GROUP BY stock_code
ORDER BY gross_sales DESC
LIMIT 10;

-- Q28: Customers with the most orders
SELECT customer_id,
       COUNT(*) AS orders
FROM invoices
WHERE invoice_no NOT LIKE 'C%'
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY orders DESC
LIMIT 10;

-- Q29: Products with more than £100,000 of gross sales
SELECT stock_code,
       ROUND(SUM(quantity * unit_price), 2) AS gross_sales
FROM invoice_lines
WHERE stock_code ~ '^[0-9]{5}'
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%'
GROUP BY stock_code
HAVING SUM(quantity * unit_price) > 100000
ORDER BY gross_sales DESC;

-- Q31: Gross sales, cancellations and net revenue
-- A revenue line = a product line with a price above zero
SELECT ROUND(SUM(quantity * unit_price) FILTER (WHERE invoice_no NOT LIKE 'C%'), 2) AS gross_sales,
       ROUND(-SUM(quantity * unit_price) FILTER (WHERE invoice_no LIKE 'C%'), 2)    AS cancelled,
       ROUND(SUM(quantity * unit_price), 2)                                           AS net_revenue
FROM invoice_lines
WHERE stock_code ~ '^[0-9]{5}'
  AND unit_price > 0;

-- Q32: Cancellation rate by value
SELECT ROUND(100.0 * -SUM(quantity * unit_price) FILTER (WHERE invoice_no LIKE 'C%')
                   / SUM(quantity * unit_price) FILTER (WHERE invoice_no NOT LIKE 'C%'), 1) AS pct_cancelled
FROM invoice_lines
WHERE stock_code ~ '^[0-9]{5}'
  AND unit_price > 0;

-- Q33: The most cancelled products by value
SELECT stock_code,
       ROUND(-SUM(quantity * unit_price), 2) AS cancelled_value
FROM invoice_lines
WHERE invoice_no LIKE 'C%'
  AND stock_code ~ '^[0-9]{5}'
GROUP BY stock_code
ORDER BY cancelled_value DESC
LIMIT 5;
