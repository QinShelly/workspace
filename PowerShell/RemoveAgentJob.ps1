[System.Reflection.Assembly]:: LoadWithPartialName("Microsoft.SqlServer.SMO")

$serverInstance = New-Object ( "Microsoft.SqlServer.Management.Smo.Server" ) "localhost"

foreach ($jobs in ( $serverInstance.JobServer.Jobs `
| Where-Object { $_.Name -match "Hub_Shanghai" } `
| Select-Object -First 100 ))
{
 write-host "remove " $jobs.Name
 $jobs.drop()
} 
