$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
#import-module "$currentPath\sqlps.ps1"

function Get-Silo{
    param($databaseServer="ENGV2HHDBQA1.ENG.RSICORP.LOCAL",
    $databaseName="HUB_FUNCTION_BETA",
    $buildnumer=7056)

    $loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

    Set-StrictMode -Version Latest

    $cmd = @"
    select DB_SERVERNAME, DB_NAME, siloid, iis_liveserver_url,Cube_Name from RSI_DIM_SILO 
    where  type='S' and status='A'
"@

# "BUILD_NUMBER='$buildnumer' and"
    $con = "server=$databaseServer;database=$databaseName;Integrated Security=sspi" 
    $da = new-object System.Data.SqlClient.SqlDataAdapter ($cmd, $con) 
    $dt = new-object System.Data.DataTable 
    $da.fill($dt) | out-null 

#    $silos = @(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

    return $dt
}

$s  = Get-Silo