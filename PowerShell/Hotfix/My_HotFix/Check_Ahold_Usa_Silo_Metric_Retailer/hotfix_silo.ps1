Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
, [string]$SiloType = "S"
)

trap {'1513 Hot Fix failed ' -f $_.Exception.Message;
Add-Content $logFailed "`n select '$siloId' as name union all"	
$cubeServer.disconnect();
break}
## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
$logSucceed= "$currentPath\Succeed.txt"
$logFailed= "$currentPath\Failed.txt"
$logJobRunning= "$currentPath\JobRuning.txt"

function jobsRunning
{
Param([string] $sqlserver, [string] $siloId)
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
	$cubejobs =@()
	$cubejobs += $siloId + '#MDCubeProcess'
	$cubejobs += $siloId + '#CubeSecurity'
	$cubejobs += $siloId + '#OraSpokeETL'
	$cubejobs += $siloId + '#UpdatePartition'
	$cubejobs += $siloId + '#AttributeAutomation'
	$cubejobs += $siloId + '#FullCubeProcess'

	foreach($job in $srv.JobServer.Jobs) 
	{
		if($cubejobs -contains $job.name -and $job.CurrentRunStatus -eq 1) {
			Write-Host $job.name $job.CurrentRunStatus
			Add-Content $logJobRunning "`n select '$siloId' as name, '$SiloType' as silotype, 'Failed' as L union all"
			return $true
		}

	}
	Write-Host "    No jobs running"
	return $false
}

function disableEventManager
{
Param([string] $sqlserver, [string] $siloId , [boolean] $enable)
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
	$jobName = $siloId + '#EventManager'
	$job = $srv.JobServer.Jobs | where {$_.name -eq $jobName}
	$job.IsEnabled = $enable
	$job.alter()
}

[string]$hotfixno="1513"
[string] $siloCubeDBName = $cubeDBName
[string] $siloCubeName =$cubeName
[string] $siloDBName = $dbName

write-host "    Disabling Event Manager"
$cubeServer = New-Object Microsoft.AnalysisServices.Server
disableEventManager $serverName $siloId $false
$run = jobsRunning $serverName $siloId

$cubeServer.connect("Data Source=$cubeServerName;Connect Timeout=600;")

if(!$run) 
{	
	$Internalxx_Check = 'create member currentcube.[Measures].[First Scan Date Internalxx] as (root([Calendar]), [First Plan Date Internal],[UNIQUES TYPE].[TY SCAN].&[1], [DISTINCT TYPE].[KEY TYPE].&[1]),visible=0;'
	
	$siloCubeDB = $cubeServer.Databases.findByname($siloCubeDBName)
	$siloCube = $siloCubeDB.Cubes.FindByName($siloCubeName)
		
	$mdxScript = $siloCube.MdxScripts[0].Commands[0].Text
	$mdxLength_Initial=$mdxScript.Length

	$IsExisted = $mdxScript.IndexOf($Internalxx_Check)
	
	if($IsExisted -gt 0)
	{	
		Add-Content $logSucceed "`n select '$siloId' as name, '$SiloType' as silotype, 'Succeed' as L union all"	
		Write-Host "Succeed"
	}
	else 
	{
		Add-Content $logFailed "`n select '$siloId' as name, '$SiloType' as silotype, 'Failed' as L union all"
		Write-Host "Failed,SiloType=$SiloType,SiloId=$siloId "
	}
}
write-host "    Enable Event Manager"
disableEventManager $serverName $siloId $true
$cubeServer.Disconnect()