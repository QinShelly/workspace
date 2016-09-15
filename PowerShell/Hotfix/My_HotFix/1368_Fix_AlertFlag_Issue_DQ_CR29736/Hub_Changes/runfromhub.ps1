param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB")


$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

function jobsRunning
{
Param([string] $sqlserver, [string] $siloId)
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
	$cubejobs =@()
	$cubejobs += $databaseName + '#DQSendAlertEmailJob'
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
$sql="select COUNT(1)as coun from msdb.dbo.sysjobs
where name='$databaseName#DQSendAlertEmailJob' "
write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$coun= $silos[0].coun
$run = jobsRunning $databaseServer $databaseName
if ($run)
{
    write-host "jobs is running"
} 
else 
{
	if($coun-eq 1)
	{
		.\hotfix_silo.ps1 -databaseServer $databaseServer -databasename $databaseName
	}
}
write-host "finished!"
