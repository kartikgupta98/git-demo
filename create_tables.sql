-- DA-02 SQL for Data Analytics: create the four tables (video V02)
-- Run this in the Supabase SQL Editor. Then import the CSVs in video V03.
-- Data: Online Retail II by Daqing Chen, UCI Machine Learning Repository, CC BY 4.0.

-- S1: Customers: one row per customer
CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    country      TEXT NOT NULL
);

-- S2: Products: one row per stock code
CREATE TABLE products (
    stock_code   TEXT PRIMARY KEY,
    description  TEXT
);

-- S3: Invoices: one row per invoice; customer_id links to customers
CREATE TABLE invoices (
    invoice_no    TEXT PRIMARY KEY,
    invoice_date  TIMESTAMP NOT NULL,
    customer_id   INTEGER REFERENCES customers (customer_id)
);

-- S4: Invoice lines: one product on one invoice
CREATE TABLE invoice_lines (
    line_id      INTEGER PRIMARY KEY,
    invoice_no   TEXT NOT NULL REFERENCES invoices (invoice_no),
    stock_code   TEXT NOT NULL REFERENCES products (stock_code),
    quantity     INTEGER NOT NULL,
    unit_price   NUMERIC NOT NULL
);

-- S5: Keep the tables private to the SQL Editor
ALTER TABLE customers     ENABLE ROW LEVEL SECURITY;
ALTER TABLE products      ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices      ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_lines ENABLE ROW LEVEL SECURITY;

-- S6: Run after importing the CSVs (video V03). Expect 5942 | 5305 | 53628 | 1044848
SELECT (SELECT COUNT(*) FROM customers)     AS customers,
       (SELECT COUNT(*) FROM products)      AS products,
       (SELECT COUNT(*) FROM invoices)      AS invoices,
       (SELECT COUNT(*) FROM invoice_lines) AS invoice_lines;
