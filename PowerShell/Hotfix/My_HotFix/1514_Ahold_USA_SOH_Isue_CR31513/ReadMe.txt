==This is Hot Fix is for 6940 release to remove the dulplicated definition of some cases/units meausres (such as "[Store On Hand Volume Cases]") in 'Ahold' retailer.==


The '1514_Ahold_USA_SOH_Isue_CR31513' do the following steps.

1. In given hub database, loop each of retailer Silo.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. remove the dulplicated definition of those measures in the cube for the silo.

4. Enable Event Manager


-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1514-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1514_Ahold_USA_SOH_Isue_CR31513.ps1' on hub server or Silo silo. Pass the hub server name, hub database name, build numer.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" 6940

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB" 6940

4.Update the silos under EUROHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "EUROHUB" 6940




