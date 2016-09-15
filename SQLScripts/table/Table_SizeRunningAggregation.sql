with cte as 
(
select *,
100. * ([DataAndIndexKB]) / SUM([DataAndIndexKB]) OVER() AS pct,
    ROW_NUMBER() OVER(ORDER BY (name) ) AS rn
from 
(
SELECT 
 tbl.Name
, Coalesce( (Select sum (spart.rows) from sys.partitions spart 
    Where spart.object_id = tbl.object_id and spart.index_id < 2), 0) AS [RowCount]

, Coalesce( (Select Cast(v.low/1024.0 as float) 
    * SUM(a.used_pages - CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id  )
    , 0.0) AS [IndexKB]

, Coalesce( (Select Cast(v.low/1024.0 as float)
    * SUM(CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id)
    , 0.0) AS [DataKB]
    
,Coalesce( (Select Cast(v.low/1024.0 as float) 
    * SUM(a.used_pages - CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id  )
    , 0.0) 
    +     
    Coalesce( (Select Cast(v.low/1024.0 as float)
    * SUM(CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id)
    , 0.0) AS [DataAndIndexKB]
    
 FROM sys.tables AS tbl
  INNER JOIN sys.indexes AS idx ON (idx.object_id = tbl.object_id and idx.index_id < 2)
  INNER JOIN master.dbo.spt_values v ON (v.number=1 and v.type='E')
) AS a
)
select 
W1.name,
W1.[RowCount],
  CAST(W1.DataAndIndexKB AS DECIMAL(12, 2)) AS DataAndIndexKB,
  CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
  CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM cte AS W1
  JOIN cte AS W2
    ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.name,W1.[RowCount], W1.DataAndIndexKB, W1.pct
--HAVING SUM(W2.pct) - W1.pct < 90 -- percentage threshold
ORDER BY W1.rn;
