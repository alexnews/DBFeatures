Query Performance Schema
The Performance Schema provides detailed query execution data. If it''s enabled, you can access this data without server access.

Steps:
Check if the Performance Schema is enabled:

sql
SHOW VARIABLES LIKE 'performance_schema';
if not, you have to turn it on in the ini:
performance_schema = ON

Query for slow queries:

SELECT 
    DIGEST_TEXT AS query,
    COUNT_STAR AS exec_count,
    SUM_TIMER_WAIT / 1000000000 AS total_time_in_sec,
    AVG_TIMER_WAIT / 1000000000 AS avg_time_in_sec
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_TIMER_WAIT / 1000000000 > 1 -- Queries taking more than 1 second
ORDER BY total_time_in_sec DESC
LIMIT 10;
