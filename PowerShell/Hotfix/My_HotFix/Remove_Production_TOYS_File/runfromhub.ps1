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
$sql="
select 
distinct
replace(replace(REPLACE(replace(replace(DB_SERVERNAME,'\stage',''),char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
from
(
select distinct DB_SERVERNAME from gahub.dbo.rsi_dim_silo
where BUILD_NUMBER = 7001 and Status = 'a'

union all
select distinct  DB_SERVERNAME from cnhub.dbo.rsi_dim_silo
where BUILD_NUMBER = 7001 and Status = 'a'

union all
select distinct DB_SERVERNAME from eurohub.dbo.rsi_dim_silo
where BUILD_NUMBER = 7001 and Status = 'a'

)as a


"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$Percent=[int]($index*100/52)
	
	$Toys_ps1="\\$dbserver\c`$\RSI\Fusion\release\Ozark7001\release\scripts\cubes\dsm\custom\TOYS.ps1"
	if(Test-Path $Toys_ps1){
		write-host "Toys_ps1 1 $dbserver"
		remove-item -Path $Toys_ps1
	}
	else{
	write-host "Toys_ps1 0 $dbserver"
	}
	$Toys_sql="\\$dbserver\c`$\RSI\Fusion\release\Ozark7001\release\scripts\rdbms\dsm\custom\TOYS.sql"
	if(Test-Path $Toys_sql){
		write-host "Toys_sql 1 $dbserver"
		remove-item -Path $Toys_sql
	}
	else{
	write-host "Toys_sql 0 $dbserver"
	}
	$Toys_sqlp="\\$dbserver\c`$\RSI\Fusion\release\Ozark7001\release\scripts\rdbms\dsm\custom\TOYS.sqlp"
	if(Test-Path $Toys_sqlp){
		write-host "Toys_sqlp 1 $dbserver"
		remove-item -Path $Toys_sqlp
	}
	else{
	write-host "Toys_sqlp 0 $dbserver"
	}
	
	write-host "$Percent%"

	$Index=$Index+1
}
write-host "finished!"
