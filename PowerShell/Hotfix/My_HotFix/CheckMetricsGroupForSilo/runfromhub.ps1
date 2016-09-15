param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$InputSiloId="all")

#powershell C:\T3Ci\sandbox\daniel\scorecardColumnLength\runfromhub.ps1 PROD1ALTPTL1 MASTERDATA 6940

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "--current dir is $currentPath"
$logOutPut = "$currentPath\Log.txt"

$sql=" 
 select *,count(1)over() AS Coun from
(
 
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME,METRICS_BUILD_NUMBER ,'cnhub' hub from cnhub.dbo.RSI_DIM_SILO 
where -- cast(replace(METRICS_BUILD_NUMBER,'.','') as int)>=69 AND 
type in('S') and [Status]='a' and RETAILER_NAME like 'target%'
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME,METRICS_BUILD_NUMBER,'eurohub' hub  from eurohub.dbo.RSI_DIM_SILO 
where -- cast(replace(METRICS_BUILD_NUMBER,'.','') as int)>=69 AND 
type in('S') and [Status]='a' and RETAILER_NAME like 'target%'
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME,METRICS_BUILD_NUMBER,'gahub' hub  from gahub.dbo.RSI_DIM_SILO 
where -- cast(replace(METRICS_BUILD_NUMBER,'.','') as int)>=69 AND 
type in('S') and [Status]='a' and RETAILER_NAME like 'target%' 
)as a
order by RETAILER_NAME
"

if($InputSiloId -ne "all")
{
	$sql="$sql and siloid='$InputSiloId'"
}

#write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	$SiloType=$silo.SiloType
	$METRICS_BUILD_NUMBER=$silo.METRICS_BUILD_NUMBER
	$hub=$Silo.hub
	$RETAILER_NAME=$Silo.RETAILER_NAME
	
	$sql="
 
 
select 
max(case when name='cube.metrics.retailer' then Value else null end) as MetricRetailer,
max(case when name='db.custom.sql' then replace(Value,'`${rsi.install.home}\scripts\rdbms\dsm\custom\','') else null end) as CustomSQL,
max(case when name='rsi.cube.custom.mdx' then replace(Value,'`${rsi.install.home}\scripts\cubes\dsm\custom\','') else null end) as CustomMDX
 from RSI_CORE_CFGPROPERTY
where name in('cube.metrics.retailer','db.custom.sql','rsi.cube.custom.mdx')
	"
	$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	
	foreach($NewColumn in $NewColumns)
	{
	  $MetricRetailer=$NewColumn.MetricRetailer
	  $CustomMDX=$NewColumn.CustomMDX
	  $CustomSQL=$NewColumn.CustomSQL
	  write-host "--$Percent"
	  write-host "select '"$siloId"' as siloid, '"$dbserver"' as servername,'"$RETAILER_NAME"' as RETAILER_NAME, '"$MetricRetailer"' as MetricRetailer,'"$CustomMDX"' as CustomMDX,'"$CustomSQL"' as CustomSQL union all"
	}
	
	
	$Index=$Index+1
}
write-host " --Finished!"
