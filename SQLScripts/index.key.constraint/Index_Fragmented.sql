--Get Top 5 Fragmented Index
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

--Get Index with fragmentation > 15
SELECT DB_NAME(SDDIPS.[database_id]) AS [database_name],  
        OBJECT_NAME(SDDIPS.[object_id], DB_ID()) AS [object_name],  
        SSI.[name] AS [index_name], SDDIPS.partition_number,  
        SDDIPS.index_type_desc, SDDIPS.alloc_unit_type_desc,  
        SDDIPS.[avg_fragmentation_in_percent], SDDIPS.[page_count]  
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'detailed') SDDIPS  
        INNER JOIN sys.sysindexes SSI  
                ON SDDIPS.OBJECT_ID = SSI.id  
                        AND SDDIPS.index_id = SSI.indid  
WHERE SDDIPS.page_count > 30  
        AND avg_fragmentation_in_percent > 15  
        AND index_type_desc <> 'HEAP'  
ORDER BY OBJECT_NAME(SDDIPS.[object_id], DB_ID()), index_id
