-- DA-02 SQL for Data Analytics
-- Report part 5: Customers (videos V22, V29, V30)

-- Q45: One order or repeat buyer?
WITH customer_summary AS (
    SELECT customer_id,
           COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation) AS orders,
           SUM(line_total) AS revenue
    FROM clean_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN 'One order' ELSE 'Repeat buyer' END AS customer_type,
       COUNT(*)               AS customers,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM customer_summary WHERE orders > 0), 1) AS pct_of_revenue
FROM customer_summary
WHERE orders > 0
GROUP BY customer_type
ORDER BY revenue DESC;

-- Q57: Retention by starting month (2010 cohorts)
WITH activity AS (
    SELECT DISTINCT customer_id,
           DATE_TRUNC('month', invoice_date)::date AS active_month
    FROM clean_sales
    WHERE customer_id IS NOT NULL
      AND NOT is_cancellation
),
cohorts AS (
    SELECT customer_id,
           active_month,
           MIN(active_month) OVER (PARTITION BY customer_id) AS cohort_month
    FROM activity
),
offsets AS (
    SELECT cohort_month,
           customer_id,
           (EXTRACT(YEAR FROM active_month) - EXTRACT(YEAR FROM cohort_month)) * 12
         + (EXTRACT(MONTH FROM active_month) - EXTRACT(MONTH FROM cohort_month)) AS month_number
    FROM cohorts
)
SELECT cohort_month,
       COUNT(*) FILTER (WHERE month_number = 0) AS new_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_number = 1)  / COUNT(*) FILTER (WHERE month_number = 0), 1) AS month_1,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_number = 3)  / COUNT(*) FILTER (WHERE month_number = 0), 1) AS month_3,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_number = 6)  / COUNT(*) FILTER (WHERE month_number = 0), 1) AS month_6,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_number = 12) / COUNT(*) FILTER (WHERE month_number = 0), 1) AS month_12
FROM offsets
WHERE cohort_month >= '2010-01-01'
  AND cohort_month <  '2010-12-01'
GROUP BY cohort_month
ORDER BY cohort_month;

-- Q58: RFM segments
-- Recency is measured from 10 December 2011, the day after the data ends.
WITH customer_rfm AS (
    SELECT customer_id,
           '2011-12-10'::date - MAX(invoice_date) FILTER (WHERE NOT is_cancellation)::date AS recency_days,
           COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation)                   AS frequency,
           SUM(line_total)                                                                  AS monetary
    FROM clean_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation) > 0
       AND SUM(line_total) > 0
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC, customer_id) AS r,
           NTILE(5) OVER (ORDER BY frequency, customer_id)         AS f,
           NTILE(5) OVER (ORDER BY monetary, customer_id)          AS m
    FROM customer_rfm
),
segmented AS (
    SELECT *,
           CASE
               WHEN r >= 4 AND f >= 4 THEN 'Champions'
               WHEN r >= 3 AND f >= 3 THEN 'Loyal'
               WHEN r >= 4            THEN 'New or promising'
               WHEN r <= 2 AND f >= 3 THEN 'At risk'
               WHEN r <= 2            THEN 'Lost'
               ELSE 'Needs attention'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                 AS customers,
       ROUND(AVG(recency_days)) AS avg_days_since_order,
       ROUND(AVG(frequency), 1) AS avg_orders,
       ROUND(SUM(monetary), 2)  AS revenue,
       ROUND(100 * SUM(monetary) / (SELECT SUM(monetary) FROM customer_rfm), 1) AS pct_of_revenue
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- Q59: The ten most valuable At risk customers: the win-back list
WITH customer_rfm AS (
    SELECT customer_id,
           '2011-12-10'::date - MAX(invoice_date) FILTER (WHERE NOT is_cancellation)::date AS recency_days,
           COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation)                   AS frequency,
           SUM(line_total)                                                                  AS monetary
    FROM clean_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancellation) > 0
       AND SUM(line_total) > 0
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC, customer_id) AS r,
           NTILE(5) OVER (ORDER BY frequency, customer_id)         AS f
    FROM customer_rfm
)
SELECT s.customer_id,
       c.country,
       s.recency_days,
       s.frequency,
       ROUND(s.monetary, 2) AS monetary
FROM scored AS s
INNER JOIN customers AS c ON s.customer_id = c.customer_id
WHERE s.r <= 2
  AND s.f >= 3
ORDER BY s.monetary DESC
LIMIT 10;
