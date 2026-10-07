-- DA-02 SQL for Data Analytics: setup script
-- Creates the four course tables and loads them from CSV.
-- Data: Online Retail II by Daqing Chen, UCI Machine Learning Repository, CC BY 4.0.
-- Restructured into four tables for this course.
--
-- BEFORE YOU RUN THIS
-- Mac version: put the da02_data folder in /Users/Shared

DROP TABLE IF EXISTS invoice_lines, invoices, products, customers;

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    country      TEXT NOT NULL
);

CREATE TABLE products (
    stock_code   TEXT PRIMARY KEY,
    description  TEXT
);

CREATE TABLE invoices (
    invoice_no    TEXT PRIMARY KEY,
    invoice_date  TIMESTAMP NOT NULL,
    customer_id   INTEGER REFERENCES customers (customer_id)
);

CREATE TABLE invoice_lines (
    line_id      INTEGER PRIMARY KEY,
    invoice_no   TEXT NOT NULL REFERENCES invoices (invoice_no),
    stock_code   TEXT NOT NULL REFERENCES products (stock_code),
    quantity     INTEGER NOT NULL,
    unit_price   NUMERIC NOT NULL
);

COPY customers     FROM '/Users/Shared/da02_data/customers.csv'     WITH (FORMAT csv, HEADER true);
COPY products      FROM '/Users/Shared/da02_data/products.csv'      WITH (FORMAT csv, HEADER true);
COPY invoices      FROM '/Users/Shared/da02_data/invoices.csv'      WITH (FORMAT csv, HEADER true);
COPY invoice_lines FROM '/Users/Shared/da02_data/invoice_lines.csv' WITH (FORMAT csv, HEADER true);

-- Check: should return 5942, 5305, 53628, 1044848
SELECT (SELECT COUNT(*) FROM customers)     AS customers,
       (SELECT COUNT(*) FROM products)      AS products,
       (SELECT COUNT(*) FROM invoices)      AS invoices,
       (SELECT COUNT(*) FROM invoice_lines) AS invoice_lines;
