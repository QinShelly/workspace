
1.Open powershell as administrator


2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "WAL1WNFSHUB.colo.retailsolutions.com" "GAHUB" 6940

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "WAL1WNFSHUB.colo.retailsolutions.com" "CNHUB" 6940

4.Update the silos under EUROHUB by run the command
  .\runfromhub.ps1 "WAL1WNFSHUB.colo.retailsolutions.com" "EUROHUB" 6940


QA steps:

1.prepare silos with 6940 version and hub 7000
2.run PS as DEV listed.
3.check job schedule:changed to run per 3 hours
4.after run one day, check job history.