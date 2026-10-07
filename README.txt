DA-02 SQL for Data Analytics: course files

CONTENTS
  create_tables.sql   creates the four tables in Supabase (video V02); its last query checks the load (V03)
  da02_data/          the four tables as CSV files, to import in the Supabase Table Editor (V03)
  da02_data/invoice_lines_parts/
                      the big invoice_lines file split into 4 parts of 261,212 lines,
                      in case the single 29 MB file is too slow to import in your browser
  solutions/          the finished report: one .sql file per report part, plus the findings memo
  local_install/      only if you install PostgreSQL on your own computer instead of using Supabase

SETUP ON SUPABASE (videos V02 and V03)
  1. Create a free project at supabase.com.
  2. SQL Editor: run create_tables.sql (S1 to S5).
  3. Table Editor: import the CSVs in this order: customers, products, invoices, invoice_lines.
  4. SQL Editor: run S6. It should return 5942, 5305, 53628, 1044848.

DATA CREDIT
  Online Retail II by Daqing Chen, UCI Machine Learning Repository.
  https://archive.ics.uci.edu/dataset/502/online+retail+ii
  Licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
  Changes: the two yearly sheets were combined and their 9-day overlap removed once,
  and the data was split into four tables (customers, products, invoices, invoice_lines).
