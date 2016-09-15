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
,DB_NAME,siloid,[type] as SiloType,RETAILER_NAME,METRICS_BUILD_NUMBER from cnhub.dbo.RSI_DIM_SILO 
where  cast(replace(METRICS_BUILD_NUMBER,'.','') as int)>=69 AND type in('S') and [Status]='a' 
 
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
 
declare @CheckRetailer int=0
 
select @CheckRetailer=count(1) from RSI_CORE_CFGPROPERTY
where name ='cube.metrics.retailer' and Value in (
'Auchan China',
'CR Vanguard Category',
'CR Vanguard',
'Lotus',
'Ren Ren Le',
'RT Mart',
'Tesco China',
'Walmart China',
'Yong Hui'
)


if @CheckRetailer>0
begin

select case when OBJECT_DEFINITION (OBJECT_ID('[dbo].[fn`$rsi_plan_sql]')) like '%We have to make sure the @prevDay and @Day are%'
then 1 else 0 end as Existed

end
else
begin
select 0 as Existed
end
 
	"
	$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	
	foreach($NewColumn in $NewColumns)
	{
	  $NewSP=$NewColumn.Existed
	  if($NewSP -eq "0")
	  {}
	  else
	  {
	  write-host "--$Percent"
	  write-host "select '"$siloId"' as siloid, '"$dbserver"' as servername union all"}
	  
	}
	
	
	$Index=$Index+1
}
write-host " --Finished!"
