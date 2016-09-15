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
select * from
(
	select distinct
			replace(replace(REPLACE(replace(replace(DB_SERVERNAME,'\stage',''),char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
	from
	(
		select distinct DB_SERVERNAME from gahub.dbo.rsi_dim_silo
		where BUILD_NUMBER in ('7056') and Status = 'a'

		union all
		select distinct  DB_SERVERNAME from cnhub.dbo.rsi_dim_silo
		where BUILD_NUMBER in ('7056') and Status = 'a'

		union all
		select distinct DB_SERVERNAME from eurohub.dbo.rsi_dim_silo
		where BUILD_NUMBER in ('7056') and Status = 'a'

		union all
		select distinct DB_SERVERNAME from PILOTHUB.dbo.rsi_dim_silo
		where BUILD_NUMBER in ('7056') and Status = 'a'
		
	)as a
) as b
--where DB_SERVERNAME='prodp1fs133.colo.retailsolutions.com'

"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1



foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$Percent=[int]($index*100/56)
	
	$SourceFolder="C:\RSI\Fusion7005\Hot-Fix\MB\MB731\scripts\"
	$DestinationFolder="\\$dbserver\c`$\RSI\Fusion\release\7056\release\scripts\"
	
	
	write-host "$DestinationFolder"
	
	Get-ChildItem $SourceFolder -recurse | ForEach-Object -Process{
		if($_ -is [System.IO.FileInfo])
		{
			$FullName=$_.FullName.ToString()
			
			$SourceFileFullName=$FullName
			$DestinationFullName=$DestinationFolder+$FullName.replace($SourceFolder,"")
			
			Copy-Item -Path $SourceFileFullName -Destination $DestinationFullName -Force
			
			if(Test-Path ($DestinationFullName)){
			}
			else
			{
				write-host "Failed to copy $DestinationFullName"
			}
		}
	}
	
	write-host "$Percent%"

	$Index=$Index+1
}
write-host "finished!"
