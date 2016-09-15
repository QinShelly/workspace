<#
   This File contains Some Common Functions used in Creation/modification of SSAS Cube using Powershell Script
#>

## Add measures
$integerFormat="#,###"
$decimalFormat="#,##0.00"
$intCurrFormat="$#,##0"
$decCurrFormat="$#,##0.00"
$dateFormat="####-##-##"

<#
 This function adds/updates the base measure in measure group. If the measure exist then it will overwrite the properties otherwise
 it will add this new measure to measure group.
 Input Parameters : MeasureGroup Object, measure's Source Table ID, measure's Source Column, Measure Name,
 					diplay folder, format string, Aggregation Function (default is Sum), visible property,
					Source Column data type and measure Data type.
#>

function dealMeasureGroup
{ 
Param([Microsoft.AnalysisServices.MeasureGroup]$measureGroup,[string]$tableID, [string]$columnID, [string]$measureName,
[string]$displayFolder, [String]$formatStr, [String]$pit, [boolean] $visible=$true, [string]$sourceColDataType="Double", [string]$measureDataType="Double")

    $source = New-Object Microsoft.AnalysisServices.DataItem
	$source.NullProcessing = [Microsoft.AnalysisServices.NullProcessing]::Preserve
		
	$measure = New-Object Microsoft.AnalysisServices.Measure
	$measure.Name = $measureName

	if ($pit -eq '7') 
	{   
		$rowBind = New-Object Microsoft.AnalysisServices.RowBinding
		$rowBind.TableID = $tableID
		$measure.AggregateFunction = "Count"
		$source.Source = $rowBind
		$source.Source.TableID = $tableID
		$measure.Source = $source
	}
	 else {
	
		$colBind = New-Object Microsoft.AnalysisServices.ColumnBinding
		$colBind.tableID = $tableID
		$colBind.columnID = $columnID
		$source.DataType = [System.Data.OleDb.OleDbType]::$sourceColDataType
		$source.Source = $colBind
		if($pit -eq '1') { $measure.AggregateFunction = "LastNonEmpty" }
		elseif($pit -eq '2') { $measure.AggregateFunction = "AverageOfChildren" }
		elseif($pit -eq '3') { $measure.AggregateFunction = "Count" }
		elseif($pit -eq '4') { $measure.AggregateFunction = "Max" }
		elseif($pit -eq '5') { $measure.AggregateFunction = "Min" }
		elseif($pit -eq '6') { $measure.AggregateFunction = "None" }
		elseif($pit -eq '8') { $measure.AggregateFunction = "LastChild" }
		elseif($pit -eq '9') { $measure.AggregateFunction = "DistinctCount" }
		$measure.Source = $source
    }
	$measure.DataType = [Microsoft.AnalysisServices.MeasureDataType]::$measureDataType
	$measure.DisplayFolder = $displayFolder
	$measure.FormatString = $formatStr
	$measure.Visible = $visible
	$measureEx = $measureGroup.Measures.FindByName($measureName)
	if ($measureEx -ne $NULL) {
		write-host $measureName exists
		$measureEx.name = $measure.Name
		$measureEx.AggregateFunction = $measure.AggregateFunction
		$measureEx.DataType = $measure.DataType
		$measureEx.DisplayFolder = $measure.DisplayFolder
		$measureEx.Visible = $measure.Visible
		$measureEx.FormatString = $measure.FormatString
		$measureEx.Source = $source.Clone() 
	} else {
		write-host Adding $measureName
		[void] $measureGroup.Measures.Add($measure)
	}
}

<#
 This function gets the column name and its data type from dsv table.
 Input Parameters : dsv Object, Table Name, Column Name.
 Returns : Data Item.
#>

function CreateDataItem
{
Param([Microsoft.AnalysisServices.DataSourceView]$dsv, [string]$tableName, [string]$columnName)
	$dataTable = $dsv.Schema.Tables[$tableName]
	$dataColumn = $dataTable.Columns[$columnName]
	$dataItem = New-Object Microsoft.AnalysisServices.DataItem($tableName, $dataColumn.ColumnName)
	$dataItem.DataType = [Microsoft.AnalysisServices.OleDbTypeConverter]::GetRestrictedOleDbType($dataColumn.DataType)
	return $dataItem
}

<#
 This function creates column binding for given column ID.
 Input Parameters : Source Table ID, Source Column ID and Column da
 Returns : Data Item.
#>

