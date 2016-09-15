param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$buildnumer=6911)

#powershell C:\T3Ci\sandbox\daniel\scorecardColumnLength\runfromhub.ps1 PROD1ALTPTL1 MASTERDATA 6940
#
$releaseHash=@{6902='everest6902';6903='everest6903';6910='pluto6910';6911='pluto6911';6940='pluto6940'}

$releasename=$releaseHash[$buildnumer]

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
$sql="
select distinct
replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid
,count(1)over() AS Coun
 from cnhub.dbo.rsi_dim_silo

where SiloId in
(
'UNILEVER_CR_VANGUARD'
,'UNILEVER_LOTUS'
,'UNILEVER_RT_MART'
,'NANFU_RT_MART'
,'MENGNIU_RT_MART'
,'KMCLRK_RT_MART'
,'UNILEVER_YONGHUI'
,'UNILEVER_REN_REN_LE'
,'UNILEVER_AUCHAN_CHINA'
,'UNILEVER_METRO_CHINA'
,'UNILEVER_SUGUO'
,'UNILEVER_LOTTEMART'
,'UNILEVER_LOTTEMART_EAST'
,'UNILEVER_RAINBOW'
,'UNILEVER_EMART'
,'UNILEVER_LIANHUA_HUASHANG'
,'UNILEVER_BEIJING_HUALIAN'
,'UNILEVER_CARREFOUR_CHINA'
,'UNILEVER_CENTURY_LIANHUA'
,'UNILEVER_GMS'
,'UNILEVER_MANNINGS'
,'UNILEVER_PARK_N_SHOP'
,'UNILEVER_TESCO_CHINA'
,'UNILEVER_WATSONS'
,'UNILEVER_WUMART'
,'UNILEVER_WUMEI'
)
"
#write-host $sql
write-host "dbserver:$databaseServer dbname:$databaseName"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$TotalCount=$silo.Coun
	$Percent=[int]($index*100/$TotalCount)
	$sql="
	declare @rowsCount int,@deployStatus varchar(10)='NO',@MB varchar(10)='',@ReturnString varchar(1000)=''

select @rowsCount=COUNT(1) from olap.UNIQUES_TYPE
if @rowsCount=512
set @deployStatus='YES'

 
	select @ReturnString='select ''$siloId'' siloid, ''$dbserver'' as server, '''+@deployStatus+''' as HasDeploy, ''6.9'' as MB_Version union all '   

 

	select @MB=METRICS_BUILD_NUMBER from RSI_DIM_SILO
if @MB<>'6.9'
 select @ReturnString='select ''$siloId'' siloid, ''$dbserver'' as server, ''NO'' as HasDeploy,'''+@MB+''' as MB_Version union all '  

	SELECT @ReturnString as ReturnString
	
	"
	$MetricsGroup=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)
	$print=$MetricsGroup[0].ReturnString
 
	write-host $print
	write-host "--$Percent%"	
 
	$index=$index+1
}
write-host "finished!"
