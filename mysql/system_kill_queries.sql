#### 6. **Find and Kill Running Processes**
Lists all currently running processes in MySQL except those in the `Sleep` state, allowing you to identify and terminate long-running or problematic queries.

Steps to Kill All Non-Sleeping Queries
Inspect Non-Sleeping Queries (Optional): First, verify the processes you want to kill:

```sql
SELECT ID, USER, HOST, DB, COMMAND, TIME, STATE, INFO
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE COMMAND != 'Sleep';
```

Generate and Execute KILL Commands Dynamically: Use a prepared statement to kill all processes that are not in the Sleep state.

```sql
SET @killsql = NULL;

SELECT GROUP_CONCAT(CONCAT('KILL ', ID, ';') SEPARATOR ' ')
INTO @killsql
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE COMMAND != 'Sleep';

PREPARE stmt FROM @killsql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

---