function CreateColumnBindingDataItem
{
Param([string]$tableID, [string]$columnID, [System.Data.OleDb.OleDbType]$type)
	$colBind = New-Object Microsoft.AnalysisServices.ColumnBinding
	$colBind.tableID = $tableID
	$colBind.columnID = $columnID

	$dataItem = New-Object Microsoft.AnalysisServices.DataItem
	$dataItem.DataType = $type
	$dataItem.Source = $colBind
	
	return $dataItem
}

<#
 This function adds the new Table or View to the DSV.
 Input Parameters : OLEDB Connection Object, DSV Object, DSV Table Name, Query of table (to get the schema of  table),
 					Table Type (View or Table), Table DB Schema Name.
#>

function AddTabletoDSV
{
Param([System.Data.OleDb.OleDbConnection]$oledb, [Microsoft.AnalysisServices.DataSourceView]$dsv, [string]$dsvSchemaName, [string]$dsvQueryText
 , [String]$TableType="View", [String] $Db_SchemaName ="olap",[String]$DBTableName = $dsvSchemaName ) 

	$schema = $dsv.schema

	$selectCmd = New-Object System.Data.OleDb.OleDbCommand
	$selectCmd.CommandText = $dsvQueryText
	$selectCmd.Connection=$oledb
	$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
	$adapter.SelectCommand = $selectCmd

	$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, $dsvSchemaName)

	$dataTable = $dataTables[0];
	$dataTable.ExtendedProperties.Remove("TableType");
	$dataTable.ExtendedProperties.Add("TableType", $TableType);
	$dataTable.ExtendedProperties.Remove("DbSchemaName");
	$dataTable.ExtendedProperties.Add("DbSchemaName", $Db_SchemaName);
	$dataTable.ExtendedProperties.Remove("DbTableName");
	$dataTable.ExtendedProperties.Add("DbTableName", $DBTableName);
	$dataTable.ExtendedProperties.Remove("FriendlyName");
	$dataTable.ExtendedProperties.Add("FriendlyName", $DBTableName);
	#$dsv.Update()
}

<#
 This function adds the new dimension to the Cube Database.
 Input Parameters : Cube Database Object, DSV Name and Dimension Name.
#>
function AddDimension
{
Param([Microsoft.AnalysisServices.Database]$db, [string]$datasourceName, [string]$dimensionName)

	[Microsoft.AnalysisServices.Dimension] $dim = $db.Dimensions.FindByName($dimensionName);
	#Write-Output ('Dimension added')
	if ( $dim -eq $NULL) {
		$dim = $db.Dimensions.Add($dimensionName);
		$dim.ID = $dimensionName;
		$dim.Type = [Microsoft.AnalysisServices.DimensionType]::Regular;
		$dim.Source = New-Object Microsoft.AnalysisServices.DataSourceViewBinding $datasourceName;
		$dim.StorageMode = [Microsoft.AnalysisServices.DimensionStorageMode]::Molap;
	};
	return $dim
}

<#
   This function will add the new attribute to the given dimension table.
   Input Parameters : Dimension object,  Source Table ID of attribute, Source Column name of attribute,
   					  Attribute Name, data type of source column and Attribute usage (Key, Regular or parent)
#>
function AddAttribute
{
Param(	[Microsoft.AnalysisServices.Dimension]$dim,	[string]$tableID,	[string]$colName,	[string]$attribName 
		,[System.Data.OleDb.OleDbType]$type,	[Microsoft.AnalysisServices.AttributeUsage] $usage, [boolean] $visible=$true
		,[String]$nameColumn =$colName, [Boolean]$AttHierEnabled =$true, [Microsoft.AnalysisServices.OrderBy]$orderby='Name'
		,[String] $attDisplayFolder,[String] $orderByAttName =$null,[Microsoft.AnalysisServices.AttributeType] $attType='Regular'
		,[String]$valueColumn = $null,[System.Data.OleDb.OleDbType]$valueColtype = 'Integer')

	AddAttribute $dim $tableID @($colName) $attribName @($type) $usage $visible $nameColumn $AttHierEnabled $orderby $attDisplayFolder $orderByAttName $attType $valueColumn $valueColtype
}

