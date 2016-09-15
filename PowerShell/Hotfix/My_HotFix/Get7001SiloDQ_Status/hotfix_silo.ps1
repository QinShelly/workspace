param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$hub="",
$SiloName="",
$BuildNumber="")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

$sql="
declare @ss varchar(100)
select @ss=  value from RSI_CORE_CFGPROPERTY where name ='db.domain.name'
select case when @ss not like '%`$%'
then ''
else '0 select ''$SiloName'' as SiloName,
''$SiloName'' as ServerName,
''$BuildNumber'' as BuildN,
''$hub'' as Hub union all' end as Outputstr
"
write-host $sql

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
foreach ($silo in $silos){
	$Output= $silo.Outputstr
	write-host $Output
	}

