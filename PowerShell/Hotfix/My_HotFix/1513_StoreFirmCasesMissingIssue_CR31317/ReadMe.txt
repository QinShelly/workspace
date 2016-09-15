==This is Hot Fix is for Ozark release to include the missed cases meausres (such as "Store Firm Receipts Volume Cases") in the retailer Safeway.==


The '1513_StoreFirmCasesMissingIssue_CR31317' do the following steps.

1. In given hub database, loop each of safeway Silo.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Add the missed measures in the cube for the silo.

4. Enable Event Manager


-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1513-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1513_StoreFirmCasesMissingIssue_CR31317.ps1' on hub server or Silo silo. Pass the hub server name, hub database name, build numer.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" 7000

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB" 7000

4.Update the silos under EUROHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "EUROHUB" 7000




