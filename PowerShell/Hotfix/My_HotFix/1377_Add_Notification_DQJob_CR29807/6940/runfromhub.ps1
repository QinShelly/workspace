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
	$currentjobs += $siloId + '#DQCheckSiloGAPJob'
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
,DB_NAME,siloid,count(1)over() AS Coun from RSI_DIM_SILO where BUILD_NUMBER='$buildnumer' AND type in('s')"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	$sql="select count(1) cnt from msdb.dbo.sysjobs 
	where name ='$siloId#DQCheckSiloGAPJob' 
	and notify_level_email=0 
	and notify_email_operator_id=0
	"
	
	$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
	if ($count -eq 0)
	{
		write-host "$Percent% Already deployed:$dbname on server $dbserver"
	} 
	else 
	{
		$run = jobsRunning $dbserver $siloId
		if ($run)
		{
			write-host "$Percent% Job Running:$siloId on server $dbserver"
		} 
		else 
		{
			.\hotfix_silo.ps1 -databaseServer $dbserver -databasename $dbname 
			write-host "$Percent%"
		}
	}
	$Index=$Index+1
}
write-host "finished!"
