param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$InputSiloId="all")

#powershell C:\T3Ci\sandbox\daniel\scorecardColumnLength\runfromhub.ps1 PROD1ALTPTL1 MASTERDATA 6940

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
$logOutPut = "$currentPath\Log.txt"

$sql=" 

select top 1 * from
(
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over() AS Coun,[type] as SiloType from gahub.dbo.RSI_DIM_SILO 
where BUILD_NUMBER>='6940' AND type in('S','C') and [Status]='a'  
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over() AS Coun,[type] as SiloType from cnhub.dbo.RSI_DIM_SILO 
where BUILD_NUMBER>='6940' AND type in('S','C') and [Status]='a'  
union all
select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over() AS Coun,[type] as SiloType from eurohub.dbo.RSI_DIM_SILO 
where BUILD_NUMBER>='6940' AND type in('S','C') and [Status]='a'  
)as a
where   siloid in
(
'PINNACLE_AHOLD',
'GLAXOSMITHKLINE_MORRISONS',
'UNILEVER_AHOLD',
'KMCLRK_AHOLD',
'UNITED_BISCUITS_MORRISONS',
'KRAFT_SNACKS_BJS',
'MCCORMICK_AHOLD',
'NESTLE_PURINA_AHOLD',
'PEPSICO_AHOLD',
'PG_AHOLD',
'PINNACLE_AHOLD',
'RECKITT_BENCKISER_AHOLD',
'SC_JOHNSON_AHOLD',
'TGTCAT_DIABETIC_CARE',
'TGTCAT_WATER',
'TRUCO_AHOLD',
'UNILEVER_AHOLD'
) 
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
	write-host "----------------$Percent $siloId on server $dbserver-----------------"
	.\1562_FirstScanDate_PerformanceIssue_CR32349.ps1 -siloId $siloId -serverName $dbserver -cubeServerName $dbserver  -dbName $dbname -cubeDBName $dbname -cubeName $dbname -SiloType $SiloType
	$Index=$Index+1
}
write-host "    Finished!"
