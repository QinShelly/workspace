Param([string]$serverName="localhost"
	, [string]$cubeServerName="localhost"
	, [string]$dbName="CONAGR_AHOLD_Metrics"
	, [string]$cubeDBName ="CONAGR_AHOLD_Metrics"
	, [string]$cubeName="CONAGR_AHOLD_Metrics")
cls
trap {'Metrics Automation Failed {0}' -f $_.Exception.Message; break}

$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"

## Add the AMO namespace
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")


$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript + '.\..\include.ps1')
. ($thisScript + '.\..\defaultaggvalidation.ps1')

## Connect to the Cube
$server = New-Object Microsoft.AnalysisServices.Server
$server.connect($cubeServerName)
$d = $server.Databases.Item($cubeDBName)

Write-Output ("Custom Ahold Cube Changes : {0}" -f $d.Name)
## Perform DataSource View Changes

$dsv = $d.DataSourceViews.Item("Fusion")
$schema = $dsv.schema

$oledb = New-Object System.Data.OleDb.OleDbConnection
$oledb.ConnectionString = "Provider=SQLNCLI10.1;Data Source=$serverName;Initial Catalog=$dbName;Integrated Security=SSPI"
$oledb.Open()
$selectCmd = New-Object System.Data.OleDb.OleDbCommand

$selectCmd.CommandText = "SELECT * FROM olap.PLAN_FACT where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "olap_PLAN_FACT")

$selectCmd.CommandText = "SELECT * FROM olap.UNIQUES_TYPE where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "olap_UNIQUES_TYPE")

AddTabletoDSV $oledb	$dsv	"RSI_DIM_POG_IND"	"SELECT * FROM [olap].[RSI_DIM_POG_IND] WHERE 1=0"		"View"	"olap";

$dsv.Update()
$oledb.Close()

$dimPOGINDName = "POG IND"		
$dim = AddDimension $d $dsv $dimPOGINDName
		
$void =  AddAttribute	$dim	"RSI_DIM_POG_IND"	'POG_IND_KEY'	'POG IND'	Integer	Key	$true	'POG_IND';
$dim.Update();
Write-Output ("$dimPOGINDName Dimension created sucessfully");

$cube = $d.Cubes.Item($cubeName)

AddCubeDimension $d $cube $dimPOGINDName	$false

$cube = $d.Cubes.Item($cubeName)

$integerFormat="#,###"
$decimalFormat="#,##0.00"
$decCurrFormat="$#,##0.00"

$ssMeasureGroup = $cube.MeasureGroups.Item("STORE SALES")
$pdfMeasureGroup = $cube.MeasureGroups.Item("PLAN FACT")

$void = AddRegularDimMGRelationship $cube  $ssMeasureGroup (CreateDataItem $dsv "dbo_STORE_SALES"  "POG_IND_KEY")			$dimPOGINDName	"POG IND"

dealMeasureGroup ([REF]$pdfMeasureGroup) "olap_PLAN_FACT" "Total Sales Volume Units WithOut CNS" "Total Sales Volume Units WithOut CNS" "Inventory\On Hand" $decimalFormat "0"
dealMeasureGroup ([REF]$pdfMeasureGroup) "olap_PLAN_FACT" "Retailer Store Out Of Stock Indicator" "Retailer Store Out Of Stock Indicator Count"     ""     $integerFormat "3"  $false "Integer" "Integer"
dealMeasureGroup ([REF]$pdfMeasureGroup) "olap_PLAN_FACT" "Retailer Store Out Of Stock Indicator" "Retailer Store Out Of Stock Indicator Internal"       ""     $integerFormat "0"  $false "Integer" "Integer"

dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Swell Volume Cases" "Inventory\Adjustments" $decimalFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store BRI Volume Cases" "Inventory\On Hand" $decimalFormat "1"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Swell Store Count" "Inventory\Adjustments" $integerFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Other Adjustment Store Count" "Inventory\Adjustments" $integerFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Total Adjustment Store Count" "Inventory\Adjustments" $integerFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Total Adjustment Volume Cases" "Inventory\Adjustments" $decimalFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store Shelf Capacity Volume Cases" "Inventory\On Hand" $decimalFormat "1"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store Secondary Shelf Capacity Volume Cases" "Inventory\On Hand" $decimalFormat "1"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store Shelf On Hand Volume Cases" "Inventory\On Hand" $decimalFormat "1"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store Mezzanine On Hand Volume Cases" "Inventory\On Hand" $decimalFormat "1"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Other Adjustment Volume Cases" "Inventory\Adjustments" $decimalFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "PERIOD_ID" "Store Forceout Reciepts Volume Equivalent Units" "Supply\Store Flow" $integerFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "Total Cost Amount" "Total Cost Amount" "Cost & Margin" $decCurrFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "Regular Cost Amount" "Regular Cost Amount" "Cost & Margin" $decCurrFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "Promoted Cost Amount" "Promoted Cost Amount" "Cost & Margin" $decCurrFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "Promoted Sales Volume Units" "Promoted Sales Volume Cases" "Sales\Promoted" $decimalFormat "0"
dealMeasureGroup ([REF]$ssMeasureGroup) "dbo_STORE_SALES" "Store On Hand Volume Units" "Store On Hand Volume Equivalent Units Internal" "Inventory\On Hand" $integerFormat "1" $false

$cube.update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull);

$pdfMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)
$ssMeasureGroup.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents)


## Add [Cost Retail Authorized Flag, [LY Cost Retail Authorized Flag] and attributes at [UNIQUES TYPE] dim
Write-Output ("Custom Target UNIQUES TYPE Dim Changes : {0}" -f $d.Name)
$uniquesDim = $d.Dimensions.item("UNIQUES TYPE");

AddAttribute $uniquesDim "olap_UNIQUES_TYPE" "Cost Retail Authorized Flag"		"Cost Retail Authorized Flag" 		"Integer" "Regular"
AddAttribute $uniquesDim "olap_UNIQUES_TYPE" "LY Cost Retail Authorized Flag"	"LY Cost Retail Authorized Flag"	"Integer" "Regular"
AddAttribute $uniquesDim "olap_UNIQUES_TYPE" "TYA Cost Retail Authorized Flag"	"TYA Cost Retail Authorized Flag"	"Integer" "Regular"
$uniquesDim.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents);

$server.disconnect()



$dimensionCalendarName = "Calendar"
$calendarSchemaName = "olap_MULTIPLE_CALENDAR"
$calendarTableName = "MULTIPLE_CALENDAR_PIVOT_EX"

## Check if forecasting enabled
$sql = "SELECT TOP 1 * FROM RSI_CORE_CFGPROPERTY WHERE Name = 'cube.fcstmetrics.enabled' AND Value = 'true'"
$result = @(Invoke-Sqlcmd -Query $sql -ServerInstance $serverName -database $dbName -QueryTimeout 65535)
$fcst_enabled = 0
if ($result.count -eq 1) {
	$fcst_enabled = 1
}

## Connect to the Cube
$server = New-Object Microsoft.AnalysisServices.Server
$server.connect($cubeServerName)
$d = $server.Databases.Item($cubeDBName)

Write-Output ("Custom Ahold Cube Changes : {0}" -f $d.Name)

## Perform DataSource View Changes

$dsv = $d.DataSourceViews.Item("Fusion")
$schema = $dsv.schema

$oledb = New-Object System.Data.OleDb.OleDbConnection
$oledb.ConnectionString = "Provider=SQLNCLI10.1;Data Source=$serverName;Initial Catalog=$dbName;Integrated Security=SSPI"
$oledb.Open()

$selectCmd = New-Object System.Data.OleDb.OleDbCommand
$selectCmd.CommandText = "SELECT * FROM olap.PLAN_FACT where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "olap_PLAN_FACT")

$selectCmd = New-Object System.Data.OleDb.OleDbCommand
$selectCmd.CommandText = "SELECT * FROM olap.MULTIPLE_CALENDAR_PIVOT_EX where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, $calendarSchemaName)
$dataTable = $dataTables[0];
$dataTable.ExtendedProperties["TableType"]= "Table";
$dataTable.ExtendedProperties["DbSchemaName"]="olap";
$dataTable.ExtendedProperties["DbTableName"]=$calendarTableName;
$dataTable.ExtendedProperties["FriendlyName"]="MULTIPLE_CALENDAR";

$selectCmd = New-Object System.Data.OleDb.OleDbCommand
$selectCmd.CommandText = "SELECT * FROM olap.STORE_SALES where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "dbo_STORE_SALES")

$selectCmd = New-Object System.Data.OleDb.OleDbCommand
$selectCmd.CommandText = "SELECT * FROM olap.BASELINE where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "dbo_BASELINE")