function AddAttribute
{
Param(	[Microsoft.AnalysisServices.Dimension]$dim,	[string]$tableID,	[string[]]$colNames,	[string]$attribName 
		,[System.Data.OleDb.OleDbType[]]$types,	[Microsoft.AnalysisServices.AttributeUsage] $usage, [boolean] $visible=$true
		,[String]$nameColumn =$colNames[0], [Boolean]$AttHierEnabled =$true, [Microsoft.AnalysisServices.OrderBy]$orderby='Name'
		,[String] $attDisplayFolder,[String] $orderByAttName =$null,[Microsoft.AnalysisServices.AttributeType] $attType='Regular'
		,[String]$valueColumn = $null,[System.Data.OleDb.OleDbType]$valueColtype = 'Integer')

	[Microsoft.AnalysisServices.DimensionAttribute] $attr;

	$attr = $dim.Attributes.Add($attribName);
	$attr.Usage = $usage;
	$attr.Type = [Microsoft.AnalysisServices.AttributeType]::$attType;
	#$attr.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Name;
	$attr.AttributeHierarchyEnabled = $AttHierEnabled
	for ($i=0; $i -lt $colNames.Length; $i++){
		$dataItem = CreateColumnBindingDataItem $tableID $colNames[$i] $types[$i]
		[void] $attr.KeyColumns.Add($dataItem);
	}

	$attr.AttributeHierarchyVisible =$visible
	$attr.OrderBy = $orderby
	if ( $nameColumn -ne "")
	{
		$nameColDataItem = CreateColumnBindingDataItem $tableID $nameColumn wchar
	 	$attr.NameColumn = ($nameColDataItem)  
	}
	if ($attDisplayFolder -ne $null -and $attDisplayFolder -ne "")
	{
		$attr.AttributeHierarchyDisplayFolder = $attDisplayFolder
	}
	if ($orderByAttName -ne $null -and $orderByAttName -ne "")
	{
		$attr.OrderByAttributeID = $orderByAttName
	}
	if ($valueColumn -ne $null -and $valueColumn -ne "")
	{
		$valueColDataItem = CreateColumnBindingDataItem $tableID $valueColumn $valueColtype
	 	$attr.ValueColumn = ($valueColDataItem)  
	}
	
}
	

function AddRelationshiptoAttributes
{Param([Microsoft.AnalysisServices.Dimension]$dim,[String] $baseAttribute , [String] $relatedAttribute =$attribName, 
	[Microsoft.AnalysisServices.RelationshipType]$relType = 'Flexible' )

	$attr = $dim.attributes.findbyname("$baseAttribute")
	$relationship= New-Object Microsoft.AnalysisServices.AttributeRelationship
	$relationship.attribute= $attr
	$relationship.attributeID =$relatedAttribute
	if ($relType -ne $null -and $relType -ne "") {
		$relationship.RelationshipType	=$relType
	}
	[Void] $attr.AttributeRelationships.add($relationship)
}
<#
   This function will add the new dimension to Cube Object.
   Input Parameters : Cube Database object,  Cube Object, Dimension Name,
   					  Attribute Name, data type of source column and Attribute usage (Key, Regular or parent)
#>
function AddCubeDimension
{
Param([Microsoft.AnalysisServices.Database]$db, [Microsoft.AnalysisServices.Cube]$cube,  [string]$dimName, [Boolean] $visible=$true ,[string] $cubeDimName = $dimName)
	[Microsoft.AnalysisServices.Dimension] $dim = $db.Dimensions.FindByName($dimName);
	$cubeDim = $cube.Dimensions.Add($dim.ID) ;
	IF ($visible -ne $null)
	{
		$cubeDim.Visible =$visible
	}
	$cubeDim.Name = $cubeDimName
	 write-host $dimName " dimension has been added to the cube";
}

<#
   This function will add multiple attributes to regular measure group relationship.
   
 #>
function AddRegularDimMGRelationships
{
Param([Microsoft.AnalysisServices.Cube]$cube
                    , [Microsoft.AnalysisServices.MeasureGroup]$measureGroup
                    , $dataItems
                    , [string]$dimName
                    , [string]$dimAttrName)

    $curDim = $cube.Dimensions.GetByName($dimName);
    $regMgDim = New-Object Microsoft.AnalysisServices.RegularMeasureGroupDimension($curDim.ID);
    [void] $measureGroup.Dimensions.Add($regMgDim)
    $mgAttr = $regMgDim.Attributes.Add($curDim.Dimension.Attributes.GetByName($dimAttrName).ID)
    $mgAttr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
    foreach($dataItem in $dataItems) {
                    [void] $mgAttr.KeyColumns.Add($dataItem)
    }
    return $regMgDim
}


