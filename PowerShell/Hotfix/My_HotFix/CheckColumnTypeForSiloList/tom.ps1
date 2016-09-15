#Get parameter
param($databaseServer="prod1altptl1.colo.retailsolutions.com",
$databaseName="MASTERDATA",
$InputSiloId="all")

#Get serverice
$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
#import-module "$currentPath\sqlps.ps1"
write-host "--current dir is $currentPath"
$logOutPut = "$currentPath\Log.txt"

#Get SQL for ALL silos on HUB
$sql=
" 
select top 1 SiloId,DB_SERVERNAME ,count(1)over() as a
from RSI_DIM_SILO
where DB_SERVERNAME LIKE '%118%'
 
"
#Get silo list
$ALL_silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)|ft -AutoSize

 

$ss=$ALL_silos[0].a
write-host $ss
#Check each silo by its server
foreach ($silo in $ALL_silos)
{
  $dbserver= $silo.DB_SERVERNAME
    #write-output $dbserver
  $siloId= $silo.siloid
  #write-output $siloId
  write-host "$dbserver"
  $sql_2=
    "
    select SILO_ID,
    SUBSTRING(DESCRIPTION,charindex('endtime',DESCRIPTION),18) OSM_End_Date
    from RSI_LOG
    WHERE OWNER_TYPE='JOB'
    AND DESCRIPTION LIKE 'BEGIN%'
    AND CREATE_DATE>convert(varchar,CONVERT(DATE,GETDATE()))+' 03:00:00' 
    ORDER BY 1 DESC
    "
    $End_Date=@(Invoke-Sqlcmd -Query $sql_2 -ServerInstance $dbserver -database $siloId -QueryTimeout 65535)
   
}  
write-host "complete"
