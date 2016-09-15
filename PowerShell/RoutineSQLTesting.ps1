#make sure no errors slip through
set-psdebug -strict; $ErrorActionPreference = "stop"

try { #Add-Type -path "${env:ProgramFiles(x86)}\XmlDiffPatch\Bin\xmldiffpatch.dll" 

Add-Type -path "C:\Users\ken.yao\Documents\MSDN\SQLXML Bulkload in .NET Code Sample\bin\Debug\xmldiffpatch.dll"
}
 #load xmldiffpatch to test results
catch #oops, he hasn't installed it yet
{
  write-warning @'
This routine currently compares results to make sure that the results
are what they should be. It uses XMLDiff, a NET tool. It can be downloaded
from https://www.microsoft.com/en-us/download/confirmation.aspx?id=24313. 
It only does so if you leave a file with the CorrectResult suffix in
the filename. If you don't want this facility, remove it! 
'@;
  exit;
}

$xmlDiff = New-Object Microsoft.XmlDiffPatch.XmlDiff;
# Create the XmlDiff object
$xmlDiff = New-Object Microsoft.XmlDiffPatch.XmlDiff(
  [Microsoft.XmlDiffPatch.XmlDiffOptions]::IgnoreChildOrder);
#poised to test results against what they should be
#here is the SQL batch for testing. It a real routine this would be pulled off disk
# but we need to keep this test simple
$SQL =@"
--the first query
print '(first)'
print '-SaveResult'
SELECT p1.ProductModelID
   FROM Production.Product AS p1
   GROUP BY p1.ProductModelID
   HAVING MAX(p1.ListPrice) >= ALL
    (SELECT AVG(p2.ListPrice)
   FROM Production.Product AS p2
   WHERE p1.ProductModelID = p2.ProductModelID);

--the second query
print '(Second)'
SELECT sum(s.TotalDue), count(*),
 right(convert(CHAR(11),s.OrderDate,113),8),TerritoryID
FROM Sales.SalesOrderHeader AS s
 GROUP BY right(convert(CHAR(11),s.OrderDate,113),8), TerritoryID WITH ROLLUP
 ORDER BY min(s.OrderDate)

 
--and the third query 
print '(final)'
print '-noMoreResult'

"@

$ErrorActionPreference = "Stop" # nothing can be retrieved
#--------------------These below need to be filled in! -----------------------------
#$pathToTest = "$env:USERPROFILE\MyPath"
$pathToTest = “c:\temp\"
$databasename = "AdventureWorks2008" #the database we want
$serverName = 'localhost' #the name of the server
$credentials = 'integrated Security=true' # fill this in before you run it!
# if SQL Server credentials, use 'user id=MyID;password=MyPassword'
#--------------------These above need to be filled in! -----------------------------

#now we declare our globals.
$connectionString = "Server=$serverName;DataBase=$databasename;$credentials;
	pooling=False;multipleactiveresultsets=False;packet size=4096";
