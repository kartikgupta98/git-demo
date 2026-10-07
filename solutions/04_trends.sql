-- DA-02 SQL for Data Analytics
-- Report part 4: Trends (videos V23 to V25, plus V26 and V28)

-- Q46: Taking one timestamp apart
SELECT invoice_date,
       invoice_date::date                AS just_the_date,
       EXTRACT(YEAR FROM invoice_date)   AS year,
       EXTRACT(MONTH FROM invoice_date)  AS month,
       EXTRACT(HOUR FROM invoice_date)   AS hour,
       DATE_TRUNC('month', invoice_date) AS month_start,
       TO_CHAR(invoice_date, 'Dy')       AS weekday
FROM invoices
WHERE invoice_no = '489434';

-- Q47: Orders and revenue by day of the week
SELECT EXTRACT(ISODOW FROM invoice_date) AS day_no,
       TO_CHAR(invoice_date, 'Dy')       AS weekday,
       COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation) AS orders,
       ROUND(SUM(line_total), 2)         AS revenue
FROM clean_sales
GROUP BY day_no, weekday
ORDER BY day_no;

-- Q48: Orders by hour of the day
SELECT EXTRACT(HOUR FROM invoice_date) AS hour,
       COUNT(DISTINCT invoice_no)      AS orders
FROM clean_sales
WHERE NOT is_cancellation
GROUP BY hour
ORDER BY hour;

-- Q49: Monthly revenue, orders and customers
SELECT DATE_TRUNC('month', invoice_date)::date AS month,
       ROUND(SUM(line_total), 2)               AS revenue,
       COUNT(DISTINCT invoice_no)  FILTER (WHERE NOT is_cancellation) AS orders,
       COUNT(DISTINCT customer_id) FILTER (WHERE NOT is_cancellation) AS customers
FROM clean_sales
GROUP BY month
ORDER BY month;

-- Q50: Each month, 2010 vs 2011
SELECT EXTRACT(MONTH FROM invoice_date) AS month_no,
       ROUND(SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2010), 0) AS revenue_2010,
       ROUND(SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2011), 0) AS revenue_2011,
       ROUND(100 * (SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2011)
                  / SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2010) - 1), 1) AS growth_pct
FROM clean_sales
WHERE invoice_date >= '2010-01-01'
  AND invoice_date <  '2011-12-01'
  AND EXTRACT(MONTH FROM invoice_date) <= 11
GROUP BY month_no
ORDER BY month_no;

-- Q51: January to November, 2010 vs 2011
SELECT ROUND(SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2010), 2) AS jan_nov_2010,
       ROUND(SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2011), 2) AS jan_nov_2011,
       ROUND(100 * (SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2011)
                  / SUM(line_total) FILTER (WHERE EXTRACT(YEAR FROM invoice_date) = 2010) - 1), 1) AS growth_pct
FROM clean_sales
WHERE invoice_date >= '2010-01-01'
  AND invoice_date <  '2011-12-01'
  AND EXTRACT(MONTH FROM invoice_date) <= 11;

-- Q52: Running total and share of all revenue (V26)
WITH monthly AS (
    SELECT DATE_TRUNC('month', invoice_date)::date AS month,
           SUM(line_total) AS revenue
    FROM clean_sales
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2)                              AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)   AS running_total,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS pct_of_all
FROM monthly
ORDER BY month;

-- Q53: Year to date, restarting each January (V26)
WITH monthly AS (
    SELECT DATE_TRUNC('month', invoice_date)::date AS month,
           SUM(line_total) AS revenue
    FROM clean_sales
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month)
                                ORDER BY month), 2) AS year_to_date
FROM monthly
ORDER BY month;

-- Q56: Month-on-month and year-on-year growth (V28)
WITH monthly AS (
    SELECT DATE_TRUNC('month', invoice_date)::date AS month,
           SUM(line_total) AS revenue
    FROM clean_sales
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2)                                                      AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2)                           AS previous_month,
       ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY month) - 1), 1)     AS mom_growth_pct,
       ROUND(100 * (revenue / LAG(revenue, 12) OVER (ORDER BY month) - 1), 1) AS yoy_growth_pct
FROM monthly
ORDER BY month;
