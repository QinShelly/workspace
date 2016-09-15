USE master 
GO 

IF OBJECT_ID('sp_db_space_usage') IS NOT NULL DROP PROC sp_db_space_usage 
GO 

CREATE PROC sp_db_space_usage 
 @sort CHAR(1) = 'n' 
AS 
/********************************************************************* 
@sort accept three values: 'n' (default), 'd' and 'l'. 
It specifies the sort order (name, data allocated, log allocated). 

Written by Tibor Karaszi 2009-12-29 
Last modified by Tibor Karaszi 2009-12-29 
*********************************************************************/ 
SET NOCOUNT ON 
DECLARE @sql NVARCHAR(2000) 
DECLARE @db_name sysname 

--Create tables to hold space usage stats from commands 
CREATE TABLE #dbcc_sqlperf_logspace 
( 
 database_name VARCHAR(32) NOT NULL 
,log_size real NOT NULL 
,log_percentage_used real NOT NULL 
,status_ INT NOT NULL 
) 

CREATE TABLE #dbcc_showfilestats  
( 
 database_name sysname NULL 
,file_id_ INT NOT NULL 
,file_group INT NOT NULL 
,total_extents bigint NOT NULL 
,used_extents bigint NOT NULL 
,name_ sysname NOT NULL 
,file_name_ NVARCHAR(3000) NOT NULL 
) 

--Create table to hold final output 
CREATE TABLE #final_output 
( 
 database_name sysname 
,data_allocated INT 
,data_used INT 
,log_allocated INT 
,log_used INT 
,is_sum bit 
) 

--Populate log space usage 
SELECT @sql = 'DBCC SQLPERF (LOGSPACE) WITH NO_INFOMSGS' 
INSERT INTO #dbcc_sqlperf_logspace(database_name, log_size, log_percentage_used, status_) 
EXECUTE (@sql) 

----Populate data space usage 
DECLARE db CURSOR FOR SELECT name FROM sysdatabases 
OPEN db 
WHILE 1 = 1 
BEGIN 
  FETCH NEXT FROM db INTO @db_name 
  IF @@FETCH_STATUS <> 0 
   BREAK 
  SET @sql = 'USE ' + QUOTENAME(@db_name) + ' DBCC SHOWFILESTATS WITH NO_INFOMSGS' 
  INSERT INTO #dbcc_showfilestats(file_id_, file_group, total_extents, used_extents, name_, file_name_) 
  EXEC (@sql) 
  UPDATE #dbcc_showfilestats SET database_name = @db_name WHERE database_name IS NULL 
END 
CLOSE db 
DEALLOCATE db 

--Result into final table 
INSERT INTO #final_output(database_name, data_allocated, data_used, log_allocated, log_used, is_sum) 
SELECT 
CASE WHEN d.database_name IS NOT NULL THEN d.database_name ELSE '[ALL]' END AS database_name 
,SUM(CAST((d.data_alloc * 64.00) / 1024 AS decimal(18,2))) AS data_alloc 
,SUM(CAST((d.data_used * 64.00) / 1024 AS decimal(18,2))) AS data_used 
,SUM(CAST(log_size AS numeric(18,2))) AS log_size 
,SUM(CAST(log_percentage_used * 0.01 * log_size AS numeric(18,2))) AS log_used 
,GROUPING(d.database_name) AS is_sum 
FROM ( 
    SELECT database_name, SUM(total_extents) AS data_alloc, SUM(used_extents) AS data_used 
    FROM #dbcc_showfilestats 
    GROUP BY database_name 
    ) AS d 
  INNER JOIN #dbcc_sqlperf_logspace AS l  
    ON d.database_name = l.database_name 
GROUP BY d.database_name WITH ROLLUP 

--Output result 
SELECT database_name, data_allocated, data_used, log_allocated, log_used  
FROM #final_output 
ORDER BY  
 is_sum 
,CASE WHEN @sort = 'n' THEN database_name END 
,CASE WHEN @sort = 'd' THEN data_allocated END DESC 
,CASE WHEN @sort = 'l' THEN log_allocated END DESC 

--Test execution 
/* 
EXEC sp_db_space_usage 
EXEC sp_db_space_usage 'n' 
EXEC sp_db_space_usage 'd' 
EXEC sp_db_space_usage 'l' 
*/ 
GO 
