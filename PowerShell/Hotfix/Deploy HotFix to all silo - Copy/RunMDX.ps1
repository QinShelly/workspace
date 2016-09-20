Param([string]$ServerName ="wal1wnfs73s.colo.retailsolutions.com"
,[string]$CubeName="ENERGIZER_WALGREENS"
)

$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\GetSilo.ps1"

<#
Invoke-ASCmd -Query "with
member measures.itemcount_ne as count(nonempty ([PRODUCT].[ITEM GROUP].[UPC].members * [Measures].[Total Sales Amount]))
member measures.storecount_ne as count(nonempty([STORE].[STORE].[STORE].members* [Measures].[Total Sales Amount]))
select {measures.itemcount_ne, measures.storecount_ne} on 0
from [ENERGIZER_WALGREENS]" -Server "wal1wnfs73s.colo.retailsolutions.com" -Database "ENERGIZER_WALGREENS" 
#>


function GetMdxTo-DataTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string]$CubeServerName       
        ,[Parameter(Mandatory=$true)] [string]$CubeDBName       
        ,[Parameter(Mandatory=$true)] [string]$MDX
    )
    Process
    {  
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") | Out-Null;
        $connectionString = "Data Source=" + $CubeServerName + ";Catalog=" + $CubeDBName + ";"
        $con = new-object Microsoft.AnalysisServices.AdomdClient.AdomdConnection($connectionString)
        $con.Open() 
        $command = new-object Microsoft.AnalysisServices.AdomdClient.AdomdCommand($MDX, $con)
        $dataAdapter = new-object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($command) 
        $ds = new-object System.Data.DataSet 
        $dataAdapter.Fill($ds) 
        $con.Close();
		return $ds.Tables[0]
    }
};

function GetItemStoreCount-Cube {
    param (
    [Parameter(Mandatory=$true)] [string]$DataSource
    ,[Parameter(Mandatory=$true)] [string]$Catelog
    )

    $MDX = @"
    with member measures.cubeName as "$Catelog"
    member measures.itemcount_ne as count(nonempty ([PRODUCT].[ITEM GROUP].[UPC].members * [Measures].[Total Sales Amount]))
    member measures.storecount_ne as count(nonempty([STORE].[STORE].[STORE].members* [Measures].[Total Sales Amount]))
    select { measures.cubeName,measures.itemcount_ne, measures.storecount_ne} on 0
    from [$Catelog]
"@

    $dt = GetMdxTo-DataTable -CubeServerName $DataSource -CubeDBName $Catelog -MDX $MDX 
    $cubeName = $dt[1][0]
    $itemCount = $dt[1][1]
    $storeCount = $dt[1][2]
    $item = New-Object System.Object
    $item | Add-Member -MemberType NoteProperty -Name "cubeName" -Value $cubeName
    $item | Add-Member -MemberType NoteProperty -Name "itemcount" -Value $itemCount
    $item | Add-Member -MemberType NoteProperty -Name "storecount" -Value $storeCount
    return $item
}

$results = @()

foreach ($silo in Get-Silo | select -first 3) {
    $cubeServerName = $silo.IIS_LiveServer_URL
    $cubeName = $silo.Cube_Name
    # write-host "$cubeServerName $cubeName"
    [regex]$regex = '^http://(.*/LIVE\d)$'
    if($cubeServerName -match $regex) {
        $cubeServerName = $Matches[1]
    }
    $cubeServerName = $cubeServerName.Replace('/','\');
    write-host "$cubeServerName $cubeName"

    $item = GetItemStoreCount-Cube -DataSource $cubeServerName -Catelog $cubeName
    $results += $item
}

$CSVFileFullName = "c:\testCube.csv"

# $results | Format-Table | Out-Default

$results | export-csv -path $CSVFileFullName -Delimiter "," -NoTypeInformation;
