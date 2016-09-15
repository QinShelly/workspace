==This Hot Fix is to update some Amount metrics' aggregation from Last non empty to Sum in FD silos.==


The '1680_FD_UpdateAggregationToSum_34749' do the following steps.

1. In given database, loop each of 7001 Ahold Silo.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Update the measures' aggregation type in the cube for the silo.

4. Enable Event Manager

5. Invoke the FCP job on the silo


-----------------------------------------------------------------
 ------- Deployment of this Hot Fix----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1680_FD_UpdateAggregationToSum_34749' on hub server or Silo silo. Pass the hub server name, hub database name.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB"




