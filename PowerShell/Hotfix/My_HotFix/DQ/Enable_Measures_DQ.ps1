param($databaseServer="ENG1WNQA2.colo.retailsolutions.com",
$databaseName="MASTERDATAQA2",
$retailerName="CVS",
$measureName="Total Sales Amount")

$loadInfo = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

##import-module "$currentPath\sqlps.ps1"

$sql="
DELETE FROM dbo.RSI_DQ_RETAILER_STORE_LIST
WHERE  RetailerName = '$retailerName'

DELETE FROM dbo.RSI_DQ_RETAILER_MEASURE_RELATION
WHERE  RETAILER_NAME = '$retailerName'
       AND CORE_MEASURE_NAME='$measureName'
	   
INSERT INTO dbo.RSI_DQ_RETAILER_MEASURE_RELATION
            (RETAILER_NAME,
             RETAIELR_KEY,
             CORE_MEASURE_NAME)
select RETAILER_NAME,RETAILER_KEY,'$measureName' from RSI_DIM_RETAILER
where RETAILER_NAME='$retailerName'
"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

$sql="
SELECT *,MAX(CASE WHEN CORE_MEASURE_NAME='$measureName' THEN 1 ELSE 0 END)OVER() Coun FROM dbo.RSI_DQ_RETAILER_MEASURE_RELATION
WHERE RETAILER_NAME = '$retailerName' ORDER BY CASE WHEN CORE_MEASURE_NAME='$measureName' THEN 1 ELSE 0 END DESC
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
	write-host "Succeed to enable '$measureName' for '$retailerName'"
	foreach($column in $returnSet) {
		$NewRetailer = @{
			"RETAILER_NAME"=$column["RETAILER_NAME"];
			"RETAIELR_KEY"=$column["RETAIELR_KEY"];
			"CORE_MEASURE_NAME"=$column["CORE_MEASURE_NAME"]
		}
		$obj = New-Object PSObject -Property $NewRetailer
		$NewRetailers += $obj
	}
	$NewRetailers | format-table -Property * -AutoSize 
}
else
{
	write-host "Failed to enable '$measureName' for '$retailerName'"
}

