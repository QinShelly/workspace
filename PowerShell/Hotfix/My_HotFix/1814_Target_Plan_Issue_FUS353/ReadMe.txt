==This Hot Fix is to fix a target/target category unique_type populated defect.


The '1862-Target unique_Type populated defect' do the following steps.

1. In given database, loop each of 7005 Target/Target Category Silos.

2. Update the data of uniques_type table

3. Copy the latest file 'TARGET.sqlp' & 'TRGCAT.sqlp' to all the 7005 stage server

4. Copy file 'TARGET.sqlp' & 'TRGCAT.sqlp'  to \\virtualnodefs\RSI\Fusion\Release\Fusion7005\release\scripts

-----------------------------------------------------------------
 ------- Deployment of this Hot Fix----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Execute (run) the Powershell files under HF folder '1862-Target unique_Type populated defect' on hub server or Silo silo. Pass the hub server name, hub database name.

e.g.

1.Open powershell as administrator

2.Change the powersheel dir to hotfix folder, then run script 
for example:
.\ProcessTest.ps1 -hubServer="192.168.29.51" -hubDBName="MASTERDATAQA2" -targetRelease="7004.80"
  