$selectCmd = New-Object System.Data.OleDb.OleDbCommand
$selectCmd.CommandText = "SELECT * FROM olap.DC_SHIPMENT where 1=0"
$selectCmd.Connection=$oledb
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
$adapter.SelectCommand = $selectCmd
$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "dbo_DC_SHIPMENT")

if ($fcst_enabled -eq 1)
{
	$selectCmd = New-Object System.Data.OleDb.OleDbCommand
	$selectCmd.CommandText = "SELECT * FROM olap.FORECASTING where 1=0"
	$selectCmd.Connection=$oledb
	$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
	$adapter.SelectCommand = $selectCmd
	$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, "FORECASTING")
}

$dsv.Update()
$oledb.Close()

$cube = $d.Cubes.Item($cubeName)

$integerFormat="#,##0"
$decimalFormat="#,##0.00"
$intCurrFormat="$#,##0"
$decCurrFormat="$#,##0.00"

function CreateDataItem([Microsoft.AnalysisServices.DataSourceView]$dsv, [string]$tableName, [string]$columnName)
{
	$dataTable = $dsv.Schema.Tables[$tableName]
	$dataColumn = $dataTable.Columns[$columnName]
	$dataItem = New-Object Microsoft.AnalysisServices.DataItem($tableName, $dataColumn.ColumnName)
	$dataItem.DataType = [Microsoft.AnalysisServices.OleDbTypeConverter]::GetRestrictedOleDbType($dataColumn.DataType)
	return $dataItem
}

function updateRegularDimUsage([Microsoft.AnalysisServices.Cube]$cube, [Microsoft.AnalysisServices.DataSourceView]$dsv, [string]$dsvDBTableName, 
	[Microsoft.AnalysisServices.MeasureGroup]$measureGroup, [string[]]$mgColNames,[Microsoft.AnalysisServices.NullProcessing[]]$nullProcessings, [string]$dimName, [string]$dimAttrName)
{
	$curDim = $cube.Dimensions.GetByName($dimName)
	$regMgDim = $measureGroup.Dimensions.Find($curDim.ID)
	if ($regMgDim -ne $NULL){
		$measureGroup.Dimensions.Remove($regMgDim);
	}
	$regMgDim = New-Object Microsoft.AnalysisServices.RegularMeasureGroupDimension($curDim.ID);
	$measureGroup.Dimensions.Add($regMgDim)
	$mgAttr = $regMgDim.Attributes.Add($curDim.Dimension.Attributes.GetByName($dimAttrName).ID)
	$mgAttr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
	
	$mgAttr = $regMgDim.Attributes.Find($curDim.Dimension.Attributes.GetByName($dimAttrName).ID)
	
	for ($i = 0; $i -lt $mgColNames.Length; $i++) {
		$dataItem = CreateDataItem $dsv $dsvDBTableName $mgColNames[$i]
		if ($nullProcessings -ne $NULL){
			if ($nullProcessings[$i] -ne $NULL){
				$dataItem.NullProcessing = $nullProcessings[$i];
			}
		}
		$isExist = 0;
		foreach ($tmpDataItem in $mgAttr.KeyColumns){
			if ($tmpDataItem.toString() -eq $dataItem.toString()) {
				$isExist = 1;
				break;
			}
		}
		if ($isExist -eq 0){
			$mgAttr.KeyColumns.Add($dataItem);
		}
	}
}

function updateReferenceDimUsage([Microsoft.AnalysisServices.Cube]$cube,
[Microsoft.AnalysisServices.MeasureGroup]$measureGroup, [string[]]$mgColNames, [string]$dimName, [string]$interDimName)
{
	$curDim = $cube.Dimensions.GetByName($dimName)
	$interDim = $cube.Dimensions.GetByName($interDimName)
	$regMgDim = $measureGroup.Dimensions.Find($curDim.ID)
	if ($regMgDim -ne $NULL){
		$measureGroup.Dimensions.Remove($regMgDim);
	}
	$regMgDim1 = New-Object Microsoft.AnalysisServices.ReferenceMeasureGroupDimension;
	$regMgDim1.CubeDimensionID = $curDim.ID;
	$regMgDim1.IntermediateCubeDimensionID = $interDim.ID;
	$mgAttr = $regMgDim1.Attributes.Add($curDim.Dimension.Attributes.GetByName($mgColNames[0]).ID)
	$mgAttr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
	$regMgDim1.IntermediateGranularityAttributeID = $interDim.Dimension.Attributes.GetByName($mgColNames[1]).ID;
	$regMgDim1.Materialization = [Microsoft.AnalysisServices.ReferenceDimensionMaterialization]::Regular;
	$measureGroup.Dimensions.Add($regMgDim1)
	
}

