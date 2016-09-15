# add to begin of C:\rsi\nextgen\scripts\dw\etl\fact_load\DW\Masterdata.ps1
. "$PSScriptRoot\..\..\..\..\common\common.ps1"
. "$PSScriptRoot\..\..\..\..\common\db\connect.ps1"
. "$PSScriptRoot\..\..\..\..\common\config.ps1"
. "$PSScriptRoot\..\..\..\custom\Custom.ps1"

# add to end of C:\rsi\nextgen\scripts\dw\etl\fact_load\DW\Masterdata.ps1
# modify the silo parameters
$siloServerName = 'PRODP1HSDBC1A.PROD.RSICORP.LOCAL\DB20'
$siloDBName='M_M_ENTERPRISE_WALGREENS'
$siloID='M_M_ENTERPRISE_WALGREENS'

$dwSchema = 'M_M_ENTERPRISE_WALGREENS'
$factTable = 'M_M_ENTERPRISE_WALGREENS.spd_fact'
$srcTable = "TMP_FACT_VIEW"

$config = Get-Config $siloServerName $siloDBName $siloID
$hubId = $config.getProperty("hub.db.name", "TESTHUB")
$schemaName = $config.getProperty("dw.schema.name", "KCC_TARGET")
$cubeServerName = $config.getProperty("olap.server.name", "engp3qa3") + $config.getProperty("olap.server.instance", "")
$cubeDBName = $config.getProperty("olap.cubedb.name", "KCC_TARGET")

$sqlConnection = Create-SqlConnection $siloServerName $siloDBName
Write-Host $siloServerName $siloDBName $siloID
$vConfig = Get-VerticaConfig $sqlConnection $siloID
$verticaConnection = Create-VerticaConnection -config $vConfig


$dimensions  = Get-DimensionTables -schemaName $dwSchema

$sql = "DROP VIEW IF EXISTS $srcTable;
                     CREATE local temp VIEW $srcTable as 
                        SELECT * from $factTable
                        where PERIOD_KEY >= 20160417 and period_key <= 20160625
                    "
$verticaConnection.Execute($sql);

Find-MissingMasterData -dw $verticaConnection -dwSchema $dwSchema -srcTable $srcTable -factTable $factTable -dimensions $dimensions