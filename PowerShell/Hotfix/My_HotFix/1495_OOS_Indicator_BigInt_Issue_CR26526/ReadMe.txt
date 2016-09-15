==This Hot Fix is to fix data type out of mememry issue for silo 'PG_DOLLAR_GENERAL' & 'PG_RITEAID'.==


The '1495_OOS_Indicator_BigInt_Issue_CR26526' do the following steps.

1. In given silo server and Silo db name.

2. Disable event manager of Silo Server.

2. checks if any jobs (cube, etl) running on Silo, if there are any jobs running then it will skip the below steps and enable event manager,otherwise it will
contingue below steps.	

3. Update the type of core measure 'OOS Indicator' & 'Store Out Of Indicator' from int to bigint.

4. Enable Event Manager


-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1514-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell file '1514_Ahold_USA_SOH_Isue_CR31513.ps1' on hub server or Silo silo. Pass the hub server name, hub database name, build numer.

e.g.

1.Open powershell as administrator

2.Update the silos under GAHUB by run the command
  .\runfromhub.ps1 "prod1fs110.colo.retailsolutions.com\STAGE" "PG_DOLLAR_GENERAL" 

3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "prodp1fs129.colo.retailsolutions.com\stage" "PG_RITEAID" 


3.Update the silos under CNHUB by run the command
  .\runfromhub.ps1 "eng1dev9s" "PG_RITEAID" 






