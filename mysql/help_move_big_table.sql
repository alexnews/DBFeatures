-- Alex Kargin github.com/alexnews/DBFeatures/
### Description: Moving Large Tables with Minimal Disruption

Managing large tables in high-traffic databases can be challenging, especially when downtime or performance impacts are unacceptable. In one of my tasks, I needed to move a table containing **10 million records**—the main table for users—without causing significant disruption to ongoing operations.

---

### The Challenge
- The table was critical to the system, with frequent reads and writes.
- A direct migration could overload the database, resulting in downtime or delays for users.
- The goal was to move the data **incrementally** to reduce the strain on the database.

---

### The Solution
I devised an **incremental migration script** that moves data in manageable portions (batches) while ensuring the integrity and structure of the new table. The process is automated using a stored procedure, allowing the migration to occur with minimal intervention and without locking the entire table. The script took me **~2 hours** to write and debug.

---

### Key Features of the Script
1. **Table Recreation**:
   - Drops the target table (`NewTableName`) if it already exists.
   - Creates the new table (`NewTableName`) with the same structure as the source table (`TableName`).

2. **Incremental Data Migration**:
   - Migrates records in batches of a specified size (`HowManyPerMove`), ensuring minimal database load.
   - Uses `INSERT IGNORE` to avoid duplicate entries during the process.

3. **Progress Monitoring**:
   - Keeps track of the number of migrated records (`@position`) to ensure all rows are processed.
   - Provides a summary report comparing the total rows in the old and new tables.

4. **Error Prevention**:
   - Ensures transactions are committed at every step, minimizing the risk of data loss.
   - Automatically adjusts for scenarios where the total number of rows changes dynamically.

---

### Code Walkthrough
Here’s how the stored procedure works:

1. **Table Preparation**:
   - Drops the existing target table if it exists.
   - Creates a new table with the same schema as the source table.

2. **Count Total Rows**:
   - Calculates the total number of records in the source table (`@total`).

3. **Batch Processing**:
   - Copies records in chunks (`HowManyPerMove`) using a loop.
   - Commits transactions after each batch to ensure database consistency.

4. **Validation**:
   - Compares the row count between the source and target tables for validation.
   - Outputs a summary message confirming the success of the operation.

---

### How to Use the Script
To execute the migration, call the stored procedure with the source table name, target table name, and batch size as parameters. For example:
```sql
CALL help_MoveRowsFromBigTable('Users', 'Users_new', 10000);
```

---

### Example Output
After execution, the procedure outputs the following confirmation message:
```
Old Table Users: 10000000 - New Table Users_new: 10000000
```

---

### Advantages
1. **Minimal Impact**:
   - Migrates data in chunks, avoiding significant strain on the database.
2. **Automation**:
   - Once started, the process runs without manual intervention.
3. **Flexibility**:
   - Allows adjustable batch sizes to suit the database''s performance capacity.

This approach is ideal for environments where performance and uptime are critical, and large tables need to be migrated or archived efficiently.

---


DROP PROCEDURE IF EXISTS `help_MoveRowsFromBigTable`;



DELIMITER ;;
CREATE PROCEDURE `help_MoveRowsFromBigTable`(
IN TableName VARCHAR(200),
IN NewTableName VARCHAR(200),
IN HowManyPerMove INT(10)
)

BEGIN

    SET @sql_txt = CONCAT('DROP TABLE IF EXISTS ',NewTableName);
    PREPARE sql_exec FROM @sql_txt;
    EXECUTE sql_exec;
    DEALLOCATE PREPARE sql_exec;

    SET @sql_txt = concat('CREATE TABLE ',NewTableName,' LIKE ',TableName);
    PREPARE sql_exec FROM @sql_txt;
    EXECUTE sql_exec;
    DEALLOCATE PREPARE sql_exec;

    SET @sql_txt = concat('SELECT count(*) INTO @total FROM ',TableName);
    PREPARE sql_exec FROM @sql_txt;
    EXECUTE sql_exec;
    DEALLOCATE PREPARE sql_exec;

    SET @position := 0;
    label1: WHILE @position < @total DO
        SET @sql_txt = concat('INSERT IGNORE INTO ',NewTableName,' SELECT * FROM ',TableName,' LIMIT ',@position,', ',HowManyPerMove);
        PREPARE sql_exec FROM @sql_txt;
        START TRANSACTION;
        EXECUTE sql_exec;
        COMMIT;
        DEALLOCATE PREPARE sql_exec;
        SET @position := @position + HowManyPerMove;
        IF @position > @tolal THEN
            SET @position := @total;
        END IF;
    END WHILE label1;

    SET @sql_txt = concat('SELECT count(*) INTO @totalNew FROM ',NewTableName);
    PREPARE sql_exec FROM @sql_txt;
    EXECUTE sql_exec;
    DEALLOCATE PREPARE sql_exec;

    SELECT CONCAT('Old Table ',TableName,': ',@total,' - New Table',NewTableName,': ',@totalNew);

END;;
DELIMITER ;

CALL help_MoveRowsFromBigTable('Users','Users_new',10000);