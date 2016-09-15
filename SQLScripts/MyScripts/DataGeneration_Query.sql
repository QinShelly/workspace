--#region Put Description Here
--===== Declare some obviously named variables
DECLARE @NumberOfRows INT,
        @StartValue   INT,
        @EndValue     INT,
        @Range        INT
;
--===== Preset the variables to known values
 SELECT @NumberOfRows = 1000000,
        @StartValue   = 400,
        @EndValue     = 500,
        @Range        = @EndValue - @StartValue + 1
;
--===== Conditionally drop the test table to make reruns easier in SSMS
     IF OBJECT_ID('tempdb..#SomeTestTable','U') IS NOT NULL
        DROP TABLE #SomeTestTable
;
--===== Create the test table with "random constrained" integers and floats
     -- within the parameters identified in the variables above.
 SELECT TOP (@NumberOfRows)
        SomeRandomInteger =  ABS(CHECKSUM(NEWID())) % @Range + @StartValue,
        SomeRandomFloat   = RAND(CHECKSUM(NEWID())) * @Range + @StartValue
   INTO #SomeTestTable
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
--#endregion

--#region Generate every Date
DECLARE @StartDate DATETIME, --Inclusive
        @EndDate   DATETIME, --Exclusive
        @Days      INT
;
 SELECT @StartDate = '1900', --Inclusive
        @EndDate   = '1901', --Exclusive
        @Days      = DATEDIFF(dd,@StartDate,@EndDate)
;
 SELECT TOP (@Days)
        TheDate = DATEADD(dd,ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1,@StartDate)
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2

--#endregion

--#region Generate every Month

DECLARE @StartDate DATETIME, --Inclusive
        @EndDate   DATETIME, --Exclusive
        @Months      INT
;
 SELECT @StartDate = '2000', --Inclusive
        @EndDate   = '2100', --Exclusive
        @Months    = DATEDIFF(mm,@StartDate,@EndDate)
;
 SELECT TOP (@Months)
        TheMonth = DATEADD(mm,ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1,@StartDate)
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
--#endregion
--#region Generate every Friday

DECLARE @StartDate DATETIME, --Inclusive
        @EndDate   DATETIME, --Exclusive
        @Weeks     INT
;
 SELECT @StartDate = '2012-01-06', --Inclusive
        @EndDate   = '2013-01-06', --Exclusive
        @Weeks     = DATEDIFF(dd,@StartDate,@EndDate)/7 --Don't use "WK" here
;
 SELECT TOP (@Weeks)
        Fridays = DATEADD(wk,ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1,@StartDate)
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2

--#endregion

--#region Generate every four hour
DECLARE @StartDate DATETIME, --Inclusive
        @EndDate   DATETIME, --Exclusive
        @Periods   INT
;
 SELECT @StartDate = 'Jan 2012', --Inclusive
        @EndDate   = 'Feb 2012', --Exclusive
        @Periods   = DATEDIFF(dd,@StartDate,@EndDate)*(24/4) --24 hours in a day, every 4 hours
;
 SELECT TOP (@Periods)
        Every4Hours = DATEADD(hh,ROW_NUMBER() OVER (ORDER BY (SELECT NULL))*4-4,@StartDate)
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
;
--#endregion

--#region Generate random Date

--===== Conditionally drop the test table to make reruns easier.
     IF OBJECT_ID('tempdb..#SomeTestTable','U') IS NOT NULL
        DROP TABLE #SomeTestTable
;
--===== Declare some obviously named variables
DECLARE @NumberOfRows INT,
        @StartDate    DATETIME,
        @EndDate      DATETIME,
        @Days         INT --This is still the "range"
;
--===== Preset the variables to known values
 SELECT @NumberOfRows = 1000000,
        @StartDate    = '2010', --Inclusive
        @EndDate      = '2020', --Exclusive
        @Days         = DATEDIFF(dd,@StartDate,@EndDate)
;
--===== Create "random constrained" integers within 
     -- the parameters identified in the variables above.
     -- "Bullet proofed" by using DATEADD instead of simple addition.
 SELECT TOP (@NumberOfRows)
        SomeRandomDate =  DATEADD(dd,ABS(CHECKSUM(NEWID())) % @Days, @StartDate)
   INTO #SomeTestTable
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2

SELECT MinDate = MIN(SomeRandomDate), 
        MaxDate = MAX(SomeRandomDate), 
        DistinctDates = COUNT(DISTINCT SomeRandomDate),
        Rows = COUNT(*)
   FROM #SomeTestTable

--#endregion
--#region Generate random DateTime


--===== Conditionally drop the test table to make reruns easier.
     IF OBJECT_ID('tempdb..#SomeTestTable','U') IS NOT NULL
        DROP TABLE #SomeTestTable
;
--===== Declare some obviously named variables
DECLARE @NumberOfRows INT,
        @StartDate    DATETIME,
        @EndDate      DATETIME,
        @Days         INT --This is still the "range"
;
--===== Preset the variables to known values
 SELECT @NumberOfRows = 1000000,
        @StartDate    = '2010', --Inclusive
        @EndDate      = '2020', --Exclusive
        @Days         = DATEDIFF(dd,@StartDate,@EndDate)
;
--===== Create the test table with "random constrained" integers and floats
     -- within the parameters identified in the variables above.
 SELECT TOP (@NumberOfRows)
        SomeRandomDateTime = RAND(CHECKSUM(NEWID())) * @Days + @StartDate
   INTO #SomeTestTable
   FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
;
--Here's the code that checks the extent of the random data.  
--===== Show the extent of the random whole dates
 SELECT MinDateTime   = MIN(SomeRandomDateTime), 
        MaxDateTime   = MAX(SomeRandomDateTime), 
        DistinctDates = COUNT(DISTINCT SomeRandomDateTime),
        Rows = COUNT(*)
   FROM #SomeTestTable
;
--===== Show ten rows of the table
 SELECT TOP 10 *
   FROM #SomeTestTable


--#endregion 

--#region Generate random data

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SourceTable]') AND type in (N'U'))
DROP TABLE [dbo].[SourceTable]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DestinationTable]') AND type in (N'U'))
DROP TABLE [dbo].[DestinationTable]
GO

CREATE TABLE SourceTable (
        ID INT NOT NULL PRIMARY KEY,
        RandomNumber DECIMAL(18,4) NOT NULL
);

CREATE TABLE DestinationTable (
        ID INT NOT NULL PRIMARY KEY,
        RandomNumber DECIMAL(18,4) NOT NULL
);
GO
--#endregion

--#region Get random value

SELECT TOP (100000)
    SomeObjectID = ABS(CHECKSUM(NEWID()))%10+1,
    SomeDate = DATEADD(dd,ABS(CHECKSUM(NEWID()))%3652,'2010')
  INTO #MyHead
  FROM master.sys.all_columns ac1
 CROSS JOIN master.sys.all_columns ac2

--#endregion
