-- Step 1: Create star schema table
.read 01_create_tables_dw.sql 
SELECT '=== Create table structure finish ===' AS status;

-- Step 2: Load the data from CSV file 
.read 02_load_schema.sql
SELECT '=== Load Schema finish ===' AS status;

-- Step 3: Mart - Create flat mart (denormalized table)
.read 03_create_flat_mart.sql
SELECT '=== Load flat mart finish ===' AS status;

-- Step 4: Mart - Create skills demand mart
.read 04_create_skills_mart.sql
SELECT '=== Load skills finish ===' AS status;

-- Step 5: Mart - Create priority mart
.read 05_create_priority_mart.sql
SELECT '=== Create priority finish ===' AS status;

-- Step 6: Mart - Update priority mart
.read 06_update_priority_mart.sql
SELECT '=== Update priority mart finish ===' AS status;

-- Step 7: Mart - Create company prospecting mart
.read 07_create_company_mart.sql
SELECT '=== Create company mart finish ===' AS status;

-- Final verification
SELECT '=== Pipeline Build Complete ===' AS status;
