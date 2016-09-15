param($databaseServer="eng1wnqa2.colo.retailsolutions.com",
$databaseName="MASTERDATA_PLUTO")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"

$sql="
select 
distinct DB_SERVERNAME,DB_NAME,siloid,Type
,count(1)over() AS Coun
from(
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,Type  from gahub.dbo.RSI_DIM_SILO 
where  status in('a')   and Type  in('S') and  metrics_build_number in('7.5','7.4','7.6') and retailer_name like 'target%'
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,Type  from eurohub.dbo.RSI_DIM_SILO 
where  status in('a')  and Type  in('S') and  metrics_build_number in('7.5','7.4','7.6') and retailer_name like 'target%'
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,Type  from cnhub.dbo.RSI_DIM_SILO 
where  status in('a')  and Type  in('S') and  metrics_build_number in('7.5','7.4','7.6') and retailer_name like 'target%'
) as a
"

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
 
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	
	$sql="select Value from RSI_CORE_CFGPROPERTY
where Name ='cube.metrics.retailer'"
	
	$Resault=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	$ResaultValue=$Resault.Value
	if($ResaultValue -eq 'Target')
	{
		SQLCMD -E -S $dbserver -d $dbname -i $currentPath\Target.sql -b
	}
	
	if($ResaultValue -eq 'Target Category')
	{
		SQLCMD -E -S $dbserver -d $dbname -i $currentPath\Target_Category.sql -b
	}
	$VerifySql="
declare @dailly_plan int=0
declare @weekly_plan int=0

set @dailly_plan=CHARINDEX('CASE WHEN COALESCE([Store On Hand Volume Units],0) > 0 THEN power(2,2) ELSE 0 END',
 OBJECT_DEFINITION (OBJECT_ID('dbo.fn`$rsi_plan_sql')) )
 
set @weekly_plan=CHARINDEX('CASE WHEN COALESCE([Total Sales Volume Units],0) <> 0 THEN power(2,1) ELSE 0 END',
 OBJECT_DEFINITION (OBJECT_ID('dbo.fn`$rsi_plan_sql_wk')) )
SELECT
 case when  @dailly_plan>0 and @weekly_plan>0 then 'Succeed' else 'Failed' end as messageString
	"
	$VerifyResault=@(Invoke-Sqlcmd -Query $VerifySql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	$Printmessage=$VerifyResault[0].messageString+" $dbname on $dbserver"
	write-host $Printmessage
	write-host "----$Percent%---"
	$Index=$Index+1
}
write-host "finished!"
