Param([string]$ServerName ="10.172.36.34"
)

#load as assembly
[Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")>$null

$d=get-date
write-host $d

#get server capacity
$ServerMemory = Get-WMIObject -class win32_physicalmemory -computer $ServerName
$ServerTotalMemory = ($ServerMemory |measure-object 'capacity' -sum).sum
Write-Host "Server " $ServerName " memory capacity is" ($ServerTotalMemory/1GB) "GB"


#get analysis services
[Array]$AsServices = get-service -computername $ServerName | where-object {$_.name -like "MS*OLAP*"}
for ($i=0; $i -le $AsServices.GetUpperBound(0); $i++) { #get each instance TotalMemoryLimit configuration
  if ($AsServices[$i].Name -eq "MSSQLServerOLAPService") {$ConnectionString=$ServerName}
  elseif ($AsServices[$i].Name -like "MSOLAP`$*")
    {$ConnectionString=$AsServices[$i].Name
     $ConnectionString=$ConnectionString.replace("MSOLAP`$",$ServerName+"\")
    } #ref: https://msdn.microsoft.com/en-us/library/hh230806.aspx
  
  $AsServer=New-Object Microsoft.AnalysisServices.Server
  $AsServer.connect($ConnectionString)
  [float]$AsTotalMemoryLimit = ($AsServer.ServerProperties | WHERE {$_.Name -eq 'Memory\TotalMemoryLimit'}).Value
  $AsServer.disconnect()
  
  Write-Host $ConnectionString ": TotalMemoryLimit is: "$AsTotalMemoryLimit"%, which is "($ServerTotalMemory*$AsTotalMemoryLimit/100/1GB)" GB"
}

#get process memory
$ProcessList = Get-WmiObject Win32_Process -ComputerName $ServerName
#$ProcessList | where {$_.name -eq "msmdsrv.exe"} |select @{expression="name";width=50;alignment="left"},{$_.workingsetsize/1GB}|format-table
$ProcessList | where {$_.name -eq "msmdsrv.exe"} |format-table @{expression="path";width=50;alignment="right"}, @{expression={$_.workingsetsize/1GB};width=30;alignment="right"}

