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
where BUILD_NUMBER = 7004 and Status = 'a'

union all
select distinct  DB_SERVERNAME from cnhub.dbo.rsi_dim_silo
where BUILD_NUMBER = 7004 and Status = 'a'

union all
select distinct DB_SERVERNAME from eurohub.dbo.rsi_dim_silo
where BUILD_NUMBER = 7004 and Status = 'a'

)as a


"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1

$CsvFiles="SDRUG.mdx"

$VirtualNodes="\\virtualnodefs\RSI\Fusion\App\data\metrics\"
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$Percent=[int]($index*100/56)
	
	foreach($csvfile in $CsvFiles)
	{
		$CurrentCsvFilePath=$VirtualNodes+$csvfile
		
		$Destination="\\$dbserver\c`$\RSI\Fusion\release\Ozark7001\release\scripts\cubes\dsm\custom\"
		Copy-Item -Path $CurrentCsvFilePath -Destination $Destination -Force
		
		$DestinationFile=$Destination+$csvfile
		
		if(Test-Path ($DestinationFile)){
			write-host "----- $dbserver"
		}
		else
		{
			write-host "XXXXX $dbserver"
		}
	}
	
	write-host "$Percent%"

	$Index=$Index+1
}
write-host "finished!"
