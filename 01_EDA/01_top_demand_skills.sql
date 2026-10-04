/*
Scan the DB first 
Using inforamtion Schema
*/
SELECT 
    table_name, column_name, data_type 
FROM information_schema.columns;

-- General overview

SELECT 
    table_name, column_name, data_type 
FROM information_schema.table;

SELECT
    * 
FROM job_postings_fact AS jpf
INNER JOIN ski