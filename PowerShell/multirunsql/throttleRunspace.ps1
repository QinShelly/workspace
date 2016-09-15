$throttleLimit = 5
$iss = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$Pool = [runspacefactory]::CreateRunspacePool(1, $throttleLimit, $iss, $Host)
$Pool.Open()
 
$ScriptBlock = {
    param($id, $id2)
    Start-Sleep -Seconds 2
    "Done processing ID $id $id2"
}
$threads = @()

$handles = for ($x = 1; $x -le 40; $x++) {
    $powershell = [powershell]::Create().AddScript($ScriptBlock).AddArgument($x).AddArgument($x)
    $powershell.RunspacePool = $Pool
    $powershell.BeginInvoke()
    $threads += $powershell
}

do {
  $i = 0
  $done = $true
  foreach ($handle in $handles) {
    if ($handle -ne $null) {
      if ($handle.IsCompleted) {
        $threads[$i].EndInvoke($handle)
        $threads[$i].Dispose()
        $handles[$i] = $null
      } else {
        $done = $false
      }
    }
    $i++
  }
  if (-not $done) { Start-Sleep -Milliseconds 500 }
} until ($done)