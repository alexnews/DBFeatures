-- Alex Kargin bitbucket.org/alexnews/dbfeatures/

### Description: Found the Storage Space for Databases

The `system_StorageSpace` stored procedure provides a detailed breakdown of the storage space used by databases and their respective tables. This tool helps database administrators monitor storage utilization, identify bottlenecks, and plan capacity effectively.

---

### Key Features
1. **Storage Metrics**:
   - Displays the following metrics for each database and its tables:
     - **Data Size**: The total size of data stored in tables.
     - **Index Size**: The total size of indexes.
     - **Table Size**: The combined size of data and indexes.

2. **Grouping and Rollup**:
   - Includes aggregated storage information for:
     - Individual tables grouped by database and storage engine.
     - Total storage usage across all databases.

3. **User-Friendly Formatting**:
   - Sizes are displayed in human-readable units (e.g., KB, MB, GB) for easier interpretation.
   - Data is formatted and aligned for clarity.

4. **System Schemas Excluded**:
   - Ignores system schemas such as `mysql`, `information_schema`, and `performance_schema` to focus on user-defined databases.

5. **Automatic Sorting**:
   - Results are sorted by database name, schema, and engine for easy navigation.

---

### How It Works

1. **Data Aggregation**:
   - Retrieves storage statistics from the `information_schema.tables` table.
   - Calculates the sum of `data_length` (data size) and `index_length` (index size).

2. **Schema and Engine Details**:
   - Groups storage data by schema and table engine, providing insights into storage distribution across different engines (e.g., InnoDB, MyISAM).

3. **Formatted Output**:
   - Converts raw size values into readable formats (KB, MB, GB) using a power of 1024.

4. **Summary Row**:
   - Includes a rollup summary that aggregates storage usage for all databases.

---

### Usage

To execute the procedure, simply call it without parameters:
```sql
CALL system_StorageSpace();
```

---

### Example Output

The procedure generates a detailed report like this:

| **Statistic**               | **Data Size**  | **Index Size**  | **Table Size**  |
|------------------------------|----------------|-----------------|-----------------|
| Storage for All Databases    |     15.345 GB  |      5.234 GB   |     20.579 GB   |
| InnoDB Tables for mydb       |      1.234 GB  |      0.456 GB   |      1.690 GB   |
| InnoDB Tables for testdb     |      0.789 GB  |      0.123 GB   |      0.912 GB   |

---

### Use Cases

1. **Capacity Planning**:
   - Identify which databases or tables are consuming the most storage.

2. **Performance Optimization**:
   - Spot tables with large indexes that may require tuning.

3. **Storage Monitoring**:
   - Track total storage utilization across multiple databases.

4. **Database Auditing**:
   - Analyze storage distribution by schema and engine.

---

### Advantages
- **Comprehensive View**:
   - Aggregates data at the schema and engine levels.
- **Readable Output**:
   - Human-readable size formats simplify analysis.
- **Efficient Analysis**:
   - Rolls up data to provide a summary for all databases.

---



DROP PROCEDURE IF EXISTS `system_StorageSpace`;

DELIMITER ;;
CREATE PROCEDURE `system_StorageSpace`()

BEGIN

    SELECT
        Statistic
      , DataSize  "Data Size"
      , IndexSize "Index Size"
      , TableSize "Table Size"
    FROM
        (SELECT
             IF(ISNULL(table_schema)=1,10, 0)                                               schema_score
           ,
             IF(ISNULL(engine)=1,10, 0)                                                     engine_score
           , IF(ISNULL(table_schema)=1, 'ZZZZZZZZZZZZZZZZ', table_schema)                   schemaname
           ,
             IF(ISNULL(B.table_schema)+ISNULL(B.engine)=2, "Storage for All Databases",
                                                           IF(ISNULL(B.table_schema)+ISNULL(B.engine)=1,
                                                                   CONCAT("Storage for ", B.table_schema),
                                                                   CONCAT(B.engine, " Tables for ",
                                                                          B.table_schema))) Statistic
           ,
             CONCAT(LPAD(REPLACE(FORMAT(B.DSize / POWER(1024, pw), 3), ',', ''), 17, ' '), ' ',
                    SUBSTR(' KMGTP', pw + 1, 1), 'B')                                       DataSize
           ,
             CONCAT(LPAD(REPLACE(FORMAT(B.ISize / POWER(1024, pw), 3), ',', ''), 17, ' '), ' ',
                    SUBSTR(' KMGTP', pw + 1, 1), 'B')                                       IndexSize
           ,
             CONCAT(LPAD(REPLACE(FORMAT(B.TSize / POWER(1024, pw), 3), ',', ''), 17, ' '), ' ',
                    SUBSTR(' KMGTP', pw + 1, 1), 'B')                                       TableSize
         FROM
             (SELECT
                  table_schema
                , engine
                ,
                  SUM(data_length)                DSize
                , SUM(index_length)               ISize
                , SUM(data_length + index_length) TSize
              FROM
                  information_schema.tables
              WHERE
                      table_schema NOT IN
                      ('mysql', 'information_schema', 'performance_schema')
                AND   engine IS NOT NULL
              GROUP BY table_schema, engine WITH ROLLUP) B
           , (SELECT 3 pw) A) AA
    ORDER BY schemaname, schema_score, engine_score
    ;

END;;
DELIMITER ;

CALL system_StorageSpace();