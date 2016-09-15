Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
)

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
$sql="
declare @ss int=0
select @ss=count(1) from RSI_META_MEASURE_CONVERSION
;with cte as(
SELECT a.RETAILER_NAME, CONVERSION_TYPE, a.[MEASURE_NAME], LOCATION_TYPE, a.CORE_MEASURE,b.PIT,b.REQUIRE_COUNT_MEASURE,b.REQUIRE_AVG
FROM (
	SELECT 1 CONVERSION_TYPE, [MEASURE_NAME],[DESCRIPTION], RETAILER_NAME, REPLACE(MEASURE_NAME, ' Cases', ' Units') CORE_MEASURE
	FROM [dbo].[RSI_META_MEASURES_DESCRIPTION]
	WHERE MEASURE_NAME like '%Cases' and [DESCRIPTION] = REPLACE(MEASURE_NAME, 'Cases', 'Units') + '/VENDOR_PACK_QTY'

	UNION ALL
	SELECT 2 CONVERSION_TYPE, [MEASURE_NAME],[DESCRIPTION], RETAILER_NAME , REPLACE(MEASURE_NAME, 'Cases', 'Units') CORE_MEASURE
	FROM [dbo].[RSI_META_MEASURES_DESCRIPTION]
	WHERE MEASURE_NAME like '%Cases' and [DESCRIPTION] like '%If VENDOR_PACK_QTY = DEFAULT_STORE_PACK_QTY%/VENDOR_PACK_QTY%'

	UNION ALL
	SELECT 3 CONVERSION_TYPE, [MEASURE_NAME] ,[DESCRIPTION], RETAILER_NAME, REPLACE(MEASURE_NAME, ' Units', ' Cases') CORE_MEASURE
	FROM [dbo].[RSI_META_MEASURES_DESCRIPTION]
	WHERE  MEASURE_NAME like '%Units' and [DESCRIPTION] = REPLACE(MEASURE_NAME, 'Units', 'Cases') + '*VENDOR_PACK_QTY'

	UNION ALL
	SELECT 4 CONVERSION_TYPE, [MEASURE_NAME],[DESCRIPTION], RETAILER_NAME, REPLACE(MEASURE_NAME, ' Units', ' Cases') CORE_MEASURE
	FROM [dbo].[RSI_META_MEASURES_DESCRIPTION]
	WHERE MEASURE_NAME like '%Units' and [DESCRIPTION] like '%If VENDOR_PACK_QTY = DEFAULT_STORE_PACK_QTY%*VENDOR_PACK_QTY%'

	UNION ALL
	SELECT 5 CONVERSION_TYPE, replace([MEASURE_NAME], ' Units', ' Equivalent Units'),'', RETAILER_NAME, [MEASURE_NAME] CORE_MEASURE
	FROM [dbo].RSI_META_MEASURES_CORE
	WHERE REQUIRE_EQUI_CONVERSION = 1 and RETAILER_NAME != '*'

) a
  join [dbo].RSI_META_MEASURES_CORE b on b.MEASURE_NAME = a.CORE_MEASURE and (b.RETAILER_NAME = '*' or a.RETAILER_NAME = b.RETAILER_NAME)
  

)
select count(1) as Coun  from cte where MEASURE_NAME not in
(
select distinct MEASURE_NAME from RSI_META_MEASURE_CONVERSION
)
and @ss>0
"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $serverName -database $dbName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$Coun= $silo.Coun
	if($Coun -gt 0)
	{
	  write-host "$dbName on $serverName"
	}else
	{
		write-host "--"
	}
	
}