param($databaseServer="ENG1WNQA10.colo.retailsolutions.com\MB",
$databaseName="KNCLRK_TOYS",
$PeriodKey="20130209",
$measureName="[Measures].[Store Authorized Indicator]")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

##import-module "$currentPath\sqlps.ps1"

$sql="
UPDATE [dbo].[RSI_DQ_VARIANCE_INFO]
SET    AlertStatus = 0
WHERE  MeasureName = '$measureName'
       AND periodKey = '$PeriodKey' 
"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

write-host "Completed"

