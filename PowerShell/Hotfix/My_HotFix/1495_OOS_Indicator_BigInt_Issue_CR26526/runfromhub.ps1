param($siloStageServer="wal1wnqa3.colo.retailsolutions.com",
$siloName="Pepsi_Kroger")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
write-host "current dir is $currentPath"
.\1495_OOS_Indicator_BigInt_Issue_CR26526.ps1 -siloId $siloName -serverName $siloStageServer -cubeServerName $siloStageServer  -dbName $siloName -cubeDBName $siloName -cubeName $siloName
write-host "Complete to deploy this hotfix to $siloName on $siloStageServer"
write-host "finished!"
