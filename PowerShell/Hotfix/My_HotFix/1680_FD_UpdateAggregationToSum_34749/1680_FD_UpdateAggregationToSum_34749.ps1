Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
)

trap {'Hot Fix failed ' -f $_.Exception.Message;
	Add-Content $logFailed "`n select '$siloId' as name,'Failed' Lag union all"	
$cubeServer.disconnect();break}
## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
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
			Add-Content $logFailed "`n select '$siloId' as name,'Job Running' Lag union all"	
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


write-host "Disabling Event Manager"
$cubeServer = New-Object Microsoft.AnalysisServices.Server
disableEventManager $serverName $siloId $false
$run = jobsRunning $serverName $siloId

$cubeServer.connect("Data Source=$cubeServerName;Connect Timeout=600;")

$d = $cubeServer.Databases.Item($cubeDBName)

$cube = $d.Cubes.Item($cubeName)

if(!$run) 
{
	$dcMeasureGroup = $cube.MeasureGroups.Item("DC SHIPMENT")
	$ssMeasureGroup = $cube.MeasureGroups.Item("STORE SALES")

	$StoreSalesAmounts="Store Receipts Amount","Store Transfer Amount","Warehouse Store Receipts Amount","Total Damaged Amount"

	foreach ($metric in $StoreSalesAmounts)
	{
		if($ssMeasureGroup.Measures.FindByName($metric))
		{
			$ssMeasureGroup.Measures.FindByName($metric).AggregateFunction = "Sum"
		}
	}

	if($dcMeasureGroup.Measures.FindByName("DC Shipment Amount"))
	{
		$dcMeasureGroup.Measures.FindByName("DC Shipment Amount").AggregateFunction = "Sum"
	}

	$ssMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)
	$dcMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)
}
write-host "Enable Event Manager"
disableEventManager $serverName $siloId $true
$cubeServer.Disconnect()