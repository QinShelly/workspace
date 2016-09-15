
function Hide-Measure {
	PARAM($code)
	if($code -match 'VISIBLE *?= *?"*?0"*?') {
		#nothing to do
		return $code
	} elseif ($code -match 'VISIBLE *?= *?"*?1"*?') {
		return $code -replace 'VISIBLE *?= *?"*?1"*?', 'VISIBLE=0'
	} else {
		if($code -match ';') {
			return $code -replace ';', ',VISIBLE=0;'
		} else {
			return $code + ', VISIBLE=0'
		}
	}
} 
$command="
CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand Volume Cases]
AS [Measures].[Regular DC On Hand Volume Cases]+[Measures].[Promoted DC On Hand Volume Cases],
FORMAT_STRING = '#,##0.00',DISPLAY_FOLDER = 'Inventory\On Hand' ,  ASSOCIATED_MEASURE_GROUP = 'STORE FACT';
"
if($command -match 'CREATE\s+MEMBER\s+(CURRENTCUBE\.)?\[Measures\]\.\[(?<name>[^\]]*)\]') {
			$name     = $matches.name
			$command = Hide-Measure $command 
			Write-Host $command
			}