#groupName 1
Start-Job -FilePath .\multigroupjob.ps1 -Name "Hotfix" -ArgumentList "1"
#groupName 2
Start-Job -FilePath .\multigroupjob.ps1 -Name "Hotfix" -ArgumentList "2"
#groupName 3
Start-Job -FilePath .\multigroupjob.ps1 -Name "Hotfix" -ArgumentList "3"
#groupName 4
Start-Job -FilePath .\multigroupjob.ps1 -Name "Hotfix" -ArgumentList "4"

Get-Job -name "Hotfix" | Wait-Job | out-null
Get-Job -name "Hotfix" | Receive-Job

#get-job -name "Hotfix" |remove-job