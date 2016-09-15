param($databaseServer="",
$databaseName="",
$workingPath="E:\Ken\SSAS_Info\multirunsql")

#$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
write-host "Silo.ps1 called. Parameters: $databaseServer $databaseName"
SQLCMD -E -S $databaseServer -d $databaseName -i $workingPath\silo.sql  -o $workingPath\log\$databaseName.log -b  
