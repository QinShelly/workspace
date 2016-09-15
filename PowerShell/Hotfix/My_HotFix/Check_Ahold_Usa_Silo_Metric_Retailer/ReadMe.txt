==This Hot Fix is for 6940,7000,7001 releases to fix the performance issue of member [First Scan Date]==


The '1562_FirstScanDate_PerformanceIssue_CR32349' do the following steps.

1. In given hub database, loop each of 6940,7000,7001 Silo.
   1.1 If pass the special siloId, will only deploy this hotfix to the special SiloId.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Replace the mdx which has performance issue to a new one in the cube for the silo.

4. Enable Event Manager


-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1562-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1562_FirstScanDate_PerformanceIssue_CR32349' on hub server or Silo silo. Pass the hub server name, hub database name, 
SiloId(Option).e.g.

1.Open powershell as administrator

2.Update all the 6940,7000,7001 silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB"

  2.1 Update the special silo under GAHUB by run the command
      .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB" "<SiloId>"

3.Update all the 6940,7000,7001 silos under CNHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB"

  3.1 Update the special silo under CNHUB by run the command
      .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB" "<SiloId>"

4.Update all the 6940,7000,7001 silos under EUROHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "CNHUB"

  4.1 Update the special silo under EUROHUB by run the command
      .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "EUROHUB" "<SiloId>"



