param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$hub="",
$SiloName="",
$BuildNumber="")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

$sql="
DECLARE @ReturnCode INT
DEclare @SiloName nvarchar(2000)='$SiloName'--'Unilever_Safeway'
DEclare @ServerName nvarchar(2000)='$databaseServer'--'Unilever_Safeway'
DEclare @BuildN nvarchar(2000)='$BuildNumber'--'Unilever_Safeway'
DEclare @Hub nvarchar(2000)='$hub'--'Unilever_Safeway'
;with cte as
(
SELECT ps.name
     ,OBJECT_NAME(p.object_id) AS table_name
     ,p.data_compression_desc
     ,sum(rows) as row,
     MAX(partition_number) as partition_number
 FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i ON p.object_id = i.object_id AND p.index_id = i.index_id
 INNER JOIN sys.partition_schemes ps ON i.data_space_id=ps.data_space_id
 INNER JOIN sys.objects AS o ON o.object_id = i.object_id
 where ps.name='POSDatePScheme'
group by data_compression_desc,ps.name,OBJECT_NAME(p.object_id)
)
,cte2 as
(
select *,ROW_NUMBER()over(partition by table_name order by getdate()) as rn from cte
)
,cte3 as
(
select * from cte2 where
table_name in (
select table_name from cte2 where rn>1

)
and table_name not in
(
select table_name from cte2 where partition_number=1
)
)
select 'select '+Ltrim((MIN(partition_number)/7))+' as MinWeek,'''+@SiloName+''' as SiloName,
'''+@ServerName+''' as ServerName,
'''+@BuildN+''' as BuildN,
'''+@Hub+''' as Hub union all' AS Outputstr
 from cte3
"

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
foreach ($silo in $silos){
	$Output= $silo.Outputstr
	write-host $Output
	
	get-content $currentPath\hotfix_silo.log
	}


##SQLCMD -E -S $databaseServer -d $databaseName -o $currentPath\hotfix_silo.log -i $currentPath\hotfix_silo.sql -b -v SiloName="$SiloName" -v ServerName="$databaseServer" -v Hub="$databaseServer" -v BuildN="$BuildNumber"

 
## 

