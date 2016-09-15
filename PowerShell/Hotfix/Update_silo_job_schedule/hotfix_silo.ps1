param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$SiloName="")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

SQLCMD -E -S $databaseServer -d $databaseName -o $currentPath\hotfix_silo.log -i $currentPath\hotfix_silo.sql -b -v SiloName="$SiloName" -v ServerName="$databaseServer" 

get-content $currentPath\hotfix_silo.log

