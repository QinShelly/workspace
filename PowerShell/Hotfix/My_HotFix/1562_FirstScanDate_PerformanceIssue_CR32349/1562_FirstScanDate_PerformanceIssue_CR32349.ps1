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
	$Internalx_Initial = '([Calendar].[Date].[Date].MEMBERS, [Measures].[First Scan Date Internalx]) = (root([Calendar]), [First Scan Date Internal]);'
	$Internalx_Replace = '([Calendar].[Date].[Date].MEMBERS, [Measures].[First Scan Date Internalx]) = (root([Calendar]), [First Plan Date Internal],[UNIQUES TYPE].[TY SCAN].&[1], [DISTINCT TYPE].[KEY TYPE].&[1]);'
	
	$SVR_Internalxx_Initial = 'create member currentcube.[Measures].[First Scan Date Internalxx] as (root([Calendar]), [First Scan Date Internal]),visible=0;'	
	$CAT_Internalxx_Initial = 'create member currentcube.[Measures].[First Scan Date Internalxx] as'
	
	$Internalxx_Replace = 'create member currentcube.[Measures].[First Scan Date Internalxx] as (root([Calendar]), [First Plan Date Internal],[UNIQUES TYPE].[TY SCAN].&[1], [DISTINCT TYPE].[KEY TYPE].&[1]),visible=0;'
	
	$siloCubeDB = $cubeServer.Databases.findByname($siloCubeDBName)
	$siloCube = $siloCubeDB.Cubes.FindByName($siloCubeName)
		
	$mdxScript = $siloCube.MdxScripts[0].Commands[0].Text
	$mdxLength_Initial=$mdxScript.Length

	$IsExisted_Internalx = $mdxScript.IndexOf($Internalx_Initial)
	
	$OutPutMessage="Internalx:"
	#If the cube existes this mdx, then need to deploy this hotfix
	if($IsExisted_Internalx -gt 0)
	{	
		$OutPutMessage="$OutPutMessage Find "
		$mdxScript = $mdxScript.replace($Internalx_Initial,$Internalx_Replace)
		$IsExisted_Internalx = $mdxScript.IndexOf($Internalx_Initial)
		if($IsExisted_Internalx -gt 0)
		{
			Add-Content $logFailed "`n select '$siloId' as name union all"	
			Write-Host "$OutPutMessage but failed to replaced,SiloType=$SiloType,SiloId=$siloId "
		}
	}
	else 
	{
		Add-Content $logSucceed "`n select '$siloId' as name union all"	
		Write-Host "$OutPutMessage Doesn't find,SiloType=$SiloType,SiloId=$siloId "
	}
	
	$OutPutMessage="Internalxx:"
	#Current silo is SVR
	if($SiloType -eq "S")
	{
		$IsExisted_InternalxxSVR = $mdxScript.IndexOf($SVR_Internalxx_Initial)
		if($IsExisted_InternalxxSVR -gt 0)
		{	
			$OutPutMessage="$OutPutMessage Find "
			$mdxScript = $mdxScript.replace($SVR_Internalxx_Initial,$Internalxx_Replace)
			$IsExisted_InternalxxSVR = $mdxScript.IndexOf($SVR_Internalxx_Initial)
			if($IsExisted_InternalxxSVR -gt 0)
			{
				Add-Content $logFailed "`n select '$siloId' as name union all"	
				Write-Host "$OutPutMessage but failed to replaced,SiloType=$SiloType,SiloId=$siloId "
			}
		}
		else 
		{
			Add-Content $logSucceed "`n select '$siloId' as name union all"	
			Write-Host "$OutPutMessage Doesn't find,SiloType=$SiloType,SiloId=$siloId "
		}
	}
	#Current silo is CAT
	else
	{
	write-host "tom=>cat"
		$IsExisted_InternalxxCAT = $mdxScript.IndexOf($CAT_Internalxx_Initial)
		$CatIsAlreadyExisted=$mdxScript.IndexOf('create member currentcube.[Measures].[First Scan Date Internalxx] as (root([Calendar]), [First Plan Date Internal],[UNIQUES TYPE].[TY SCAN].&[1], [DISTINCT TYPE].[KEY TYPE].&[1]),visible=0;')
		if($IsExisted_InternalxxCAT -gt 0)
		{	
			if($CatIsAlreadyExisted -gt 0)
			{
			  Write-Host "Cat silo already updated"
			  $IsExisted_InternalxxCAT = $mdxScript.IndexOf('(root([Calendar]), [First Scan Date Internal]),visible=0;')
				if($IsExisted_InternalxxCAT -gt 0)
				{
				
				}else
				
				{
				write-host 'Already deploy'
				Add-Content $logFailed "`n select '$siloId' as name union all"	
				}
			}else
			{
				$OutPutMessage="$OutPutMessage Find "
				$mdxScript = $mdxScript.replace($CAT_Internalxx_Initial,$Internalxx_Replace)
				$mdxScript = $mdxScript.replace('(root([Calendar]), [First Scan Date Internal]),visible=0;','')
				$IsExisted_InternalxxCAT = $mdxScript.IndexOf('(root([Calendar]), [First Scan Date Internal]),visible=0;')
				if($IsExisted_InternalxxCAT -gt 0)
				{
					Add-Content $logFailed "`n select '$siloId' as name union all"	
					Write-Host "$OutPutMessage but failed to replaced,SiloType=$SiloType,SiloId=$siloId "
				}
			}
		}
		else 
		{
			Add-Content $logSucceed "`n select '$siloId' as name union all"	
			Write-Host "$OutPutMessage Doesn't find,SiloType=$SiloType,SiloId=$siloId "
		}
	}
	
	$mdxLength_Final=$mdxScript.Length
	
	if($mdxLength_Initial -lt $mdxLength_Final)
	{
		#Update the MDX script to Cube.
		$siloCube.MdxScripts[0].Commands[0].Text = $mdxScript
		$siloCube.MdxScripts[0].Update()
		$Message="Succeed,SiloType=$SiloType,SiloId=$siloId"
		Add-Content $logSucceed "`n select '$siloId' as name union all"	
		Write-Host "$Message"
	}
	else
	{
		Add-Content $logSucceed "`n select '$siloId' as name union all"	
		Write-Host "Doesn't replace anything,SiloType=$SiloType,SiloId=$siloId "
	}
}
write-host "    Enable Event Manager"
disableEventManager $serverName $siloId $true
$cubeServer.Disconnect()