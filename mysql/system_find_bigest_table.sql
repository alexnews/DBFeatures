-- Alex Kargin github.com/alexnews/DBFeatures/
-- Found the biggest Table in DB

### Description: Find the Biggest Tables in a Database

This stored procedure, `system_BiggestTable`, is designed to identify and display the largest tables in a MySQL database based on their data and index sizes. It''s a handy tool for database administrators to monitor storage usage, optimize performance, or manage capacity planning.

---

### Key Features
1. **Flexible Results**:
   - Accepts a parameter (`pHowMany`) to specify how many of the largest tables should be displayed.
   - Defaults to showing the top 10 tables if no valid value is provided.

2. **Detailed Metrics**:
   - Reports the following details for each table:
     - **Schema and Table Name**: Full table identifier.
     - **Row Count**: Approximate number of rows, formatted in millions (`M`).
     - **Data Size**: The size of the data portion of the table, formatted in gigabytes (`G`).
     - **Index Size**: The size of the indexes for the table, also formatted in gigabytes (`G`).
     - **Total Size**: Combined size of data and indexes, formatted in gigabytes (`G`).
     - **Index-to-Data Ratio**: Ratio of index size to data size for understanding indexing overhead.

3. **Ordered by Size**:
   - The output is sorted in descending order by total size (data + index).

---

### How It Works

1. **Parameter Handling**:
   - Checks if `pHowMany` is valid (`>= 1`). If not, defaults to `10`.

2. **Query the Information Schema**:
   - Retrieves metadata from `information_schema.TABLES`, which stores information about all tables in the database.

3. **Calculations**:
   - Uses mathematical operations to format sizes in gigabytes (`G`) and row counts in millions (`M`).
   - Computes the total size (`data + index`) and the index-to-data ratio.

4. **Sorting and Limiting**:
   - Orders tables by total size in descending order.
   - Limits the results to the top `pHowMany` tables.

---

### Usage
To execute the procedure, call it with the desired number of results:
```sql
CALL system_BiggestTable(5);
```
- This example will list the top 5 largest tables in the database.

If no value or an invalid value is provided, the default is 10:
```sql
CALL system_BiggestTable('');
```

---

### Example Output
```
+---------------------------------------+--------+--------+-------+------------+---------+
| Table                                 | rows   | DATA   | idx   | total_size | idxfrac |
+---------------------------------------+--------+--------+-------+------------+---------+
| mydb.large_table1                     | 12.34M | 4.56G  | 1.23G | 5.79G      | 0.27    |
| mydb.large_table2                     | 10.56M | 3.89G  | 1.45G | 5.34G      | 0.37    |
| mydb.large_table3                     | 8.91M  | 2.75G  | 0.92G | 3.67G      | 0.33    |
+---------------------------------------+--------+--------+-------+------------+---------+
```

### Use Cases
1. **Capacity Monitoring**:
   - Quickly identify which tables consume the most storage.

2. **Optimization Planning**:
   - Spot tables with high index-to-data ratios (`idxfrac`) to evaluate indexing strategies.

3. **Database Maintenance**:
   - Focus maintenance efforts (e.g., archiving or partitioning) on the largest tables.

4. **Auditing**:
   - Analyze storage distribution across schemas and tables.

---

### Advantages
- **Efficient**: Leverages `information_schema` for real-time insights without impacting production data.
- **Customizable**: Adjusts the number of results dynamically.
- **Comprehensive**: Provides both size and structural metrics (e.g., index-to-data ratio).

---



DROP PROCEDURE IF EXISTS `system_BiggestTable`;

DELIMITER ;;
CREATE PROCEDURE `system_BiggestTable`(
IN pHowMany INT(10)
)

BEGIN
    IF pHowMany < 1 THEN
      SET pHowMany := 10;
    END IF;

    SELECT CONCAT(table_schema, '.', table_name),
           CONCAT(ROUND(table_rows / 1000000, 2), 'M')                                    total_rows,
           CONCAT(ROUND(data_length / ( 1024 * 1024 * 1024 ), 2), 'G')                    DATA,
           CONCAT(ROUND(index_length / ( 1024 * 1024 * 1024 ), 2), 'G')                   idx,
           CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2), 'G') total_size,
           ROUND(index_length / data_length, 2)                                           idxfrac
    FROM   information_schema.TABLES
    ORDER  BY data_length + index_length DESC
    LIMIT  pHowMany;

END;;
DELIMITER ;

CALL system_BiggestTable('');