-- Alex Kargin github.com/alexnews/dbfeatures/

### Description: Check Unindexed Tables

The `system_CheckIndex` stored procedure is designed to identify columns in tables across your MySQL database that are not indexed. This tool helps database administrators ensure that critical columns—especially those involved in queries or joins—are properly indexed to improve performance and efficiency.

---

### Key Features
1. **Flexible Input**:
   - Accepts a parameter (`pIndex`) to specify which columns (by name pattern) to check for indexing.
   - For example, you can pass `'Id'` to check if columns containing "Id" are indexed.

2. **Comprehensive Coverage**:
   - Scans all tables and columns in the database (excluding system schemas like `information_schema`, `performance_schema`, and `mysql`).

3. **Detailed Report**:
   - Provides the following information for each column:
     - **Schema Name** (`TABLE_SCHEMA`): The schema where the table is located.
     - **Table Name** (`TABLE_NAME`): The table containing the column.
     - **Column Name** (`COLUMN_NAME`): The specific column being checked.
     - **Index Status** (`Indexed`): Indicates whether the column is indexed. If not, it shows "Not indexed."

4. **Joins Metadata**:
   - Leverages `information_schema` tables to cross-check column usage and indexes:
     - **`COLUMNS`**: Retrieves metadata about all columns.
     - **`KEY_COLUMN_USAGE`**: Checks if the column is part of an index.

---

### How It Works

1. **Input Parameter (`pIndex`)**:
   - Filters columns by name using a `LIKE` query on the `COLUMN_NAME` field.
   - For example, passing `'Id'` will check all columns with names containing "Id."

2. **Join Information Schema**:
   - Joins `TABLES` and `COLUMNS` to get all column details.
   - Left joins `KEY_COLUMN_USAGE` to check for associated indexes.

3. **Unindexed Columns**:
   - Filters results to only include columns that are **not indexed**.

4. **Exclude System Schemas**:
   - Ignores `information_schema`, `performance_schema`, and `mysql` schemas to focus on user-defined databases.

---

### Usage

To execute the stored procedure, call it with the desired column name pattern:

```sql
CALL system_CheckIndex('Id');
```

---

### Example Output

After execution, the procedure generates a report like this:

| **TABLE_SCHEMA** | **TABLE_NAME** | **COLUMN_NAME** | **Indexed**     |
|-------------------|----------------|------------------|-----------------|
| mydb              | users          | userId          | Not indexed     |
| mydb              | orders         | orderId         | Not indexed     |
| mydb              | products       | productId       | PRIMARY (index) |

- The **`Indexed`** column indicates whether the column is indexed. If not, it will display **"Not indexed"**.

---

### Use Cases

1. **Performance Tuning**:
   - Identify unindexed columns that might slow down queries, joins, or lookups.

2. **Database Maintenance**:
   - Audit tables to ensure critical columns are indexed properly.

3. **Query Optimization**:
   - Target unindexed columns in frequently queried tables for adding appropriate indexes.

4. **Schema Analysis**:
   - Analyze indexing practices across schemas to improve consistency and performance.

---

### Advantages
- **Automated Auditing**:
   - Saves time by programmatically checking for missing indexes.
- **Customizable**:
   - Allows you to focus on specific columns based on the name pattern.
- **Comprehensive**:
   - Scans all user schemas and tables, providing a detailed report of unindexed columns.

---



DROP PROCEDURE IF EXISTS `system_CheckIndex`;

DELIMITER ;;
CREATE PROCEDURE `system_CheckIndex`(
IN pIndex VARCHAR(100)
)

BEGIN

SELECT t.TABLE_SCHEMA
     , t.TABLE_NAME
     , c.COLUMN_NAME
     , IFNULL(kcu.CONSTRAINT_NAME, 'Not indexed') AS Indexed
FROM information_schema.TABLES as t
         INNER JOIN information_schema.COLUMNS as c
                    ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
                        AND c.TABLE_NAME = t.TABLE_NAME
                        AND c.COLUMN_NAME LIKE '%pIndex%'
         LEFT JOIN information_schema.KEY_COLUMN_USAGE as kcu
                   ON kcu.TABLE_SCHEMA = t.TABLE_SCHEMA
                       AND kcu.TABLE_NAME = t.TABLE_NAME
                       AND kcu.COLUMN_NAME = c.COLUMN_NAME
                       AND kcu.ORDINAL_POSITION = 1
WHERE kcu.TABLE_SCHEMA IS NULL
  AND t.TABLE_SCHEMA NOT IN ('information_schema', 'performance_schema', 'mysql');

END;;
DELIMITER ;

CALL system_CheckIndex('Id');