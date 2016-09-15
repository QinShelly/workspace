<#
Invoke-ASCmd -Query "with
member measures.itemcount_ne as count(nonempty ([PRODUCT].[ITEM GROUP].[UPC].members * [Measures].[Total Sales Amount]))
member measures.storecount_ne as count(nonempty([STORE].[STORE].[STORE].members* [Measures].[Total Sales Amount]))
select {measures.itemcount_ne, measures.storecount_ne} on 0
from [ENERGIZER_WALGREENS]" -Server "wal1wnfs73s.colo.retailsolutions.com" -Database "ENERGIZER_WALGREENS" 
#>
function InvokeMdxTo-Csv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string]$connectionString       
        ,[Parameter(Mandatory=$true)] [string]$MDX
        ,[Parameter(Mandatory=$true)] [string]$CSVFileFullName
    )
    Process
    {  
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") | Out-Null;
        write-host "Executing InvokeMdxTo-Csv $MDXName"
        $con = new-object Microsoft.AnalysisServices.AdomdClient.AdomdConnection($connectionString)
        $con.Open() 
        $command = new-object Microsoft.AnalysisServices.AdomdClient.AdomdCommand($MDX, $con)
        $dataAdapter = new-object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($command) 
        $ds = new-object System.Data.DataSet 
        $dataAdapter.Fill($ds) 
        $con.Close();
		ExportDSTo-CSV $ds $CSVFileFullName
    }
};

function ExportDSTo-CSV{
param (
        [Parameter(Mandatory=$true)] [System.Data.DataSet]$ds
		,[Parameter(Mandatory=$true)] [string]$CSVFileFullName
    )
	$ds.Tables[0] | export-csv -path $CSVFileFullName -Delimiter "," -NoTypeInformation;
}

function GetMdxTo-DS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string]$connectionString       
        ,[Parameter(Mandatory=$true)] [string]$MDX
    )
    Process
    {  
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") | Out-Null;
        
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

$connectionString = "Data Source=" + $DataSource + ";Catalog=" + $Catelog + ";"
$MDX = @"
with member measures.cubeName as "$Catelog"
member measures.itemcount_ne as count(nonempty ([PRODUCT].[ITEM GROUP].[UPC].members * [Measures].[Total Sales Amount]))
member measures.storecount_ne as count(nonempty([STORE].[STORE].[STORE].members* [Measures].[Total Sales Amount]))
select { measures.cubeName,measures.itemcount_ne, measures.storecount_ne} on 0
from [$Catelog]
"@

$dt = GetMdxTo-DS -connectionString $connectionString -MDX $MDX 
$cubeName = $dt[1][0]
$itemCount = $dt[1][1]
$storeCount = $dt[1][2]
$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "cubeName" -Value $cubeName
$item | Add-Member -MemberType NoteProperty -Name "itemcount" -Value $itemCount
$item | Add-Member -MemberType NoteProperty -Name "storecount" -Value $storeCount
return $item
}
$collectionObject = @()

$DataSource = "wal1wnfs73s.colo.retailsolutions.com"
$Catelog = "ENERGIZER_WALGREENS"
$item = GetItemStoreCount-Cube -DataSource $DataSource -Catelog $Catelog
$collectionObject += $item

$Catelog = "HANES_WALGREENS"
$item = GetItemStoreCount-Cube -DataSource $DataSource -Catelog $Catelog
$CSVFileFullName = "c:\testCube.csv"

$collectionObject += $item
$collectionObject | Format-Table |Out-Default