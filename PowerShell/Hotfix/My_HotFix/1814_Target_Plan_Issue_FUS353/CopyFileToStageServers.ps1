param($databaseServer="eng1wnqa2.colo.retailsolutions.com",
$databaseName="MASTERDATA_PLUTO",
$buildnumer=7005)

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
		select 
		distinct DB_SERVERNAME 
		from(
		select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
		,DB_NAME,siloid,Type  from eurohub.dbo.RSI_DIM_SILO 
		where  status in('a') and BUILD_NUMBER='7005' and Type  in('S')
		union all
		select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
		,DB_NAME,siloid,Type  from GAHUB.dbo.RSI_DIM_SILO 
		where  status in('a') and BUILD_NUMBER='7005' and Type in('S')
		union all
		select replace(replace(REPLACE(replace(DB_SERVERNAME,char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME
		,DB_NAME,siloid,Type  from CNHUB.dbo.RSI_DIM_SILO 
		where  status in('a') and BUILD_NUMBER='7005' and Type in('S')
		) as a
	)as a
) as b

"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1

foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$Percent=[int]($index*100/56)
	
	$SourceFolder="$currentPath\scripts\"
	$DestinationFolder="\\$dbserver\c`$\RSI\Fusion\release\Fusion7005\release\scripts\"
	
	
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
