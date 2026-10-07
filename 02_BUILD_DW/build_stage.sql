--step 1 create star schema table
.read 01_create_tables_dw.sql

-- steo 2 load the data from csv file 
. read 02_load_schema.sql