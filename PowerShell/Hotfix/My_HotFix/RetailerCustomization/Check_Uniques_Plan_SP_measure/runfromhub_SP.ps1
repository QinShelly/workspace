param($RetailerName="")

#powershell C:\T3Ci\sandbox\daniel\scorecardColumnLength\runfromhub.ps1 PROD1ALTPTL1 MASTERDATA 6940
#


$databaseServer="wal1wnfshub.colo.retailsolutions.com"


$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

$sql="

declare @RetailerName varchar(100)='$RetailerName'

SELECT siloid,retailer_Name,count(1) over() as cou,
replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,HubDB,BUILD_NUMBER,RN FROM 
(
	SELECT siloid,retailer_Name,DB_SERVERNAME,DB_NAME,HubDB,BUILD_NUMBER,
	ROW_NUMBER()OVER(PARTITION BY HubDB ORDER BY BUILD_NUMBER desc,HubDB ) RN
	FROM
	(
		select siloid, retailer_Name,DB_SERVERNAME,DB_NAME,'GAHUB' As HubDB,BUILD_NUMBER
		from GAHUB.dbo.RSI_DIM_SILO
		where RETAILER_NAME=@RetailerName and status='A' 
		union all
		select siloid,retailer_Name,DB_SERVERNAME,DB_NAME,'EUROHUB' As HubDB,BUILD_NUMBER
		from EUROHUB.dbo.RSI_DIM_SILO
		where RETAILER_NAME=@RetailerName and status='A' 
		union all
		select siloid,retailer_Name,DB_SERVERNAME,DB_NAME,'CNHUB' As HubDB,BUILD_NUMBER
		from CNHUB.dbo.RSI_DIM_SILO
		where RETAILER_NAME=@RetailerName and status='A' 
	) as a) AS B 
 "
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database "GAHUB" -QueryTimeout 65535)

if($silos.count -gt 0)
{
    $SiloTotals=$silos.count
    write-host " $SiloTotals"
	foreach ($silo in $silos){
		$dbserver= $silo.DB_SERVERNAME
		$dbname= $silo.DB_NAME
		$siloId= $silo.siloid
		$totalCount=$silo.cou
		$BUILD_NUMBER=$silo.BUILD_NUMBER
		$sql="
			select   distinct
			ltrim(replace(replace(REPLACE(name,'TYA',''),'LY',''),'TY','')) as NewColumn
			 from syscolumns 
			where id=OBJECT_ID('olap.UNIQUES_TYPE','u')
			and name not like '%_OH%'
			and name not like '%_SCAN%' and name not like '%_PLAN%'	and name <>'DESCR' and name <>'UNIQUES_KEY'
		"
		$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
		
		
		if($NewColumns.count -gt 0)
		{
			write-host "------------Additional Unique[$BUILD_NUMBER->$totalCount]------------"
			foreach($NewColumn in $NewColumns)
			{
			  $NewUnique=$NewColumn.NewColumn
			  write-host "$NewUnique"
			}
		}
		$sql="
	select c.name as NewColumn from syscolumns  as c
	
	where id=OBJECT_ID('dbo.RSI_FACT_PLAN','u')
	and name not in
	(
	'VENDOR_KEY','RETAILER_KEY','ITEM_KEY','STORE_KEY','PERIOD_KEY','SUBVENDORID','OOS_TYPE','UNIQUES_TYPE','SCAN DATE','Store On Hand Volume Units Modeledx',
	'Store Out of Stock Indicator Modeledx','Last Store On Hand Volume Units Modeledx','Last Store Out of Stock Indicator Modeledx'
	)
		"
		$NewColumns=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
		
		if($NewColumns.count -gt 0)
		{
			write-host "------------Planned SP measures------------"
			foreach($NewColumn in $NewColumns)
			{
			  $NewSP=$NewColumn.NewColumn
			  write-host "$NewSP"
			}
		}
	}
}
write-host "finished!"
