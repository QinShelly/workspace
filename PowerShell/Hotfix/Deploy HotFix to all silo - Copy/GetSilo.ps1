$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"

function Get-Silo{
    param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
    $databaseName="GAHUB",
    $buildnumer=7056)

    $loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

    Set-StrictMode -Version Latest

    $sql = @"
    select DB_SERVERNAME,DB_NAME,siloid,iis_liveserver_url,Cube_Name from RSI_DIM_SILO 
    where BUILD_NUMBER='$buildnumer' and type='S' and status='A'
"@
    $silos = @(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

    return $silos
}

 Get-Silo