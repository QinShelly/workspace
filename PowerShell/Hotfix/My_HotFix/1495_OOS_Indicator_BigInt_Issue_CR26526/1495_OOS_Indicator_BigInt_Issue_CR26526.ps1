Param(
[string] $siloId = "Pepsico_Sains"
, [string]$serverName = "wal1wnqa3"
, [string]$cubeServerName = "wal1wnqa3"
, [string]$dbName = "Pepsico_Sains"
, [string]$cubeDBName = "Pepsico_Sains"
, [string]$cubeName = "Pepsico_Sains"
)

trap {'1495 Hot Fix failed ' -f $_.Exception.Message;
$cubeServer.disconnect();
break}
## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

[string]$hotfixno="1495"
[string] $siloCubeDBName = $cubeDBName
[string] $siloCubeName =$cubeName
[string] $siloDBName = $dbName

write-host "start apply hotfix for $siloId"
write-host "Disabling Event Manager"
$cubeServer = New-Object Microsoft.AnalysisServices.Server


$cubeServer.connect("Data Source=$cubeServerName;Connect Timeout=600;")

$d = $cubeServer.Databases.Item($cubeDBName)

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript + '.\include.ps1')

$cube = $d.Cubes.Item($cubeName)

$integerFormat="#,###"

$storeFactMeasureGroup = $cube.MeasureGroups.Item("Store Sales")

dealMeasureGroup ([REF]$storeFactMeasureGroup) "dbo_STORE_SALES" "OOS Indicator" "OOS Indicator" "" $integerFormat "3" $false "BigInt" "BigInt"
dealMeasureGroup ([REF]$storeFactMeasureGroup) "dbo_STORE_SALES" "OOS Indicator" "Store Out of Stock Indicator" "Inventory\On Hand" $integerFormat "0" $true "BigInt" "BigInt"

$storeFactMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)

$cubeServer.Disconnect()
Write-Host "Successfully updated the Hot Fix $hotfixno"