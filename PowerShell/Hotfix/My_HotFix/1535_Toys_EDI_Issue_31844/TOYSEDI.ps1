Param([string]$serverName="localhost"
	, [string]$cubeServerName="localhost"
	, [string]$dbName="KCC_TOYS"
	, [string]$cubeDBName ="KCC_TOYS"
	, [string]$cubeName="KCC_TOYS")

trap {'Metrics Automation Failed {0}' -f $_.Exception.Message; break}

## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript + '.\..\include.ps1')

## Connect to the Cube
$server = New-Object Microsoft.AnalysisServices.Server
$server.connect($cubeServerName)
$d = $server.Databases.Item($cubeDBName)

Write-Output ("Custom Toys R US EDI Cube Changes : {0}" -f $d.Name)

$cube = $d.Cubes.Item($cubeName)


$ssMeasureGroup = $cube.MeasureGroups.Item("STORE SALES")

$dcMeasureGroup = $cube.MeasureGroups.Item("DC SHIPMENT")

$integerFormat="$#,##0.00"

dealMeasureGroup ([ref]$ssMeasureGroup) "dbo_STORE_SALES" "Store On Hand Amount" "Store On Hand Amount" "Inventory\On Hand" $integerFormat "1" 
dealMeasureGroup ([ref]$dcMeasureGroup) "dbo_DC_SHIPMENT" "DC On Hand Amount" "DC On Hand Amount" "Inventory\On Hand" $integerFormat "1"

$ssMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)
$dcMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)

$server.disconnect()
Write-Output ("Done!")