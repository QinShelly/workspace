SELECT SUM(deqs.total_logical_reads) TotalPageReads,
SUM(deqs.total_logical_writes) TotalPageWrites,
CASE
WHEN DB_NAME(dest.dbid) IS NULL THEN 'AdhocSQL'
ELSE DB_NAME(dest.dbid) END Databasename
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
GROUP BY DB_NAME(dest.dbid)
