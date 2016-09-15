Param ( 
  [String]$CPServerName="engv2qa3.ENG.RSICORP.LOCAL",
  [String]$CPDBName="CP"
)

. "$PSScriptRoot\..\common\connect.ps1"

$verticaConfig = [pscustomobject]@{
  'username'      = 'engdeployvtc'
  'password'      = Decrypt -Code 'egE8eterS9HgycJfxIOZ+w=='
  'serverName'    = 'DEVVERTICANXG.ENG.RSICORP.LOCAL'
  'backupServers' = $null
  'dbName'        = 'FUSION'
  'portNo'    = 5433
  'context'       = 'Deployment'
}

$dw   = Create-VerticaConnection -config $verticaConfig

$sql = "select distinct projection_schema from projections"
$res = $dw.query($sql)
#$res 

$verticaMap = @{}
foreach($row in $res) {
	[void] $verticaMap.Add($row[0], $row[0])
}

$cp = Create-SqlConnection $CPServerName $CPDBName
$cpResult = $cp.query("select distinct silo_Id from RSI_DEPLOY_SILO_CONFIG")
#$cpResult

$cpMap = @{}
foreach($row in $cpResult) {
	[void] $cpMap.Add($row[0], $row[0])
}

foreach ($x in $res){
    if (-not $cpMap.ContainsKey($x.projection_schema) -and $x.projection_schema.ToLower().StartsWith('ken')) {
        $x.projection_schema
    } 
}