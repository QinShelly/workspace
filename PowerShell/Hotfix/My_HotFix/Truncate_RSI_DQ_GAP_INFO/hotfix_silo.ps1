param($databaseServer="wal1wnfshub.colo.retailsolutions.com",
$databaseName="GAHUB",
$hub="",
$SiloName="")

Set-StrictMode -Version Latest
$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
import-module "$currentPath\sqlps.ps1"
$sql="
IF OBJECT_ID('dbo.RSI_DQ_GAP_INFO','u') is not null 
BEGIN
	IF EXISTS (SELECT TOP 1 * FROM  dbo.RSI_DQ_GAP_INFO WHERE  GAP = 'N')
	  BEGIN
		BEGIN TRY
			BEGIN TRANSACTION;
			IF OBJECT_ID('tempdb.dbo.#Temp20140808_$SiloName','u') is not null drop table #Temp20140808_$SiloName

			CREATE TABLE #Temp20140808_$SiloName(
					[SiloId] [nvarchar](500) NULL,
					[RetailerKey] int,
					[MeasureName] [nvarchar](500) NULL,
					[SubVendorId] [nvarchar](500) NULL,
					[DOW] [nvarchar](500) NULL,
					[MetricReceived] [nvarchar](10) NULL,
					[LagExpected] [int] NULL,
					[LastPeriodKey] [int] NULL,
					[ExpectPeriodKey] [int] NULL,
					[TimeStamp] [datetime] NULL,
					[GAP] [char](10) NULL,
					[MeasureAvailabilityFlag] [nvarchar](10) NULL,
					[MostRecentDate] [nvarchar](10) NULL,
					[SyncCount] int
				) 
			INSERT INTO #Temp20140808_$SiloName
			([SiloId],[RetailerKey],[MeasureName],[SubVendorId],[DOW],[MetricReceived],[LagExpected],[LastPeriodKey],[ExpectPeriodKey],[TimeStamp],[GAP],[MeasureAvailabilityFlag],[MostRecentDate],[SyncCount])
			
			SELECT TOP 1
			[SiloId],[RetailerKey],[MeasureName],[SubVendorId],[DOW],[MetricReceived],[LagExpected],[LastPeriodKey],[ExpectPeriodKey],[TimeStamp],[GAP],[MeasureAvailabilityFlag],[MostRecentDate],[SyncCount]
			FROM dbo.RSI_DQ_GAP_INFO WHERE  GAP = 'N'

			TRUNCATE TABLE dbo.RSI_DQ_GAP_INFO

			INSERT INTO dbo.RSI_DQ_GAP_INFO
			([SiloId],[RetailerKey],[MeasureName],[SubVendorId],[DOW],[MetricReceived],[LagExpected],[LastPeriodKey],[ExpectPeriodKey],[TimeStamp],[GAP],[MeasureAvailabilityFlag],[MostRecentDate],[SyncCount])
			SELECT TOP 1
			[SiloId],[RetailerKey],[MeasureName],[SubVendorId],[DOW],[MetricReceived],[LagExpected],[LastPeriodKey],[ExpectPeriodKey],[TimeStamp],[GAP],[MeasureAvailabilityFlag],[MostRecentDate],[SyncCount]
			FROM #Temp20140808_$SiloName WHERE  GAP = 'N'

			if OBJECT_ID('tempdb.dbo.#Temp20140808_$SiloName','u') is not null drop table #Temp20140808_$SiloName
			
			SELECT 'Completed to fix' AS OutPutString
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			SELECT 'Failure to fix' AS OutPutString
		END CATCH
		
	  END 
	  ELSE
	  BEGIN
		SELECT 'Already fixed' AS OutPutString
	  END
END
"
$silos=@(Invoke-Sqlcmd -Query $sql -ServerInstance $databaseServer -database $databaseName -QueryTimeout 65535)
foreach ($silo in $silos)
{
	$Output= $silo.OutPutString
	
	if($Output -eq "Failure to fix")
	{
		$Output="$Output Server=$databaseServer Silo=$databaseName"
	}
	write-host $Output
} 

