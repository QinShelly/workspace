param($databaseServer="eng1wnqa2.colo.retailsolutions.com",
$databaseName="MASTERDATA_PLUTO",
$buildnumer=6911)

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
			replace(replace(REPLACE(replace(replace(DB_SERVERNAME,'\stage',''),char(32),''),char(9),''),CHAR(10),''),CHAR(13),'') as DB_SERVERNAME,
			SiloId,
			BUILD_NUMBER
	from
	(
		select distinct DB_SERVERNAME,SiloId,BUILD_NUMBER from gahub.dbo.RSI_DIM_SILO 
		where   type in('S') AND status in('a') and RETAILER_NAME='ahold' and BUILD_NUMBER='$buildnumer'
		union all
		select distinct DB_SERVERNAME,SiloId,BUILD_NUMBER from cnhub.dbo.RSI_DIM_SILO 
		where   type in('S') AND status in('a') and RETAILER_NAME='ahold' and BUILD_NUMBER='$buildnumer'
		union all
		select distinct DB_SERVERNAME,SiloId,BUILD_NUMBER from eurohub.dbo.RSI_DIM_SILO 
		where   type in('S') AND status in('a') and RETAILER_NAME='ahold' and BUILD_NUMBER='$buildnumer'

	)as a
) as b
 order by 1
"
##write-host $sql
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$Index=1

##Collect unique stage server list
$StageServerList= [System.Collections.ArrayList]@()

foreach ($silo in $silos){
	$ServerName=$silo.DB_SERVERNAME
	if(-not $StageServerList.Contains($ServerName))
	{$StageServerList.Add($ServerName)}
}

##Updata stage server Ahold7004 release code
foreach ($server in $StageServerList){
	$dbserver= $server
	$ServerCount=$StageServerList.Count
	$Percent=[int]($index*100/$ServerCount)
	
	$SourceFileFullName="$currentPath\scripts\cubes\dsm\custom\AHOLD.mdx"
	$DestinationFullName="\\$dbserver\c`$\RSI\Fusion\release\Ahold7004\release\scripts\cubes\dsm\custom\AHOLD.mdx"
	
	Copy-Item -Path $SourceFileFullName -Destination $DestinationFullName -Force
	if(Test-Path ($DestinationFullName)){}else{
		write-host "Failed to copy $DestinationFullName"
	}
	write-host "$Percent%"
	$Index=$Index+1
}

Write-host "Finish all stage server Ahold7004 release code update"

##Update mdx file in stage server for each of silo in DomainConfig\cubes\dsm\custom
$Index=1
foreach ($silo in $silos){
	$dbserver= $silo.DB_SERVERNAME
	$SiloId=$silo.SiloId
	$Percent=[int]($index*100/56)
	
	$SourceFileFullName="$currentPath\scripts\cubes\dsm\custom\AHOLD.mdx"
	$DestinationFullName="\\$dbserver\c`$\RSI\Fusion\configuration\$SiloId-DomainConfig\cubes\dsm\custom\AHOLD.mdx"
		
	Copy-Item -Path $SourceFileFullName -Destination $DestinationFullName -Force
	if(Test-Path ($DestinationFullName)){}else{
		write-host "Failed to copy $DestinationFullName"
	}
	write-host "$Percent%"
	$Index=$Index+1
}
Write-host "Finish all silo DomainConfig code update"
