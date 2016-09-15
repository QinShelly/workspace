@ECHO OFF

ECHO Begining deployment on %Date% at %Time%

SET svr=%1
SET SourceCode=%2

REM Depoy new SQL objects

REM ****************************
REM Check Duplicate Deployment
REM ****************************

For %%f in (
%SourceCode%\Pre_Deployment_ReleaseTracking.sql
) DO (ECHO         Executing %%f) > deploy.log & (sqlcmd -E -S %svr% -i %%f)   >> deploy.log

Find "Error: Check duplicate deployment failed" deploy.log
IF %ERRORLEVEL% EQU 0 GOTO DUPLICATEDEPLOYMENT

REM ****************************
REM Main Deployment Steps
REM ****************************

For %%f in (
%SourceCode%\InsertData.sql
) DO (ECHO         Executing %%f) >> deploy.log & (sqlcmd -E -S %svr% -i %%f)   >> deploy.log

REM ****************************
REM Check Validation Result
REM ****************************

For %%f in (
%SourceCode%\Post_Deployment_ReleaseTracking.sql
) DO (ECHO         Executing %%f) >> deploy.log & (sqlcmd -E -S %svr% -i %%f)   >> deploy.log

Find "Error: Deployment validation failed" deploy.log
IF %ERRORLEVEL% EQU 0 GOTO VALIDATIONFAILURE

ECHO **Deployment Complete** on %Date% at %Time%
ECHO **Deployment Complete** on %Date% at %Time%  >> deploy.log
GOTO END

:DUPLICATEDEPLOYMENT
ECHO **Possible duplicate deployment has been identified. Quit the deployment** on %Date% at %Time%
ECHO **Possible duplicate deployment has been identified. Quit the deployment** on %Date% at %Time%  >> deploy.log
GOTO END

:VALIDATIONFAILURE
ECHO **Post deployment validation is failed. Deployment is failed. Quit the deployment** on %Date% at %Time%
ECHO **Post deployment validation is failed. Deployment is failed. Quit the deployment** on %Date% at %Time%  >> deploy.log
GOTO END

:END