<#
   This function will add the Regular relationship between the Dimension and Measure group.
   Input Parameters : Cube Object,Measure Group name, measure group data Item, Dimension Name
   					 and Dimension Key column Attribute Name.
   Returns : Dimension Object
 #>
function AddRegularDimMGRelationship
{
Param([Microsoft.AnalysisServices.Cube]$cube
		, [Microsoft.AnalysisServices.MeasureGroup]$measureGroup
		, [Microsoft.AnalysisServices.DataItem]$dataItem
		, [string]$dimName
		, [string]$dimAttrName)

	$curDim = $cube.Dimensions.GetByName($dimName);
	$regMgDim = New-Object Microsoft.AnalysisServices.RegularMeasureGroupDimension($curDim.ID);
	$measureGroup.Dimensions.Add($regMgDim)
	$mgAttr = $regMgDim.Attributes.Add($curDim.Dimension.Attributes.GetByName($dimAttrName).ID)
	$mgAttr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
	
	$mgAttr.KeyColumns.Add($dataItem)
	return $regMgDim
}

<#
   This function will add the attribute to reglaur measure group relationship.
   
 #>
function AddAttributeToRegularDimMGRelationship
{
Param([Microsoft.AnalysisServices.RegularMeasureGroupDimension]$regMgDim
		, [Microsoft.AnalysisServices.DataItem]$dateItem
		, [string]$dimAttrName)
		
	$mgAttr = $regMgDim.Attributes.Add($dimAttrName)
	$mgAttr.KeyColumns.Add($dataItem[1])

}

<#
   This function will creates new measure group for Cube.
   Input Parameters : Cube Object, Measure Group Name, DropIfexists (To Know whether drop the measure group or not if it exists)
   Returns : Measuregroup Object
 #>
function CreateMeasuregroup ([Microsoft.AnalysisServices.Cube] $cube, [String] $measureGrpName,  [boolean] $DropIfExists=$false)
	{
		$measureGroup = $cube.MeasureGroups.FindByName($measureGrpName)
		if ($measureGroup -ne $NULL) { 
			if ($DropIfExists)
				{
				 $measureGroup.Drop()
				}
			else {
			   return $measureGroup
			}
		}
		$measureGroup = $cube.MeasureGroups.Add($measureGrpName)
		$measureGroup.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap
		$measureGroup.Type = [Microsoft.AnalysisServices.MeasureGroupType]::Regular
		Write-Host "Measure Group " $measureGrpName " created"
		return $measureGroup
	}



<# This function used to create the partion for given measure group with given partionName with table binding option.
	Input Parameters : Measure Group Object, DSV Name, Partition name, Measure Group DSV table name
#>

	function CreateMGPartition([Microsoft.AnalysisServices.MeasureGroup]$measureGroup, [string]$datasourceName, [string]$partitionName, [string]$MGdsvTableName)
	{
		[Microsoft.AnalysisServices.Partition] $part = $measureGroup.Partitions.FindByName($partitionName);
		if ( $part -ne $NULL) {
			Write-Output ('Drop Partition');
			$part.Drop([Microsoft.AnalysisServices.DropOptions]::AlterOrDeleteDependents );
		}
		$part = $measureGroup.Partitions.Add($partitionName);
		$part.ID = $partitionName;
		$part.NAME = $partitionName;
		$part.Source = New-Object Microsoft.AnalysisServices.DsvTableBinding($datasourceName, $MGdsvTableName) ;
		$part.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap;
		$part.ProcessingMode = [Microsoft.AnalysisServices.ProcessingMode]::Regular;
		$part.Update();
		Write-Output ('Partition created sucessfully');
	}
	
  <# This function will create refernced relationship between the given measure group($measureGroup) and dimension ($dimName) using
    parameter $interDimAttr as intermediate dimension.
	Input Parametes : Cube Object, Measure Group Object, Measure Group Key column name, Dimension Name, Intermediate Dimension Name,
					  Intermediate Dimension relationship attribute name.
  #>
  
	function updateReferenceDimUsage
	([Microsoft.AnalysisServices.Cube]$cube, [Microsoft.AnalysisServices.MeasureGroup]$measureGroup, [string[]]$mgColNames, [string]$dimName, [string]$interDimName
	, [string]$interDimAttr)
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
		$regMgDim1.IntermediateGranularityAttributeID = $interDim.Dimension.Attributes.GetByName($interDimAttr).ID;
		$regMgDim1.Materialization = [Microsoft.AnalysisServices.ReferenceDimensionMaterialization]::Regular;
		$measureGroup.Dimensions.Add($regMgDim1)
		
	}
	
