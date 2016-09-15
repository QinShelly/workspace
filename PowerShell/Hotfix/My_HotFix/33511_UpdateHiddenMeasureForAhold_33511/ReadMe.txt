==This Hot Fix is to update the hidden NPI & Prom measures to visable for 'Ahold' 7001 silos.==


The '33511_UpdateHiddenMeasureForAhold_33511' do the following steps.

1. In given database, loop each of 7001 Ahold Silo.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Enable the hidden NPI & Prom measures in the cube for the silo.

4. Enable Event Manager

5. Update the incorrect measure name in metadata tables

6. Add a dim 'Metadata' process event in rsi_olap_process


-----------------------------------------------------------------
 ------- Deployment of this Hot Fix----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '33511_UpdateHiddenMeasureForAhold_33511' on hub server or Silo silo. Pass the hub server name, hub database name.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "wal1wnfshub.colo.retailsolutions.com" "GAHUB"




