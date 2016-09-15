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
	
	$sql="SELECT COUNT(*) cnt FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME='SP`$RSI_DQ_CREATE_ALERT_INFO'"
	$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
	
	if($count -gt 0)
	{
		$sql="
		SELECT count(1) as cnt FROM sys.sql_modules 
		WHERE object_id = (OBJECT_ID(N'SP`$RSI_DQ_CREATE_ALERT_INFO'))
		and definition like '%--If the sales is not null,the first sub-vendor with the maximal sales should always be yes to alert%' "
		$count=@(Invoke-Sqlcmd -Query $sql -ServerInstance $dbserver -database $dbname -QueryTimeout 65535)[0].cnt
		if($count -eq 0)
		{
			write-host "select '$siloId' as silo_id,'$dbserver' as db_server union all "
		}
	}
}
write-host "finished!"
