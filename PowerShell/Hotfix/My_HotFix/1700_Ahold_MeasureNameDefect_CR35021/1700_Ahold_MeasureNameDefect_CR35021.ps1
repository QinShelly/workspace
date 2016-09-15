Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
, [string]$SiloType = "S"
)

trap {'1700 Hot Fix failed ' -f $_.Exception.Message;
Add-Content $logFailed "`n select '$siloId' as name union all"	
$cubeServer.disconnect();
break}
## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
$logSucceed= "$currentPath\Succeed.txt"
$logFailed= "$currentPath\Failed.txt"

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
			Add-Content $logFailed "`n select '$siloId' as name,'Job Running' as lag union all"	
			Write-Host $job.name $job.CurrentRunStatus
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

[string]$hotfixno="1700"
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
	$AddMdx   ='[Measures].[Store Receipt Volume Units-5 Days prior Ad Break] = sum({existing [CALENDAR].[Ahold Ad Calendar Name].[Ahold Ad Calendar Name].MEMBERS},[Measures].[Store Receipt Volume Units 5 Days prior Ad Break LNE]);'
	$siloCubeDB = $cubeServer.Databases.findByname($siloCubeDBName)
	$siloCube = $siloCubeDB.Cubes.FindByName($siloCubeName)
	$mdxScript = $siloCube.MdxScripts[0].Commands[0].Text
	
	$NeedToDeploy=$mdxScript.IndexOf($AddMdx)
	
	if($NeedToDeploy -lt 1)
	{
		Write-Host "This silo needs deploy"
		
		$mdxScript = $mdxScript+$AddMdx;
		
		#Update the MDX script to Cube.
		$siloCube.MdxScripts[0].Commands[0].Text = $mdxScript
		$siloCube.MdxScripts[0].Update()
		
		$mdxScript = $siloCube.MdxScripts[0].Commands[0].Text
		
		$IsSucceed=$mdxScript.IndexOf($AddMdx)
		
		If($IsSucceed -gt 0)
		{
			$Message="Succeed,SiloType=$SiloType,SiloId=$siloId"
			Add-Content $logSucceed "`n select '$siloId' as name,'succeed' as lag union all"	
			Write-Host "$Message"
		}
		else
		{
			Add-Content $logFailed "`n select '$siloId' as name,'Failed to append as lag union all"	
			Write-Host "Failed to append,SiloType=$SiloType,SiloId=$siloId "
		}
	}
	else
	{
		$Message="Already fixed,SiloType=$SiloType,SiloId=$siloId"
		Add-Content $logSucceed "`n select '$siloId' as name,'already fixed' as lag union all"	
		Write-Host "$Message"
	}
}
write-host "    Enable Event Manager"
disableEventManager $serverName $siloId $true
$cubeServer.Disconnect()