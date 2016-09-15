@echo off
echo Start deployment of DailyBuild

:TFGET
echo Step : Get the latest code from TFS
     tf get
     if %errorlevel%==1 goto DEND

:BINIT
echo Stip : Build Database Init
     cd %Detego_Root%\DataWarehouseInit\xml
    msbuild

:EINIT
echo Step : Execute Init package
     cd %Detego_Root%\Bin\DataWarehouseInit\InitDriverForMSBuild
     dtexec /file InitDriverForMSBuild.dtsx

:BDIM
echo Step : Build Dimension code
     cd %Detego_Root%\Dimensions\xml
     msbuild

:EDIM
echo Step : Execute Dimension Package
     cd %Detego_Root%\Bin\Dimensions\DimDriver
     dtexec /file DimDriver.dtsx

:BTABLE
echo Step : Build Table code
     cd %Detego_Root%\Table\xml
     msbuild

:ETABLE
echo Step : Execute Table package
     cd %Detego_Root%\Bin\Table\TableDriver
     dtexec /file TableDriver.dtsx

:BFACT
echo Step : Build Fact code
     cd %Detego_Root%\FactTables\XML
     msbuild

:EFACT
echo Step : Execute Fact Package
     cd %Detego_Root%\Bin\FactTables\FactDriver
     dtexec /file FactDriver.dtsx

:DEND
echo End of deployment process.
