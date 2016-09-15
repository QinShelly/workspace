
1.Open powershell as administrator


2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" 6940

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB" 6940

4.Update the silos under EUROHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "EUROHUB" 6940
QA steps: Alsson
1.run ps in hub server eng1wnqa2 with right properties,and check silo is in 6940 build.
2.6940 silo on this hub has been applied this hotfix and check alert table flag is Y
