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

$sql="select 
replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
,DB_NAME,siloid,count(1)over()as Coun from RSI_DIM_SILO where BUILD_NUMBER='$buildnumer'   AND type in('s') "
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$dbname= $silo.DB_NAME
	$siloId= $silo.siloid
	
	$sql=" select count(*) as cnt FROM msdb.dbo.sysjobs WHERE name ='$dbname#DQCheckSiloGAPJob'"
	$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
	
	if($count -gt 0)
	{
		$sql="
		SELECT COUNT(1) as cnt
FROM   msdb.dbo.sysjobschedules AS jobs
INNER JOIN msdb.dbo.sysschedules AS s
ON jobs.schedule_id = s.schedule_id
WHERE  s.name = N'Every 6 hours daily'
AND jobs.job_id = (select job_id FROM msdb.dbo.sysjobs WHERE name='$dbname#DQCheckSiloGAPJob')

		"
		$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
		if($count -eq 1)
		{
			write-host "select '$siloId' as silo_id,'$dbserver' as db_server union all "
		}
	}
}
write-host "finished!"
