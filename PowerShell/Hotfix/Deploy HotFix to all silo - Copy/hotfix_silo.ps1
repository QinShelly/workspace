param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
write-host "Second Powshell $databaseServer $databaseName"
SQLCMD -E -S $databaseServer -d $databaseName -o $currentPath\hotfix_silo.log -i $currentPath\hotfix_silo.sql -b  

get-content $currentPath\hotfix_silo.log