param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"

$sql="
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over() AS Coun  from gahub.dbo.RSI_DIM_SILO 
where METRICS_BUILD_NUMBER>='4.1' AND type in('S') AND status in('a') and RETAILER_NAME='Family Dollar'
"

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	
	.\1680_FD_UpdateAggregationToSum_34749.ps1 -siloId $siloId -serverName $dbserver -cubeServerName $dbserver  -dbName $dbname -cubeDBName $dbname -cubeName $dbname
	
	$jobName="$siloId#FullCubeProcess"
	$sql="EXECUTE msdb.dbo.sp_start_job '"+$jobName+"';"
	write-host "----$Percent%---$sql"
	$Index=$Index+1
}
write-host "finished!"
