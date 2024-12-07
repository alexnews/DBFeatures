#### **Analytics by Tables**
Provides a detailed breakdown of storage usage (data size, index size, and total size) for tables grouped by schema and engine.

```sql
SELECT Statistic, DataSize "Data Size", IndexSize "Index Size", TableSize "Table Size"
FROM (SELECT IF(ISNULL(table_schema)=1,10,0) schema_score,
IF(ISNULL(engine)=1,10,0) engine_score, IF(ISNULL(table_schema)=1,
'ZZZZZZZZZZZZZZZZ',table_schema) schemaname,
IF(ISNULL(B.table_schema)+ISNULL(B.engine)=2,
"Storage for All Databases",IF(ISNULL(B.table_schema)+ISNULL(B.engine)=1,
CONCAT("Storage for ",B.table_schema),CONCAT(B.engine," Tables for ",
B.table_schema))) Statistic,
CONCAT(LPAD(REPLACE(FORMAT(B.DSize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') DataSize,
CONCAT(LPAD(REPLACE(FORMAT(B.ISize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') IndexSize,
CONCAT(LPAD(REPLACE(FORMAT(B.TSize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') TableSize FROM (SELECT table_schema,engine,
SUM(data_length) DSize,SUM(index_length) ISize,SUM(data_length+index_length) TSize
FROM information_schema.tables WHERE table_schema NOT IN
('mysql','information_schema','performance_schema') AND engine IS NOT NULL
GROUP BY table_schema,engine WITH ROLLUP) B,(SELECT 3 pw) A) AA
ORDER BY schemaname,schema_score,engine_score;
```

---