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
write-host $sql

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)

write-host 'Complete..'
write-host 'Verify..'

$sql="
SELECT *,COUNT(1)OVER() AS Coun FROM dbo.RSI_DQ_RETAILER_STORE_LIST
WHERE RetailerName = '$retailerName'
"
$returnSet=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
$IsSucceed=$returnSet[0].Coun

if($IsSucceed -eq 1)
{
	write-host "Succeed to enable $retailerName"
	foreach($spemeasure in $returnSet) {
		$misMatch = @{
			"RetailerName"=$spemeasure["RetailerName"];
			"RetailerKey"=$spemeasure["RetailerKey"];
			"DATA_GAP"=$spemeasure["DATA_GAP"];
			"DATA_VARIANCE"=$spemeasure["DATA_VARIANCE"]
		}
		$obj = New-Object PSObject -Property $misMatch
		$misMatches += $obj
	}
	$misMatches | format-table -Property * -AutoSize 
}
else
{
	write-host "Failed to enable $retailerName"
}

