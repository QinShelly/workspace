param($databaseServer="ENG1WNQA2.colo.retailsolutions.com",
$databaseName="MASTERDATAQA2",
$retailerName="CVS")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

##import-module "$currentPath\sqlps.ps1"

$sql="
DELETE FROM dbo.RSI_DQ_RETAILER_STORE_LIST
WHERE  RetailerName = '$retailerName'

INSERT INTO dbo.RSI_DQ_RETAILER_STORE_LIST
            (RetailerName,
             RetailerKey)
select RETAILER_NAME,RETAILER_KEY from RSI_DIM_RETAILER
where RETAILER_NAME='$retailerName'
"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

$sql="
SELECT *,MAX(CASE WHEN RetailerName='$retailerName' THEN 1 ELSE 0 END)OVER() Coun FROM dbo.RSI_DQ_RETAILER_STORE_LIST
ORDER BY CASE WHEN RetailerName='$retailerName' THEN 1 ELSE 0 END DESC
"
$returnSet=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

$IsSucceed=0
if($returnSet.length -gt 0)
{
	$IsSucceed=$returnSet[0].Coun
}

write-host ''

$NewRetailer = @{}
$NewRetailers = @()
	
if($IsSucceed -eq 1)
{
	write-host "Succeed to enable $retailerName"
	foreach($column in $returnSet) {
		$NewRetailer = @{
			"RetailerName"=$column["RetailerName"];
			"RetailerKey"=$column["RetailerKey"];
			"DATA_GAP"=$column["DATA_GAP"];
			"DATA_VARIANCE"=$column["DATA_VARIANCE"]
		}
		$obj = New-Object PSObject -Property $NewRetailer
		$NewRetailers += $obj
	}
	$NewRetailers | format-table -Property * -AutoSize 
}
else
{
	write-host "Failed to enable $retailerName"
}

