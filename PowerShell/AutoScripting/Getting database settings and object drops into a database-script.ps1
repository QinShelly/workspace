 # set "Option Explicit" to catch subtle errors
set-psdebug -strict
$DirectoryToSaveTo='C:\temp\' # local directory to save build-scripts to
$servername='localhost' # server name and instance
$Database='JNJ_Boots' # the database to copy from
$ErrorActionPreference = "stop" # you can opt to stagger on, bleeding, if an error occurs
Trap {
# Handle the error
$err = $_.Exception
write-host $err.Message
while( $err.InnerException ) {
   $err = $err.InnerException
   write-host $err.Message
   };
# End the script.
break
}
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
   }
$My='Microsoft.SqlServer.Management.Smo'
$s = new-object ("$My.Server") $ServerName # get the server.
$Server=$s.netname -replace '[\\\/\:\.]',' ' # remove characters that can cause problems
$instance = $s.instanceName -replace '[\\\/\:\.]',' ' # ditto
$DatabaseName =$database -replace '[\\\/\:\.]',' ' # ditto
$DirectoryToSaveTo=$DirectoryToSaveTo+$Server+'\'+$Instance+'\' # database scripts are local on client
if (!( Test-Path -path "$DirectoryToSaveTo" )) # create it if not existing
       {$progress ="attempting to create directory $DirectoryToSaveTo"
              Try { New-Item "$DirectoryToSaveTo" -type directory | out-null }
             Catch [system.exception]{
       Write-Error "error while $progress. $_"
                return
                }
           }
<# now we will use the canteen system of SMO to specify what we want from the script. It is best to have a list of the defaults to hand and just override the defaults where necessary, but there is a chance that a later revision of SMO could change the defaults, so beware! #>
$CreationScriptOptions = new-object ("$My.ScriptingOptions")
$CreationScriptOptions.ExtendedProperties= $true # yes, we want these
$CreationScriptOptions.DRIAll= $true # and all the constraints
$CreationScriptOptions.Indexes= $true # Yup, these would be nice
$CreationScriptOptions.Triggers= $true # This should be included when scripting a database
$CreationScriptOptions.ScriptBatchTerminator = $true # this only goes to the file
$CreationScriptOptions.Filename = "$($DirectoryToSaveTo)$($DatabaseName)_Build.sql";
# we have to write to a file to get the GOs
$CreationScriptOptions.IncludeHeaders = $true; # of course
$CreationScriptOptions.ToFileOnly = $true # no need of string output as well
$CreationScriptOptions.IncludeIfNotExists = $true # not necessary but it means the script can be more versatile
$transfer = new-object ("$My.Transfer") $s.Databases[$Database]
$transfer.options=$CreationScriptOptions # tell the transfer object of our preferences
$scripter = new-object ("$My.Scripter") $s # script out the database creation
$scripter.options=$CreationScriptOptions # with the same options
$scripter.Script($s.Databases[$Database]) # do it
"USE $Database" | Out-File -Append -FilePath "$($DirectoryToSaveTo)$($DatabaseName)_Build.sql"
"GO" | Out-File -Append -FilePath "$($DirectoryToSaveTo)$($DatabaseName)_Build.sql"
# add the database object build script
$transfer.options.AppendToFile=$true
$transfer.options.ScriptDrops=$true
$transfer.EnumScriptTransfer()
$transfer.options.ScriptDrops=$false
$transfer.EnumScriptTransfer()
"All written to $($DirectoryToSaveTo)$($DatabaseName)_Build.sql"