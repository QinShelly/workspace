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
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME from gahub.dbo.RSI_DIM_SILO 
where  METRICS_BUILD_NUMBER>='6.3' AND type in('S','m') and [Status]='a' 
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME from cnhub.dbo.RSI_DIM_SILO 
where METRICS_BUILD_NUMBER>='6.3' AND type in('S','m') and [Status]='a'  
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME from eurohub.dbo.RSI_DIM_SILO 
where METRICS_BUILD_NUMBER>='6.3' AND type in('S','m') and [Status]='a'  
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
 
	
	$sql="
		select 
CAST([[measures]].[tom]]] as int) As Existed
from OPENQUERY("+$siloId+"_OLAP, '
with member [tom]
as count(([Metadata].[Metadata].&[Measure]&[[Measures]].[1 Wk Sales Amount Prev]]]))
select{[tom]} on 0 from ["+$siloId+"] where [Metadata].[Metadata Type].&[Measure]
')
as a 
	"
	$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	
	foreach($NewColumn in $NewColumns)
	{
	  $NewSP=$NewColumn.Existed
	  if($NewSP -eq "1")
	  {}
	  else
	  {
	  write-host "--$Percent"
	  write-host "select "$siloId" as siloid, "$dbserver" as servername union all"}
	  
	}
	
	
	$Index=$Index+1
}
write-host " --Finished!"
