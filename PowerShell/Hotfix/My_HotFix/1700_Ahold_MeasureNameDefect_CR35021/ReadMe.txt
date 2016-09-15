==This Hot Fix is for 7004 release to correct a measure name (remove 'Test' in meausre name 'Test Store Receipt Volume Units 5 Days prior Ad Break LNE') for 'Ahold' retailer.==


The '1700_Ahold_MeasureNameDefect_CR35021' do the following steps.

1. In given hub database, loop each of retailer Silo.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Correct the measure name in the cube for the silo.

4. Enable Event Manager


-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1700-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1700_Ahold_MeasureNameDefect_CR35021.ps1' on hub server or Silo silo. Pass the hub server name, hub database name, build numer.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" 7004

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB" 7004

4.Update the silos under EUROHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "EUROHUB" 7004

5.Copy the latest Ahod.mdx file to related stage server under Ahold7004 build folder
  .\CopyFileToStageServer.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" 7004

6. Copy to the latest Ahold.mdx into Virsualnodefs manually.




