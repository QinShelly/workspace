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
	$cubejobs =@()
	$cubejobs += $siloId + '#DQCheckSiloGAPJob'
	foreach($job in $srv.JobServer.Jobs) 
	{
		if($cubejobs -contains $job.name -and $job.CurrentRunStatus -eq 1) {
			Write-Host $job.name $job.CurrentRunStatus
			return $true
		}
	}
	Write-Host "No jobs running"
	return $false
}

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
$sql="select DB_SERVERNAME,DB_NAME,siloid from RSI_DIM_SILO where BUILD_NUMBER='$buildnumer' and type='S'"
write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$index=1
foreach ($silo in $silos){
  $dbserver= $silo.DB_SERVERNAME
  $dbname= $silo.DB_NAME
  $siloId= $silo.siloid
  $sql="SELECT COUNT(*) cnt FROM INFORMATION_SCHEMA.ROUTINES
 WHERE ROUTINE_NAME='sp`$RSI_DQ_SYNC_JOB' AND ROUTINE_DEFINITION like '%where GAP=%'"
  $count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
  if ($count -eq 1){
     write-host "database $dbname on server $dbserver already applied"
  } else {
     write-host "$dbname not applied on $dbserver"
     #$run = jobsRunning $dbserver $siloId
     if (0){
        write-host "jobs is running"
     } else {
        write-host "jobs is not running"
		write-host "$index/13 current dir is $currentPath"
		
		#Out-File -FilePath $currentPath\hotfix_silo.log "select '$siloId' AS SiloId,'$dbserver' AS dbserver union all "
        .\hotfix_silo.ps1 -databaseServer $dbserver -databasename $dbname 
     }
  }
  $index=$index+1
}
write-host "finished!"
