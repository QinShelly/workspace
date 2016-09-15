param(
    [String]$vendorName = 'PepsiCo',
    [String]$retailerName = 'Target'
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\connect.ps1"

$cpServerName = 'engv2qa3.ENG.RSICORP.LOCAL'
$cpDBName = 'CP'
$siloDBServerName = 'engv2qa3.ENG.RSICORP.LOCAL'
$dwServerName = '10.172.32.16'
$hubServerName  = 'engv2qa3.ENG.RSICORP.LOCAL'
$hubDBName = 'HUB'
$metricsGroup = 'Target'  # find metric group
$releaseName = 'Release'
$olapServerName = 'engv2qa3.ENG.RSICORP.LOCAL'

$cp_connection  = Create-SqlConnection $cpServerName $cpDBName

$short_vendor_name = $cp_connection.QueryScalar("select top 1 vendor_sname from rsi_dim_vendor where vendor_name = '$vendorName' and active = 'T'")
if (-not $short_vendor_name){
    "vendorname not found "
    $rows = $cp_connection.Query("select * from rsi_dim_vendor where vendor_name like '%$vendorName%' and active = 'T'")
    $rows | Out-GridView
    exit    
}
$vendor_key = $cp_connection.QueryScalar("select top 1 vendor_key from rsi_dim_vendor where vendor_name = '$vendorName' and active = 'T'")

write-host "vendor_key: " $vendor_key


$short_retailer_name = $cp_connection.QueryScalar("select top 1 retailer_sname from rsi_dim_retailer where retailer_name like '%$retailerName%' and active = 'T'")
if (-not $short_retailer_name){
    "retailername not found "
    $rows = $cp_connection.Query("select * from rsi_dim_retailer where retailer_name like '%$retailerName%' and active = 'T'")
    $rows | Out-GridView
    exit    
}
$retailer_key = $cp_connection.QueryScalar("select top 1 retailer_key from rsi_dim_retailer where retailer_name like '%$retailerName%' and active = 'T'")

write-host "retailer_key: " $retailer_key

$sqlConnection = Create-SqlConnection $hubServerName $hubDBName
$vConfig = Get-VerticaConfig $sqlConnection $hubDBName
$verticaConnection = Create-VerticaConnection -config $vConfig
$knonwMetricsGroup = @{ahold='Ahold USA'}
$metricsGroup = $knonwMetricsGroup["$retailerName"]
if (-not $metricsGroup) {
    $metricsGroup = $verticaConnection.QueryScalar("select distinct retailer_name from metadata_hub.MEASURES_core where retailer_name  = '$retailerName'")
}
if (-not $metricsGroup){
    "metricsgroup not found "
    exit    
}

# check ven/ret comination exists on DSM

$configAnt = "call ant -DsiloID=$($releaseName)_$($short_vendor_name)_$($short_retailer_name) -Ddb.server.name=$siloDBServerName"+
 " -Ddw.server.name=$dwServerName -Dhub.server.name=$hubServerName -Dhub.db.name=$hubDBName" + 
 " -Drsi.retailer.name=""$retailerName"" -Drsi.vendor.name=""$vendorName""" +
 " -Dcube.metrics.retailer=""$metricsGroup"" -Ddeploy.release.name=$releaseName" +
 " -Dolap.server.name=$olapServerName create-silo-config"

 $fileName = "$PSScriptRoot\$($short_vendor_name)_$($short_retailer_name).bat"
 $fileName
 $configAnt
 Out-File -FilePath $fileName -InputObject $configAnt -Encoding ASCII

 $deployAnt = "call ant -DsiloID=$($releaseName)_$($short_vendor_name)_$($short_retailer_name) -Ddeploy.release.name=$releaseName create-app-db deploy-silo"

 Out-File -FilePath $fileName -InputObject $deployAnt -Encoding ASCII -Append
 