--Log Space
DBCC SQLPERF (LOGSPACE)


--DB / Table space 
sp_spaceUsed 'table'

sp_helpdb 


--stats
dbcc updateusage('regbuitdw')
go

EXEC sp_updatestats
go

 
DBCC CheckDB ([DBName])

sp_who2

dbcc inputbuffer (81)

sp_lock 81

kill 75

select db_name(13)
 
select object_name(59172748)
 
select * from sys.sysfiles
 
sp_renamedb 'RegBuitStaging','RegBuitStaging_old'

dbcc shrinkfile (3,1,NOTRUNCATE)

select object_name(ID) from sys.sysindexes Order by rowcnt desc 
 
sp_Detach_DB 'regbuitstagingold'

select * from master.dbo.sysdatabases Order by name

SELECT * FROM sys.dm_exec_query_stats CROSS APPLY sys.dm_exec_query_plan(plan_handle)

SELECT * FROM sys.dm_exec_query_stats CROSS APPLY sys.dm_exec_sql_text(sql_handle)

SELECT * FROM sys.dm_exec_cached_plans CROSS APPLY sys.dm_exec_query_plan(plan_handle)

--Get fragment index

select QUOTENAME(DB_NAME(i.database_id), '"')
+ N'.'
+ QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id, i.database_id), '"')
+ N'.'
+ QUOTENAME(OBJECT_NAME(i.object_id, i.database_id), '"') as full_obj_name
, *
from (
 select *, DENSE_RANK() OVER(PARTITION by database_id ORDER BY avg_fragmentation_in_percent DESC) as rnk
 from sys.dm_db_index_physical_stats(default, default, default, default, default)
 where avg_fragmentation_in_percent > 0
) as i
where i.rnk <= 5
order by i.database_id, i.rnk
