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
 
 
 declare @Yes varchar(10)='N'
 IF NOT EXISTS (SELECT * FROM sys.all_views AS v JOIN sys.sql_modules AS smv ON smv.object_id = v.object_id and name = 'ANL_STORE_SALES' WHERE smv.definition like '%Store SKU Active Indicator%')
	AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('template.RSI_FACT_PIVOT') AND name = 'Store SKU Active Indicator')
	AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('template.RSI_FACT_PIVOT') AND name = 'Store SKU Tracked Indicator')
	AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('template.RSI_FACT_PIVOT') AND name = 'POG_IND')
	AND EXISTS (select * from RSI_META_ATTRIBUTE where RETAILER_NAME = 'Target' and DIMENSION_TYPE = 1 and KEY_COLUMN = 'DSD_IND')
BEGIN
 set @Yes='Y'
END
select @Yes  as [Yes]
 
	"
	$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	
	foreach($NewColumn in $NewColumns)
	{
	  $Yes=$NewColumn.Yes
	  if($Yes -eq 'Y')
	  {
	  
	  write-host "select '"$siloId"' as siloid, '"$dbserver"' as servername union all"
	  }
	  write-host "--$Percent"
	}
	
	
	$Index=$Index+1
}
write-host " --Finished!"
