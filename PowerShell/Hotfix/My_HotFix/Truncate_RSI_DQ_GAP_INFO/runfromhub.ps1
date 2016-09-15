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
$sql="
select 
*,count(1)over() as Coun from
(
	select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME,DB_NAME,siloid,BUILD_NUMBER,'gahub' as hub from gahub.dbo.RSI_DIM_SILO 
	where BUILD_NUMBER>='6940' and BUILD_NUMBER<'7004'  and Type='S' and Status='A'
	union all 
	select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME,DB_NAME,siloid,BUILD_NUMBER,'CNHUB' as hub from CNHUB.dbo.RSI_DIM_SILO 
	where BUILD_NUMBER>='6940' and BUILD_NUMBER<'7004'  and Type='S' and Status='A'
	union all 
	select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME,DB_NAME,siloid,BUILD_NUMBER,'EUROHUB' as hub from EUROHUB.dbo.RSI_DIM_SILO 
	where BUILD_NUMBER>='6940' and BUILD_NUMBER<'7004'  and Type='S' and Status='A'
) as a
"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$TotalCount=$silo.Coun
	$hub=$silo.hub
	$Percent=[int]($index*100/$TotalCount)
	write-host "--$Percent%"
	.\hotfix_silo.ps1 -databaseServer $dbserver -databasename $dbname -hub $hub -SiloName $siloId 
	$index=$index+1
}
write-host "finished!"
