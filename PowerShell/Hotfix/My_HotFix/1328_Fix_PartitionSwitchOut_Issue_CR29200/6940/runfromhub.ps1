param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$buildnumer=6911)

#powershell C:\T3Ci\sandbox\daniel\scorecardColumnLength\runfromhub.ps1 PROD1ALTPTL1 MASTERDATA 6940
#
$releaseHash=@{6902='everest6902';6903='everest6903';6910='pluto6910';6911='pluto6911';6940='pluto6940'}

$releasename=$releaseHash[$buildnumer]

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

function jobsRunning
{
Param([string] $sqlserver, [string] $siloId)
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
	$currentjobs =@()
	$currentjobs += $siloId + '#UpdatePartition'
	foreach($job in $srv.JobServer.Jobs) 
	{
		if($currentjobs -contains $job.name -and $job.CurrentRunStatus -eq 1) {
			Write-Host $job.name $job.CurrentRunStatus
			return $true
		}
	}
	return $false
}

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
$sql="select 
replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid from RSI_DIM_SILO where BUILD_NUMBER='$buildnumer'   AND type in('s','C')"
write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$index=0
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$sql="SELECT case when datediff(hour,LAST_ALTERED,GETDATE())>1 then 'Error' else '     ' end as coun FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME='Sp`$rsi_upd_partition_function' "
	$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
	write-host "$count for $siloId on $dbserver"
}
write-host "finished!"
