param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$hub="",
$SiloName="",
$BuildNumber="")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

$sql="
DECLARE @IsRight1 INT=1,
        @IsRight2 INT=1,
		@OutPut varchar(max)='',
		@OutPut2 varchar(max)=''

IF EXISTS (SELECT *
           FROM   RSI_DIM_SILO
           WHERE  type = 'C')
  BEGIN
      SELECT @IsRight1 = Count(1),@OutPut=@OutPut+case when max(value) is null then '' else ' mdx:'+max(value) end
      FROM   RSI_CORE_CFGPROPERTY
      WHERE  name = 'rsi.cube.custom.mdx'
             AND value <> '`${rsi.install.home}\scripts\cubes\dsm\custom\category.mdx'

print  @OutPut

      SELECT @IsRight2 = Count(1),@OutPut2=@OutPut2+case when max(value) is null then '' else ' sql:'+max(value) end
	  FROM   RSI_CORE_CFGPROPERTY
      WHERE  name = 'db.custom.sql'
             AND value <> '`${rsi.install.home}\scripts\rdbms\dsm\custom\category.sql'

print  @OutPut2

      IF @IsRight1 + @IsRight2 = 0
        BEGIN
            set @OutPut= '--'
			set @OutPut2=''
        END
  END 

select @OutPut+@OutPut2 as Outputstr


  
"
#write-host $sql

$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
foreach ($silo in $silos){
	$Output= $silo.Outputstr
	if ($Output -eq "--")
	{
		write-host "--"
	}
	else
	{
		write-host "$Output $databaseName $databaseServer"
	}
	}