<##
	This function updates the DSV Schema for given table/View. Use this function to update the table changes
	in backend database to DSV. 
##>	
	function redoSchemaforDSV ([Microsoft.AnalysisServices.DataSourceView]$dsv, [System.Data.OleDb.OleDbConnection]$oledbConn,	[String]$dsvTableName, [String]$DBTableName)
	{
		$schema = $dsv.schema
		$selectCmd = New-Object System.Data.OleDb.OleDbCommand
		$selectCmd.CommandText = "SELECT * FROM " + $DBTableName + " WHERE 1=0"
		$selectCmd.Connection=$oledbConn
		$adapter = New-Object System.Data.OleDb.OleDbDataAdapter
		$adapter.SelectCommand = $selectCmd
		
		$pkColumns = New-Object System.Collections.Generic.List[System.Data.DataColumn]
		$pkColumns =[System.Collections.Generic.List[System.Data.DataColumn]] $schema.Tables.ITEM($dsvTableName).PrimaryKey
		$nonPKColumns = New-Object System.Collections.Generic.List[System.Data.DataColumn]
		Foreach ($datCol in  $schema.Tables.ITEM($dsvTableName).Columns) 
		{if (-not ($pkColumns.Contains($datCol))) 
			{$nonPKColumns.Add($datCol)}
		}
		Foreach ($dcol in $nonPKColumns)
		{
			$schema.Tables.ITEM($dsvTableName).Columns.Remove($dcol)
		}
		$dataTables = $adapter.FillSchema($schema, [System.Data.SchemaType]::Mapped, $dsvTableName)
		##$dsv.Update()
	}

<##
	This function Adds the Descritization Bucket Count, Descritization method, format of display of buckets
	(it can be used to customize bucketing range display name) to a Dimension Attribute.
##>

	function updateDescritizationPropertytoAttribute([Microsoft.AnalysisServices.Dimension]$dim, [string]$attName,
		[int]$discretizationCount, [Microsoft.AnalysisServices.DiscretizationMethod]$discretizationMethod,[string]$formatString)
	{
		$attribute = $dim.Attributes.FindByName($attName)
		$attribute.DiscretizationBucketCount = $discretizationCount
		$attribute.DiscretizationMethod = $discretizationMethod
		if ($formatString -ne $null -or $formatString -ne '')
		{
			foreach ($keyColumn in $attribute.keyColumns)
			{$keyColumn.Format = $formatString}
		}
	}

function showHideCubeDimension ([Microsoft.AnalysisServices.Cube] $cube, [string]$cubeDimName, [boolean]$showOrHideFlag = $true)
{
	If (($cube -ne $null) -and ($cube.Dimensions.FindByName($cubeDimName) -ne $null))
		{
		$cubeDimObject = $cube.Dimensions.FindByName($cubeDimName)
		$cubeDimObject.Visible =$showOrHideFlag
		}
		
}

function CreateSchemaforDSV {
	param ([System.Data.SqlClient.SqlConnection]$sqldb,[System.Data.DataSet] $dataset, [string]$dsvSchemaName, [string]$dsvQueryText
 , [String]$TableType="View", [String] $Db_SchemaName ="olap",[String]$DBTableName = $dsvSchemaName,[String]$DBFriendlyName=$DBTableName)
	
	$selectCmd = New-Object System.Data.SqlClient.SqlCommand
	$selectCmd.CommandText = $dsvQueryText
	$selectCmd.Connection=$sqldb
	
	$adapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$adapter.SelectCommand = $selectCmd
	$dataTables=$adapter.FillSchema($dataset, [System.Data.SchemaType]::Source, $dsvSchemaName)
	
	$dataTable = $dataTables[0];
	$dataTable.ExtendedProperties.Remove("TableType");
	$dataTable.ExtendedProperties.Add("TableType", $TableType);
	$dataTable.ExtendedProperties.Remove("DbSchemaName");
	$dataTable.ExtendedProperties.Add("DbSchemaName", $Db_SchemaName);
	$dataTable.ExtendedProperties.Remove("DbTableName");
	$dataTable.ExtendedProperties.Add("DbTableName", $DBTableName);
	$dataTable.ExtendedProperties.Remove("FriendlyName");
	$dataTable.ExtendedProperties.Add("FriendlyName", $DBFriendlyName);
 	return $dataset
 }