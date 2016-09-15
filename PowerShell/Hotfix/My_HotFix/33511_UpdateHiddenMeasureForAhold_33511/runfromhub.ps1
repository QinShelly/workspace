param($databaseServer="eng1wnqa2.colo.retailsolutions.com",
$databaseName="MASTERDATA_PLUTO")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"

$sql="
select 
replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over() AS Coun from RSI_DIM_SILO 
where BUILD_NUMBER='7001' AND type in('S') AND status in('a') and RETAILER_NAME='Ahold'
"

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
$NewMetadata="
'DC On Hand vs. Expected Demand Var Volume Cases (NPI)',
'DC On Hand vs. Expected Demand Var Volume Units (NPI)',
'DC On Hand and On Order vs. Expected Demand Var Volume Cases (NPI)',
'DC On Hand and On Order vs. Expected Demand Var Volume Units (NPI)',
'DC On Hand vs. Expected Demand Var Volume Cases (Promo)',
'DC On Hand vs. Expected Demand Var Volume Units (Promo)'
"

foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	
	$VerifySql="
	DECLARE @IsVisableInCube int=0
	DECLARE @IsEventBeInserted int=0
	DECLARE @IsAvailableForMetaTables int=0
	
	select @IsVisableInCube=1

	select @IsAvailableForMetaTables=case when count(1)=6 then 1 else 0 end from RSI_META_MEASURES_DESCRIPTION as descrip
	join RSI_META_MEASURES AS measure
	on descrip.MEASURE_NAME=measure.MEASURE_NAME and descrip.RETAILER_NAME='AHOLD USA'
	join RSI_META_MEASURES_RET AS ret
	on ret.MEASURE_NAME=measure.MEASURE_NAME and ret.RETAILER_NAME='AHOLD USA'
	join [olap].[RSI_OLAP_METADATA] as olap
	on olap.ALIAS=ret.MEASURE_NAME
	where measure.MEASURE_NAME in("+$NewMetadata+")

	select @IsEventBeInserted=count(1) from rsi_olap_process
	where ObjectName='Metadata' and Status is null

	DECLARE @IsAholdUSA varchar(512),@ReturnString varchar(100)='Success'
	select @IsAholdUSA=value from RSI_CORE_CFGPROPERTY
	where Name like '%cube.metrics.retailer%'

	IF @IsAholdUSA='AHOLD USA'
	BEGIN
		SET @ReturnString=case when @IsEventBeInserted=1 then 'Event Succeed,' else 'Event Failed,' end +
				case when @IsAvailableForMetaTables=1 then 'Tables Succeed,' else 'Tables Failed,'end +
				case when @IsVisableInCube=1 then 'Cube Succeed' else 'Cube Failed' end
	END

	SELECT @ReturnString AS ReturnString
"
	$VerifyResault=@(Invoke-Sqlcmd -Query $VerifySql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	
	$outpute=$VerifyResault[0].ReturnString+"  "+$dbname +" $dbserver "
	write-host $outpute

	write-host "----$Percent%   $index  "
	$Index=$Index+1
}
write-host "finished!"