function updateDegenerateDimUsage([Microsoft.AnalysisServices.Cube]$cube,
[Microsoft.AnalysisServices.MeasureGroup]$measureGroup, [string]$mgColName, [string]$dimName)
{
	$curDim = $cube.Dimensions.GetByName($dimName)
	$regMgDim = $measureGroup.Dimensions.Find($curDim.ID)
	if ($regMgDim -ne $NULL){
		$measureGroup.Dimensions.Remove($regMgDim);
	}
	$regMgDim1 = New-Object Microsoft.AnalysisServices.DegenerateMeasureGroupDimension($curDim.ID);
	$mgAttr = $regMgDim1.Attributes.Add($curDim.Dimension.Attributes.GetByName($mgColName).ID)
	$mgAttr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
	$measureGroup.Dimensions.Add($regMgDim1)
	
}

function updateCalendarDimension([Microsoft.AnalysisServices.Cube]$cube,[Microsoft.AnalysisServices.Database]$db, [string]$datasourceName,[Microsoft.AnalysisServices.DataSourceView]$dsv)
{

	[Microsoft.AnalysisServices.Dimension] $dim = $db.Dimensions.FindByName($dimensionCalendarName);
	$cubeDim = $cube.Dimensions.FindByName($dim.ID);
	
	[Microsoft.AnalysisServices.DimensionAttribute] $attr
	$keyAttrName = 'Date'
	$attr = $dim.Attributes.FindByName($keyAttrName);
	$newAttr = $attr.Clone();
	$dim.Attributes.Remove($attr);
	$dataItem = CreateDataItem $dsv $calendarSchemaName 'CALENDAR_KEY'
	##$dataItem.NullProcessing = [Microsoft.AnalysisServices.NullProcessing]::UnknownMember
	$isExist = 0;
	foreach ($tmpDataItem in $newAttr.KeyColumns){
		if ($tmpDataItem.toString() -eq $dataItem.toString()) {
			$isExist = 1;
			break;
		}
	}
	if ($isExist -eq 0){
		$newAttr.KeyColumns.Add($dataItem);
		$newAttr.KeyColumns[1].DataType =  [System.Data.OleDb.OleDbType]::Integer
	}
	$keyAttr=$newAttr;
	$dim.Attributes.Add($newAttr);
	
	$dim.UnknownMember = [Microsoft.AnalysisServices.UnknownMemberBehavior]::Hidden;
	$cubeDim = $cube.Dimensions.FindByName($dim.ID);
	if ( $cubeDim -eq $NULL) {
		$cubeDim = $cube.Dimensions.Add($dim.ID);
	}

	$attr = $dim.Attributes.findByName('Ahold Ad Calendar Name');
	if ($attr -eq $NULL){
		$attr = $dim.Attributes.Add('Ahold Ad Calendar Name');
	}
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Regular;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_AD_calendarName';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.KeyColumns[0].DataSize =  50
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_AD_calendarName';
	$attr.ValueColumn=$dataItem;
	$attr.ValueColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.ValueColumn.DataSize =  50
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_AD_calendarName';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  50

	$attr = $dim.Attributes.findByName('Ahold Calendar Name');
	if ($attr -eq $NULL){
		$attr = $dim.Attributes.Add('Ahold Calendar Name');
	}
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Regular;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_calendarName';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.KeyColumns[0].DataSize =  50
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_calendarName';
	$attr.ValueColumn=$dataItem;
	$attr.ValueColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.ValueColumn.DataSize =  50
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_calendarName';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  50
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;

	$attr = $dim.Attributes.findByName('Ahold Year');
	if ($attr -ne $NULL){
		$dim.Attributes.Remove('Ahold Year');
	}
	$attr = $dim.Attributes.Add('Ahold Year');
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Years;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_year';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::SmallInt
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearname';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  10
	$attrrel = New-Object Microsoft.AnalysisServices.AttributeRelationship("Ahold Calendar Name")
	$attrrel.RelationshipType=[Microsoft.AnalysisServices.RelationshipType]::Rigid
	$attr.AttributeRelationships.Add($attrrel);
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;
	

	$attr = $dim.Attributes.findByName('Ahold Quarter');
	if ($attr -ne $NULL){
		$dim.Attributes.Remove('Ahold Quarter');
	}
	$attr = $dim.Attributes.Add('Ahold Quarter');
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Quarters;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearquarter';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::Integer
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearquartername';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  10
	$attrrel = New-Object Microsoft.AnalysisServices.AttributeRelationship("Ahold Year")
	$attrrel.RelationshipType=[Microsoft.AnalysisServices.RelationshipType]::Rigid
	$attr.AttributeRelationships.Add($attrrel);
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;

	$attr = $dim.Attributes.findByName('Ahold Period');
	if ($attr -ne $NULL){
		$dim.Attributes.Remove('Ahold Period');
	}
	$attr = $dim.Attributes.Add('Ahold Period');
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Months;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearperiod';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::Integer
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearperiodname';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  20
	$attrrel = New-Object Microsoft.AnalysisServices.AttributeRelationship("Ahold Quarter")
	$attrrel.RelationshipType=[Microsoft.AnalysisServices.RelationshipType]::Rigid
	$attr.AttributeRelationships.Add($attrrel);
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;

	$attr = $dim.Attributes.findByName('Ahold Week Number');
	if ($attr -ne $NULL){
		$dim.Attributes.Remove('Ahold Week Number');
	}
	$attr = $dim.Attributes.Add('Ahold Week Number');
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Regular;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearweek';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::Integer
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearweekname';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  40
	$attrrel = New-Object Microsoft.AnalysisServices.AttributeRelationship("Ahold Period")
	$attrrel.RelationshipType=[Microsoft.AnalysisServices.RelationshipType]::Rigid
	$attr.AttributeRelationships.Add($attrrel);
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;

	$attr = $dim.Attributes.findByName('Ahold Day Number');
	if ($attr -ne $NULL){
		$dim.Attributes.Remove('Ahold Day Number');
	}
	$attr = $dim.Attributes.Add('Ahold Day Number');
	$attr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Regular;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::Regular;
	$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key;
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearweekday';
	$attr.KeyColumns.Add($dataItem);
	$attr.KeyColumns[0].DataType =  [System.Data.OleDb.OleDbType]::Integer
	$dataItem = CreateDataItem $dsv  $calendarSchemaName 'AHLD_yearweekdayname';
	$attr.NameColumn=$dataItem;
	$attr.NameColumn.DataType =  [System.Data.OleDb.OleDbType]::WChar
	$attr.NameColumn.DataSize =  20
	$attrrel = New-Object Microsoft.AnalysisServices.AttributeRelationship("Ahold Week Number")
	$attrrel.RelationshipType=[Microsoft.AnalysisServices.RelationshipType]::Rigid
	$attr.AttributeRelationships.Add($attrrel);
	$attr.AttributeHierarchyVisible = [System.Boolean]::false;

	$keyAttr.AttributeRelationships.remove('Ahold Period');
	$keyAttr.AttributeRelationships.remove('Ahold Quarter');
	$keyAttr.AttributeRelationships.remove('Ahold Year');
	$keyAttr.AttributeRelationships.remove('Ahold Week Number');
	$keyAttr.AttributeRelationships.remove('Ahold Calendar Name');

	$Hier = $dim.Hierarchies.FindByName("Ahold Ad");
	if ($Hier -ne $NULL){
		$dim.Hierarchies.Remove("Ahold Ad");
	}

	$Hier = $dim.Hierarchies.Add("Ahold Ad");
	$Hier.Levels.Add("Ahold Calendar Name").SourceAttributeID = "Ahold Calendar Name";
	$Hier.Levels.Add("Ahold Year").SourceAttributeID = "Ahold Year";
	$Hier.Levels.Add("Ahold Quarter").SourceAttributeID = "Ahold Quarter";
	$Hier.Levels.Add("Ahold Period").SourceAttributeID = "Ahold Period";
	$Hier.Levels.Add("Ahold Week Number").SourceAttributeID = "Ahold Week Number";
	$Hier.Levels.Add("Day Number").SourceAttributeID = "Ahold Day Number";

	$measureGroup = $cube.MeasureGroups.FindByName("Store Sales")
	updateRegularDimUsage $cube $dsv "dbo_STORE_SALES" $measureGroup ("PERIOD_KEY","CALENDAR_KEY") ($NULL,[Microsoft.AnalysisServices.NullProcessing]::UnknownMember) $dim.ID "Date"
	#updateReferenceDimUsage $cube $measureGroup ("Time Calculation","Period ID") "Time Calculation" $dim.ID

	$measureGroup = $cube.MeasureGroups.FindByName("Baseline")
	updateRegularDimUsage $cube $dsv "dbo_BASELINE" $measureGroup ("PERIOD_KEY","CALENDAR_KEY") ($NULL,[Microsoft.AnalysisServices.NullProcessing]::UnknownMember) $dim.ID "Date"
	#updateReferenceDimUsage $cube $measureGroup ("Time Calculation","Period ID") "Time Calculation" $dim.ID

	$measureGroup = $cube.MeasureGroups.FindByName("DC SHIPMENT")
	updateRegularDimUsage $cube $dsv "dbo_DC_SHIPMENT" $measureGroup ("PERIOD_KEY","CALENDAR_KEY") ($NULL,[Microsoft.AnalysisServices.NullProcessing]::UnknownMember) $dim.ID "Date"
	#updateReferenceDimUsage $cube $measureGroup ("Time Calculation","Period ID") "Time Calculation" $dim.ID

	$measureGroup = $cube.MeasureGroups.FindByName("PLAN FACT")
	updateRegularDimUsage $cube $dsv "olap_PLAN_FACT" $measureGroup ("PERIOD_KEY","CALENDAR_KEY") ($NULL,[Microsoft.AnalysisServices.NullProcessing]::UnknownMember) $dim.ID "Date"
	#updateReferenceDimUsage $cube $measureGroup ("Time Calculation","Period ID") "Time Calculation" $dim.ID

	if ($fcst_enabled -eq 1)
	{
		$measureGroup = $cube.MeasureGroups.FindByName("FORECASTING")
		updateRegularDimUsage $cube $dsv "FORECASTING" $measureGroup ("PERIOD_KEY","CALENDAR_KEY") ($NULL,[Microsoft.AnalysisServices.NullProcessing]::UnknownMember) $dim.ID "Date"
		#updateReferenceDimUsage $cube $measureGroup ("Time Calculation","Period ID") "Time Calculation" $dim.ID
	}
	
	$measureGroup = $cube.MeasureGroups.FindByName("CALENDAR")
	updateDegenerateDimUsage $cube $measureGroup "Date" $dim.ID

	$dim.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull -bor [Microsoft.AnalysisServices.UpdateOptions]::AlterDependents);
	
	Write-Output ('Alert Calendar Dimension created sucessfully');
}

