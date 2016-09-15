$server1 = 'pvd1wnfs99s.colo.retailsolutions.com'	
$db1 = 'COTY_WALGREENS'
$server2= 'prodp1fs134.colo.retailsolutions.com\STAGE'	
$db2 = 'DANNON_AHOLD'
$server3 = 'prodp1fs156.colo.retailsolutions.com\STAGE'
$db3 =	'CONAGRA_FOODLION'

$start = Get-Date
#$code = {Start-Sleep -Seconds 2; "Hello"}
$code = { E:\Ken\SSAS_Info\multirunsql\silo.ps1 -databaseServer 'pvd1wnfs99s.colo.retailsolutions.com' -databasename 'COTY_WALGREENS' }
   
$newPowerShell = [PowerShell]::Create().AddScript($code)
#$newPowerShell.Invoke()

$handle = $newPowerShell.BeginInvoke()
   
while ($handle.IsCompleted -eq $false) {
  Write-Host '.' -NoNewline
  Start-Sleep -Milliseconds 500
}
   
Write-Host ''
$newPowerShell.EndInvoke($handle)
$newPowerShell.Runspace.Close()
$newPowerShell.Dispose()
<#
.\silo.ps1 -databaseServer $server1 -databasename $db1
.\silo.ps1 -databaseServer $server2 -databasename $db2
.\silo.ps1 -databaseServer $server3 -databasename $db3 
$result1, $result2, $result3 = Receive-Job $alljobs
#>

<#
$job1 = Start-Job -ScriptBlock { E:\Ken\SSAS_Info\multirunsql\silo.ps1 $args[0] $args[1] } -ArgumentList @($server1, $db1)
$job2 = Start-Job -FilePath .\silo.ps1 -ArgumentList $server2,$db2
$job3 = Start-Job -FilePath .\silo.ps1 -ArgumentList $server3,$db3

$alljobs = Wait-Job $job1, $job2,$job3
#>
$end = Get-Date
$timespan = $end - $start
$seconds = $timespan.TotalSeconds

Write-Host "total time cost $seconds seconds"