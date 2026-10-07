-- DA-02 SQL for Data Analytics
-- Report part 1: Data quality profile (videos V04 to V11, plus Q30 from V14)
-- Run one query at a time: select it, then press F5.

-- Q1: What does one sale line look like?
SELECT *
FROM invoice_lines
LIMIT 10;

-- Q2: Just the columns we need, with clearer names
SELECT invoice_no,
       stock_code,
       quantity   AS qty,
       unit_price AS price_gbp
FROM invoice_lines
LIMIT 10;

-- Q3: A quick look at the other tables
SELECT * FROM invoices  LIMIT 5;
SELECT * FROM customers LIMIT 5;
SELECT * FROM products  LIMIT 5;

-- Q4: Lines with a negative quantity
SELECT *
FROM invoice_lines
WHERE quantity < 0;

-- Q5: Negative lines with a zero price
SELECT *
FROM invoice_lines
WHERE quantity < 0
  AND unit_price = 0;

-- Q6: Lines with a negative price
SELECT *
FROM invoice_lines
WHERE unit_price < 0;

-- Q7: Expensive postage or manual lines (wrong, then right)
SELECT *
FROM invoice_lines
WHERE unit_price > 1000 AND stock_code = 'POST' OR stock_code = 'M';

SELECT *
FROM invoice_lines
WHERE unit_price > 1000 AND (stock_code = 'POST' OR stock_code = 'M');

-- Q8: Cancelled invoices (number starts with C)
SELECT *
FROM invoices
WHERE invoice_no LIKE 'C%';

-- Q9: Anything with "postage" in the name, any case
SELECT *
FROM products
WHERE description ILIKE '%postage%';

-- Q10: Stock codes that are not products
SELECT *
FROM products
WHERE stock_code !~ '^[0-9]{5}';

-- Q11: A few of them by name
SELECT *
FROM products
WHERE stock_code IN ('POST', 'DOT', 'M', 'BANK CHARGES');

-- Q12: The BETWEEN trap with dates (wrong, then right)
SELECT *
FROM invoices
WHERE invoice_date BETWEEN '2011-12-01' AND '2011-12-09';

SELECT *
FROM invoices
WHERE invoice_date >= '2011-12-01'
  AND invoice_date <  '2011-12-10';

-- Q13: Invoices with no customer
SELECT *
FROM invoices
WHERE customer_id IS NULL;

-- The mistake everyone makes once: returns nothing
SELECT *
FROM invoices
WHERE customer_id = NULL;

-- Q14: Products with no description
SELECT stock_code,
       COALESCE(description, '(no description)') AS description
FROM products
WHERE description IS NULL;

-- Q15: Which countries do customers come from?
SELECT DISTINCT country
FROM customers
ORDER BY country;

-- Q16: The ten biggest lines by quantity
SELECT *
FROM invoice_lines
ORDER BY quantity DESC
LIMIT 10;

-- Q17: ...and the most negative
SELECT *
FROM invoice_lines
ORDER BY quantity ASC
LIMIT 5;

-- Q18: When did those two happen?
SELECT *
FROM invoices
WHERE invoice_no IN ('581483', 'C581484');

-- Q19: The most valuable lines
SELECT invoice_no,
       stock_code,
       quantity,
       unit_price,
       quantity * unit_price AS line_total
FROM invoice_lines
ORDER BY line_total DESC
LIMIT 10;

-- Q20: The division trap
SELECT 5 / 2              AS whole_numbers,
       5 / 2.0            AS one_decimal,
       5::numeric / 2     AS converted_first,
       ROUND(10 / 3.0, 2) AS rounded;

-- Report part 1 (continued): the data in numbers
-- Q21: Size of the lines table
SELECT COUNT(*)                   AS total_lines,
       COUNT(DISTINCT invoice_no) AS invoices,
       COUNT(DISTINCT stock_code) AS stock_codes,
       SUM(quantity)              AS units,
       MIN(unit_price)            AS lowest_price,
       MAX(unit_price)            AS highest_price
FROM invoice_lines;

-- Q22: Dates and customers
SELECT COUNT(*)                    AS invoices,
       COUNT(customer_id)          AS with_customer,
       COUNT(DISTINCT customer_id) AS customers,
       MIN(invoice_date)           AS first_invoice,
       MAX(invoice_date)           AS last_invoice
FROM invoices;

-- Q23: The division trap again
SELECT COUNT(*) FILTER (WHERE customer_id IS NULL) / COUNT(*) AS share_no_customer
FROM invoices;

-- Q24: How big is each invoice problem?
SELECT COUNT(*)                                     AS total_invoices,
       COUNT(*) FILTER (WHERE invoice_no LIKE 'C%') AS cancelled,
       COUNT(*) FILTER (WHERE customer_id IS NULL)  AS no_customer,
       ROUND(100.0 * COUNT(*) FILTER (WHERE invoice_no LIKE 'C%') / COUNT(*), 1) AS pct_cancelled,
       ROUND(100.0 * COUNT(*) FILTER (WHERE customer_id IS NULL)  / COUNT(*), 1) AS pct_no_customer
FROM invoices;

-- Q25: How big is each line problem?
SELECT COUNT(*)                                           AS total_lines,
       COUNT(*) FILTER (WHERE stock_code !~ '^[0-9]{5}') AS non_product_lines,
       COUNT(*) FILTER (WHERE unit_price = 0)             AS zero_price_lines,
       COUNT(*) FILTER (WHERE quantity < 0)               AS negative_qty_lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE stock_code !~ '^[0-9]{5}') / COUNT(*), 1) AS pct_non_product
FROM invoice_lines;

-- Q30: Exact duplicate lines (added in V14)
SELECT invoice_no, stock_code, quantity, unit_price,
       COUNT(*) AS copies
FROM invoice_lines
GROUP BY invoice_no, stock_code, quantity, unit_price
HAVING COUNT(*) > 1
ORDER BY copies DESC;
