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
$sql="select DB_SERVERNAME,DB_NAME,siloid,count(1)over() as Coun from RSI_DIM_SILO where BUILD_NUMBER='$buildnumer'"
write-host $sql
write-host "dbserver:$databaseServer dbname:$databaseName"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$TotalCount=$silo.Coun
	$Percent=[int]($index*100/$TotalCount)
	write-host "--$Percent%"
	.\hotfix_silo.ps1 -databaseServer $dbserver -databasename $dbname -hub $databaseName -SiloName $siloId -BuildNumber $buildnumer
	$index=$index+1
}
write-host "finished!"
