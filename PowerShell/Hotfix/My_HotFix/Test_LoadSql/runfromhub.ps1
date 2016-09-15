param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="Fathom_CP")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
$sql="
select distinct SILO_ID,SERVER_NAME,count(1)over() as Coun from RSI_DEPLOY_EVENTS 
where TARGET_BUILD_NUMBER = 'ozark7001' 
and SILO_ID not like '%COCACOLA_AHOLD%'
and (ACTION = 'install' or ACTION = 'upgrade') 
and EVENT_TS <'2014-06-11'
"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.SERVER_NAME
	$dbname= $silo.SILO_ID
	$siloId= $silo.SILO_ID
	$Coun= $silo.Coun
	$Percent=[int]($index*100/$Coun)
	
	.\Test_Load.ps1 -siloId $siloId -serverName $dbserver -cubeServerName $dbserver  -dbName $dbname -cubeDBName $dbname -cubeName $dbname
	write-host "$Percent% Complete to deploy this hotfix to $dbname on $dbserver"

	$Index=$Index+1
}
write-host "finished!"