#connect to the server
$message = [string]''; # for messages (e.g. print statements)
$Name = '';
$LastMessage = '';
$SQLError = '';
$previousName = '';
$SavingResult = $true;
$ThereWasASQLError = $false;
try #to make the connection
{
  $conn = new-Object System.Data.SqlClient.SqlConnection($connectionString)
  $conn.Open()
}
catch #can't make that connection
{
  write-warning @" 
Sorry, but I can't reach $databasename on the server instance $serverName. 
Maybe it is spelled wrong, credentials are wrong or the VPN link is broken.
I can't therefore run the test.
"@;
  exit
}
# This is the beating heart of the routine. It is called on receipt of every
# message or error
$conn.add_InfoMessage({#this is called on every print statement or message 
    param ($sender, #The source of the event
      $event) #the errors, message and source
    if ($event.Errors.count -gt 0) #there may be an error
    {
      $global:SQLError = "$($event.Errors)"; #remember the errors
      $global:ThereWasASQLError = ($global:SQLError -cmatch '(?im)\.SqlError: *\w')
      #you may think that if there is an error in the array... but no there are false alarms
    };
    $global:LastMessage = $event.Message; #save the message
    $global:message = "$($message)`n $($global:LastMessage)";#just add it
    switch -regex ($global:LastMessage) #check print statements for a switch
    {
      '(?im)\((.{2,25})\)' #was it the name of the query?
      {
        $global:Name = $matches[1] -replace '[\n\\\/\:\.]', '-'; #get the name in the brackets
        $null > "$pathToTest$($name).io"; #and clear out the io record for the query
        break;
      }
      '(?im)-NoMoreResult' { $global:SavingResult = $false; break; } #prevent saving of result
      '(?im)-SaveResult' { $global:SavingResult = $true; break; } #switch on saving of result
      default
      { #if we have some other message, then record the messge to a file
        if ($name -ne '') { "$($event.Message)" >> "$pathToTest$($name).io"; }
      }
    }
  }
  );
  $conn.FireInfoMessageEventOnUserErrors = $true; #collect even the errors as messages.
  #now we do the server settings to get IO and CPU from the server. 
  # We do them as separate batches just to play nice
  @('Set statistics io on;Set statistics time on;', 'SET statistics XML ON;') |
  %{ $Result = (new-Object System.Data.SqlClient.SqlCommand($_, $conn)).ExecuteNonQuery(); }
  #and we execute everything at once, recording how long it all took
  try #executing the sql
  {
    $timeTaken = measure-command { #measure the end-to-end time
      $rdr = (new-Object System.Data.SqlClient.SqlCommand($SQL, $conn)).ExecuteReader();
    }
  }
  catch
  {
    write-warning @" 
Sorry, but there was an error with executing the batch against $databasename
on the server instance $serverName. 
I can't therefore run the test.
"@;
    exit;
  }
  if ($ThereWasASQLError -eq $true)
  {
    write-warning @" 
Sorry, but there was an error '$SQLError' with executing the batch against $databasename
on the server instance $serverName. 
I can't therefore run the test.
"@;
  }
  
  #now we save each query, along with the query plans
  do #a loop
  {
    if ($name -eq $previousName) #if we have no name then generate one that's legal
    {
      $Name = ([System.IO.Path]::GetRandomFileName() -split '\.')[0]
    }#why would we want the file-type?
    #the first result will be the data so save it
    $datatable = new-object System.Data.DataTable
    $datatable.TableName = $name
    $datatable.Load($rdr)#pop it in a datatable
    if ($SavingResult) { $datatable.WriteXml("$pathToTest$($name).xml"); }
    #and write it out as XML so we can compare it easily
    else #if we aren't saving the result delete any previous tests
    {
      If (Test-Path "$pathToTest$($name).xml")
      {
        Remove-Item "$pathToTest$($name).xml"
      }
    }
    $datatable.close; #and close the datatable
    if ($rdr.GetName(0) -like '*showplan')#ah we have a showplan!!
    {
      while ($rdr.Read())#so read it all out quickly in one gulp
      {
        [system.io.file]::WriteAllText("$pathToTest$($name).sqlplan", $rdr.GetString(0));
      }
    }
    $previousName = $name #and remember the name to avoid duplicates
    #now we wonder if the DBA has left an XML file with the correct result?   
    if (test-path "$pathToTest$($name)CorrectResult.xml")
    { #there is a correct result to compare with!
      $CorrectResult = [xml][IO.File]::ReadAllText("$pathToTest$($name)CorrectResult.xml")
      $TestResult = [xml][IO.File]::ReadAllText("$pathToTest$($name).xml")
      if (-not $xmlDiff.Compare($CorrectResult, $TestResult))#if there were differences....
      { #do the difference report
        $XmlWriter = New-Object System.XMl.XmlTextWriter("$pathToTest$($name).differences", $Null)
        $xmlDiff.Compare($CorrectResult, $TestResult, $XmlWriter)
        $xmlWriter.Close();
        $message = "$message`nDifferences found to result of query '$name'"
      }
      else #remove any difference reports with the same name
      {
        If (Test-Path "$pathToTest$($name).differences")
        {
          Remove-Item "$pathToTest$($name).differences"
        }
      }
    }
  }
  while ($rdr.NextResult())# and get the next if there is one
  $rdr.Close()
  #now save all the messages for th batch including the errors.
  $message > "$($pathToTest)all.messages"
  #and add the end-to-end timing.
  "End-To-End time was $($timeTaken.Milliseconds) Ms" >> "$($pathToTest)all.messages"