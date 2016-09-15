$Filepath='C:\temp' # local directory to save build-scripts to
$DataSource='localhost' # server name and instance
$Database='JNJ_Boots'# the database to copy from
# set "Option Explicit" to catch subtle errors
set-psdebug -strict
$ErrorActionPreference = "stop" # you can opt to stagger on, bleeding, if an error occurs
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$ms='Microsoft.SqlServer'
$v = [System.Reflection.Assembly]::LoadWithPartialName( "$ms.SMO")
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
[System.Reflection.Assembly]::LoadWithPartialName("$ms.SMOExtended") | out-null
   }
$My="$ms.Management.Smo" #
$s = new-object ("$My.Server") $DataSource
if ($s.Version -eq  $null ){Throw "Can't find the instance $Datasource"}
$db= $s.Databases[$Database] 
if ($db.name -ne $Database){Throw "Can't find the database '$Database' in $Datasource"};
$transfer = new-object ("$My.Transfer") $db
$CreationScriptOptions = new-object ("$My.ScriptingOptions") 
$CreationScriptOptions.ExtendedProperties= $true # yes, we want these
$CreationScriptOptions.DRIAll= $true # and all the constraints 
$CreationScriptOptions.Indexes= $true # Yup, these would be nice
$CreationScriptOptions.Triggers= $true # This should be included when scripting a database
$CreationScriptOptions.ScriptBatchTerminator = $true # this only goes to the file
$CreationScriptOptions.IncludeHeaders = $true; # of course
$CreationScriptOptions.ToFileOnly = $true #no need of string output as well
$CreationScriptOptions.IncludeIfNotExists = $true # not necessary but it means the script can be more versatile
$CreationScriptOptions.Filename =  "$($FilePath)\$($Database)_Build.sql"; 
$transfer = new-object ("$My.Transfer") $s.Databases[$Database]

$transfer.options=$CreationScriptOptions # tell the transfer object of our preferences
$transfer.ScriptTransfer()
"All done"