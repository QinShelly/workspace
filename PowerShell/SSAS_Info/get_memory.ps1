Param([string]$ServerName ="prodp1fs125.colo.retailsolutions.com"
,[int]$numberOfProcessToShow=10
)

#load as assembly
#[Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")>$null

$d=get-date
write-host $d

#get server capacity
$ServerMemory = Get-WMIObject -class win32_physicalmemory -computer $ServerName
$ServerTotalMemory = ($ServerMemory |measure-object 'capacity' -sum).sum
Write-Host "Server " $ServerName " total memory is " ($ServerTotalMemory/1GB | % { '{0:N2}' -f $_ }) "GB"

#get process memory
$ProcessList = Get-WmiObject Win32_Process -ComputerName $ServerName

$ProcessTotalMemory = ($ProcessList |measure-object 'WorkingSetSize' -sum).sum
Write-Host "Server " $ServerName "  used memory is " ($ProcessTotalMemory/1GB | % { '{0:N2}' -f $_ }) "GB"

Write-Host "Memory used " ($ProcessTotalMemory/$ServerTotalMemory | % { "{0:P2}" -f $_ } )

$ProcessList | Sort-Object WorkingSetSize -descending |
 format-table @{expression="caption";width=30;alignment="right"}, @{expression={$_.workingsetsize/1GB |
  % { '{0:N2}' -f $_ }};width=15;alignment="right"; label="WorkingSetSize GB"}, @{expression={$_.GetOwner().User};label="Owner";width=20;alignment="right"}, @{expression="CommandLine";width=50;alignment="right"} |
  select -first $numberOfProcessToShow

