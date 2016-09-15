
$myitems = 
@([pscustomobject]@{server="pvd1wnfs99s.colo.retailsolutions.com";db="COTY_WALGREENS"},
[pscustomobject]@{server="prodp1fs134.colo.retailsolutions.com\STAGE";db="DANNON_AHOLD"},
[pscustomobject]@{server="prodp1fs156.colo.retailsolutions.com\STAGE";db="CONAGRA_FOODLION"})
$start = Get-Date
<#
.\silo.ps1 -databaseServer $server1 -databasename $db1
.\silo.ps1 -databaseServer $server2 -databasename $db2
.\silo.ps1 -databaseServer $server3 -databasename $db3 
$result1, $result2, $result3 = Receive-Job $alljobs
#>
$job1 = Start-Job -ScriptBlock { E:\Ken\SSAS_Info\multirunsql\silo.ps1 $args[0] $args[1] } -ArgumentList @($myitems[0].server, $myitems[0].db)
#$job1 = Start-Job -FilePath .\silo.ps1 -ArgumentList $server1,$db1
$job2 = Start-Job -FilePath .\silo.ps1 -ArgumentList $myitems[1].server,$myitems[1].db
$job3 = Start-Job -FilePath .\silo.ps1 -ArgumentList $myitems[2].server,$myitems[2].db

$alljobs = Wait-Job $job1, $job2,$job3

$end = Get-Date
$timespan = $end - $start
$seconds = $timespan.TotalSeconds

Write-host "total time cost $seconds seconds"