updateCalendarDimension $cube $d 'Fusion' $dsv

function dealAholdAdMeasureGroup
{ 
Param([Microsoft.AnalysisServices.MeasureGroup]$measureGroup)
	$calmeasureGroup = $cube.MeasureGroups.FindByName("CALENDAR")
	$meas=@()
	foreach($measure in $measureGroup.Measures) {
		if($measure.AggregateFunction -eq "LastNonEmpty" -or $measure.AggregateFunction -eq "AverageOfChildren") {
			if(-not $measure.name.EndsWith("Equivalent Units")) {
				$measureInternal = New-Object Microsoft.AnalysisServices.Measure
				$measureInternal.Name = $measure.name + ' Internal'
				$measureInternal.AggregateFunction = $measure.AggregateFunction
				$measureInternal.DataType = $measure.DataType
				$measureInternal.DisplayFolder = $measure.DisplayFolder
				$measureInternal.FormatString = $measure.FormatString
				$measureInternal.Source = $measure.Source.Clone()				
				$measureInternal.visible = $false
				$meas = $meas + $measureInternal
				
				$measure = $calmeasureGroup.Measures.FindByName("LY " + $measure.name);
				if($measure -ne $NULL) {
					$measureInternal = New-Object Microsoft.AnalysisServices.Measure
					$measureInternal.Name = $measure.name + ' Internal'
					$measureInternal.AggregateFunction = $measure.AggregateFunction
					$measureInternal.DataType = $measure.DataType
					$measureInternal.DisplayFolder = $measure.DisplayFolder
					$measureInternal.FormatString = $measure.FormatString
					$measureInternal.Source = $measure.Source.Clone()				
					$measureInternal.visible = $false
					$calmeasureGroup.Measures.Add($measureInternal)				
				}
			}
		}
	}
	foreach($measure in $meas) {
		[void] $measureGroup.Measures.Add($measure)
	}
}

$measureGroup = $cube.MeasureGroups.FindByName("Store Sales")
dealAholdAdMeasureGroup $measureGroup

$measureGroup = $cube.MeasureGroups.FindByName("Baseline")
dealAholdAdMeasureGroup $measureGroup

validateDefaultAggs $cube $serverName $dbName

$cube.update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull);

$server.disconnect()
