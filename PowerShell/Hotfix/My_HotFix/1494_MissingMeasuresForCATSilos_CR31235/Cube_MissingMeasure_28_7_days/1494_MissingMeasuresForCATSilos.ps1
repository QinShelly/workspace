Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
)

trap {'1494 Hot Fix failed ' -f $_.Exception.Message;
$cubeServer.disconnect();
break}
## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

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
			return $true
		}

	}
	Write-Host "No jobs running"
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


[string]$hotfixno="1451"
[string] $siloCubeDBName = $cubeDBName
[string] $siloCubeName =$cubeName
[string] $siloDBName = $dbName

write-host "start apply hotfix for $siloId"
write-host "Disabling Event Manager"
$cubeServer = New-Object Microsoft.AnalysisServices.Server
disableEventManager $serverName $siloId $false
$run = jobsRunning $serverName $siloId

$cubeServer.connect("Data Source=$cubeServerName;Connect Timeout=600;")

if(!$run) 
{

	$findStrStart = 'CREATE MEMBER CURRENTCUBE.[Time Calculation].[Time Calculation].[28 Days] AS NULL'

	$siloCubeDB = $cubeServer.Databases.findByname($siloCubeDBName)
	$siloCube = $siloCubeDB.Cubes.FindByName($siloCubeName)
		
	$mdxScript = $siloCube.MdxScripts[0].Commands[0].Text
	
	$NoNeedToDeploy = $mdxScript.IndexOf($findStrStart)
	
	#If the cube doesn't contain the [28 days] or [7 days] then need to deploy this hotfix
	if($NoNeedToDeploy -lt 0)
	{	
		$mdxScript = $mdxScript + 
'
CREATE MEMBER CURRENTCUBE.[Time Calculation].[Time Calculation].[28 Days] AS NULL;
CREATE MEMBER CURRENTCUBE.[Time Calculation].[Time Calculation].[7 Days] AS NULL;
'

		#Update the MDX script to Cube.
		if($mdxScript -ne $null -and $mdxScript.length -gt 1)
		{
			$siloCube.MdxScripts[0].Commands[0].Text = $mdxScript
			$siloCube.MdxScripts[0].Update()
		}
		else 
		{
			write-host "The MDX Changes already applied to this Cube. No changes applied now"	
		}
		$siloCube.MdxScripts[0].Commands[0].Text = $mdxScript
		$siloCube.MdxScripts[0].Update()
	}
	else 
	{
		write-host "The MDX Changes already applied to this Cube. No changes applied now"	
	}
}
write-host "Enable Event Manager"
disableEventManager $serverName $siloId $true

$cubeServer.Disconnect()
Write-Host "Successfully updated the Hot Fix 1494"