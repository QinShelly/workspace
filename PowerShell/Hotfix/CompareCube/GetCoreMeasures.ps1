cls

#[void][reflection.assembly]::LoadFile("C:\Program Files (x86)\Microsoft SQL Server\110\SDK\Assemblies\Microsoft.AnalysisServices.dll") 
[Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")

$servers = @(
	#@{"ServerName"=".\rsi";"DatabaseName"="WM_SALES_SUPPLYCHAIN_GLOBAL";}
	@{"ServerName"="engp3qa3\LIVE1";"DatabaseName"="COFFIE_ALPHA_UNIIN_SAMCAT";}
)

function GetDimTableName #([string]$servername, [string]$databasename, [string]$dimension) 
{ 
	param ([string]$servername, [string]$databasename, [string]$dimension) 
    $server=New-Object Microsoft.AnalysisServices.Server 
    $server.Connect($servername) 
    $db=$server.Databases.GetByName($databasename) 
    $tablename="Not Found Table" 
 
    foreach($dim in $db.Dimensions) 
    { 
        if($dimension -eq $dim.Name) 
        { 
            $tablename=$dim.KeyAttribute.NameColumn.Source.TableID 
            break 
        } 
    } 
    $tablename 
}
<#
#Create Dictionary Variable
function New-GenericDictionary([type] $keyType, [type] $valueType) 
{ 
    $base = [System.Collections.Generic.Dictionary``2] 
    $qc = $base.MakeGenericType($keyType, $valueType) 
    New-Object $qc 
} 

$dic = New-GenericDictionary string string 
foreach($view in $db.DataSourceViews) 
{ 
    foreach($t in $view.Schema.Tables) 
    { 
        $dic.Add($t.TableName,$t.ExtendedProperties["DbSchemaName"]+"."+$t.ExtendedProperties["DbTableName"]) 
        #Write-Host $t "<-->" $t.ExtendedProperties["DbSchemaName"]$t.ExtendedProperties["DbTableName"] #FriendlyName 
		Write-Host ("{0}<-->Type:{1},{2}.{3}" -f $t,$t.ExtendedProperties["TableType"],$t.ExtendedProperties["DbSchemaName"],$t.ExtendedProperties["DbTableName"]) 
    } 
}
#>

foreach($s in $servers) {
	$ServerName = $s.ServerName
	$DatabaseName = $s.DatabaseName

	$server=New-Object Microsoft.AnalysisServices.Server 
	$server.Connect($ServerName) 
	$db=$server.Databases.GetByName($DatabaseName) 
	#$cube=$db.Cubes.GetByName("test");

	$OutputFileName = "E:\Coffie\CompareCube\CUBE\Cubes_$($DatabaseName).txt"
	if(Test-Path -Path $OutputFileName) {
		Clear-Content $OutputFileName
	}
	Add-Content $OutputFileName "CubeName	MeasureGroup	MeasureName	Visible	FormatString	AggregateType	DisplayFolder	SourceTable	SourceColumn	Type" 

#start print metadata 
foreach($cube in $db.Cubes) 
{ 
	Write-Host "Cube Name: $cube" 
#	foreach($dim in $cube.Dimensions) #cube dimensions 
#	{ 
#	    #$dim 
#	    $tablename=GetDimTableName $ServerName $DatabaseName $dim.Dimension 
#	    #trap{ 
#	    $tablename=$dic.Item($tablename) 
#	    #} 
#	    $out="" 
#	    $out=$out+$cube.Name+"	"+$dim.Dimension+"	Cube Dimension:"+$dim.Name+"	Dimensions	"+$tablename 
#	    #Add-Content $OutputFileName $out 
#	} 
 
	#Core measure
	foreach($mg in $cube.MeasureGroups) 
	{ 
	    foreach($mea in $mg.Measures) 
	    { 
	        #$measure
	        #$tableID=$dic.Item($mea.Source.Source.TableID)    
	        $out="" 
	        $out=$out+"$($cube.Name)	$($mg.Name)	$($mea.Name)	$($mea.Visible)	$($mea.FormatString)	$($mea.AggregateFunction)	$($mea.DisplayFolder)	$($mea.Source.Source.TableID)	$($mea.Source.Source.ColumnID)	Core Measure"
	        Add-Content $OutputFileName $out 
	    }
	}

	#get calculation script 
	$mdxScript=$cube.DefaultMdxScript.Commands[0]
	$commands = $mdxScript.text.split(";")
	foreach($command in $commands)
	{
		$measure=""
		$format=""
		$measureGroup=""
		$visible=""
		$displayFolder=""
		$setName=""
	    if($command -match 'CREATE\s+MEMBER\s+(CURRENTCUBE\.)?\[Measures\]\.\[(?<name>[^\]]*)\]') 
	    {
	        $measure=$Matches.name
			$Matches.Clear()
			
			if($command -match 'FORMAT_STRING\s*=\s*\"(?<name>[^\]]*?)\"')
			{
				$format=$Matches.name
			}
			$Matches.Clear()
			
			if($command -match "ASSOCIATED_MEASURE_GROUP\s*=\s*\'(?<name>[^\]]*?)\'")
			{
				$measureGroup=$Matches.name
			}
			$Matches.Clear()
			
			if($command -match "DISPLAY_FOLDER\s*=\s*\'(?<name>[^\]]*?)\'") {
				$displayFolder = $Matches.name
			}
			$Matches.Clear()
			
			if($command -match 'VISIBLE\s*=\s*(?<name>[0-1])')
			{
			    #$regx = New-Object System.Text.RegularExpressions.Regex('VISIBLE\s*=\s*[0-1]')
				if($Matches.name -eq "1")
				{
					$visible="True"
				}
				else
				{
					$visible="False"
				}
			}
			else
			{
				$visible="True"
			}

	        $out=""
	        $out=$out+"$($cube.Name)	$measureGroup	$measure	$visible	$format		$displayFolder			Calculated Measure"
	        Add-Content $OutputFileName $out
	    }
		elseif($command -match 'CREATE\s+(HIDDEN)?\s*(DYNAMIC)?\s*SET\s+(CURRENTCUBE\.)?\[(?<name>[^\]]*)\]') {
			$setName = $Matches.name
			$out=""
			$out=$out+"$($cube.Name)		$setName							Set"
			Add-Content $OutputFileName $out
		}
	}
}
}
Write-Host "Done!"