SET NOCOUNT ON;
USE master;
GO

IF OBJECT_ID('dbo.PerfworkloadTraceStart', 'P') IS NOT NULL
      DROP PROC dbo.PerfworkloadTraceStart;
GO

CREATE PROC dbo.PerforworkloadTraceStart
      @dbid       AS INT,
      @tracefile  AS NVARCHAR(245),
      @traceid    AS INT OUTPUT
AS

-- Create a Queue
DECLARE @rc                   AS INT;
DECLARE @maxfilesize    AS BIGINT;

SET @maxfilesize = 5;

EXEC @rc = sp_trace_create @traceid OUTPUT, 0, @tracefile, @maxfilesize, NULL
IF (@rc != 0) GOTO error;

-- Set the events;
DECLARE @on AS BIT;
SET @on = 1;

-- RPC:Completed
EXEC sp_trace_setevent @traceid, 10, 15, @on;
EXEC sp_trace_setevent @traceid, 10, 8, @on;
EXEC sp_trace_setevent @traceid, 10, 16, @on;
EXEC sp_trace_setevent @traceid, 10, 48, @on;
EXEC sp_trace_setevent @traceid, 10, 1, @on;
EXEC sp_trace_setevent @traceid, 10, 17, @on;
EXEC sp_trace_setevent @traceid, 10, 10, @on;
EXEC sp_trace_setevent @traceid, 10, 18, @on;
EXEC sp_trace_setevent @traceid, 10, 11, @on;
EXEC sp_trace_setevent @traceid, 10, 12, @on;
EXEC sp_trace_setevent @traceid, 10, 13, @on;
EXEC sp_trace_setevent @traceid, 10, 6, @on;
EXEC sp_trace_setevent @traceid, 10, 14, @on;

-- SP:Completed
EXEC sp_trace_setevent @traceid, 43, 15, @on;
EXEC sp_trace_setevent @traceid, 43, 8, @on;
EXEC sp_trace_setevent @traceid, 43, 48, @on;
EXEC sp_trace_setevent @traceid, 43, 1, @on;
EXEC sp_trace_setevent @traceid, 43, 10, @on;
EXEC sp_trace_setevent @traceid, 43, 11, @on;
EXEC sp_trace_setevent @traceid, 43, 12, @on;
EXEC sp_trace_setevent @traceid, 43, 13, @on;
EXEC sp_trace_setevent @traceid, 43, 6, @on;
EXEC sp_trace_setevent @traceid, 43, 14, @on;

-- RPC:StmtCompleted
EXEC sp_trace_setevent @traceid, 45, 8, @on;
EXEC sp_trace_setevent @traceid, 45, 16, @on;
EXEC sp_trace_setevent @traceid, 45, 48, @on;
EXEC sp_trace_setevent @traceid, 45, 1, @on;
EXEC sp_trace_setevent @traceid, 45, 17, @on;
EXEC sp_trace_setevent @traceid, 45, 10, @on;
EXEC sp_trace_setevent @traceid, 45, 18, @on;
EXEC sp_trace_setevent @traceid, 45, 11, @on;
EXEC sp_trace_setevent @traceid, 45, 12, @on;
EXEC sp_trace_setevent @traceid, 45, 13, @on;
EXEC sp_trace_setevent @traceid, 45, 6, @on;
EXEC sp_trace_setevent @traceid, 45, 14, @on;
EXEC sp_trace_setevent @traceid, 45, 15, @on;

-- SQL:BatchCompleted
EXEC sp_trace_setevent @traceid, 12, 15, @on;
EXEC sp_trace_setevent @traceid, 12, 8, @on;
EXEC sp_trace_setevent @traceid, 12, 16, @on;
EXEC sp_trace_setevent @traceid, 12, 48, @on;
EXEC sp_trace_setevent @traceid, 12, 1, @on;
EXEC sp_trace_setevent @traceid, 12, 17, @on;
EXEC sp_trace_setevent @traceid, 12, 6, @on;
EXEC sp_trace_setevent @traceid, 12, 10, @on;
EXEC sp_trace_setevent @traceid, 12, 14, @on;
EXEC sp_trace_setevent @traceid, 12, 18, @on;
EXEC sp_trace_setevent @traceid, 12, 11, @on;
EXEC sp_trace_setevent @traceid, 12, 12, @on;
EXEC sp_trace_setevent @traceid, 12, 13, @on;

-- SQL:StmtCompleted
EXEC sp_trace_setevent @traceid, 41, 15, @on;
EXEC sp_trace_setevent @traceid, 41, 8, @on;
EXEC sp_trace_setevent @traceid, 41, 16, @on;
EXEC sp_trace_setevent @traceid, 41, 48, @on;
EXEC sp_trace_setevent @traceid, 41, 1, @on;
EXEC sp_trace_setevent @traceid, 41, 17, @on;
EXEC sp_trace_setevent @traceid, 41, 10, @on;
EXEC sp_trace_setevent @traceid, 41, 18, @on;
EXEC sp_trace_setevent @traceid, 41, 11, @on;
EXEC sp_trace_setevent @traceid, 41, 12, @on;
EXEC sp_trace_setevent @traceid, 41, 13, @on;
EXEC sp_trace_setevent @traceid, 41, 6, @on;
EXEC sp_trace_setevent @traceid, 41, 14, @on;

-- Set the filters

-- Appplication name filter
EXEC sp_trace_setfilter @traceid, 10, 0, 7, N'SQL Server Profiler%';
-- Database ID filter
EXEC sp_trace_setfilter @traceid, 3, 0, 0, @dbid;

-- Set the trace status to start
EXEC sp_trace_setstatus @traceid, 1;

-- Print trace id and filename for future references
PRINT 'Trace ID: ' + CAST(@traceid AS VARCHAR(10)) + ', Trace File: ''' + @tracefile + '.trc''';

GOTO finish;

error:
PRINT 'Error Code: ' + CAST(@rc AS VARCHAR(10));

finish:
GO

-----------------------------------
-- To start the SQL Server trace

DECLARE @dbid AS INT, @traceid AS INT;
SET @dbid = DB_ID('<Database Name>');

EXEC master.dbo.PerfworkloadTraceStart
      @dbid = @dbid,
      @tracefile = 'c:\temp\Perfworkload 20091205',
      @traceid = @traceid OUTPUT;
      
-----------------------------------
-- Stop and close the trace
EXEC sp_trace_setstatus 2, 0;
EXEC sp_trace_setstatus 2, 2;


-----------------------------------
-- Analyze Trace Data
USE Performance;
IF OBJECT_ID(' dbo.Workload', 'U' ) IS NOT NULL DROP TABLE dbo.Workload;
GO
SELECT CAST(TextData AS NVARCHAR(MAX)) AS tsql_code,
  Duration AS duration
INTO dbo.Workload
FROM sys.fn_trace_gettable(' c:\temp\Perfworkload 20091205.trc', NULL) AS T
WHERE Duration > 0
  AND EventClass IN(41, 45);

-----------------------------------
-- Convert a SQL query into a template
IF OBJECT_ID(' dbo.SQLSig' , ' FN') IS NOT NULL 
  DROP FUNCTION dbo.SQLSig; 
GO 
 
CREATE FUNCTION dbo.SQLSig  
  (@p1 NTEXT, @parselength INT = 4000) 
RETURNS NVARCHAR(4000) 
 
-- 
-- This function is provided "AS IS" with no warranties, 
-- and confers no rights.  
--Use of included script samples are subject to the terms specified at 
-- http://www.microsoft.com/info/cpyright.htm 
--  
-- Strips query strings 
AS 
BEGIN  
  DECLARE @pos AS INT; 
  DECLARE @mode AS CHAR(10); 
  DECLARE @maxlength AS INT; 
  DECLARE @p2 AS NCHAR(4000); 
  DECLARE @currchar AS CHAR(1), @nextchar AS CHAR(1); 
   DECLARE @p2l en AS INT; 
 
  SET @maxlength = LEN(RTRIM(SUBSTRING(@p1, 1,4000) )); 
  SET @maxlength = CASE WHEN @maxlength > @parselength  
                     THEN @parselength ELSE @maxlength END; 
  SET @pos = 1; 
  SET @p2 = '' ; 
  SET @p2len = 0; 
  SET @currchar = ' ' ; 
  set @nextchar = ' ' ; 
  SET @mode = ' command' ;

  WHILE (@pos <= @maxlength) 
  BEGIN 
    SET @currchar = SUBSTRING(@p1, @pos, 1) ; 
    SET @nextchar = SUBSTRING(@p1, @pos+1, 1); 
    IF @mode = ' command' 
    BEGIN 
      SET @p2 = LEFT(@p2, @p2len) + @currchar; 
      SET @p2len = @p2l en + 1 ; 
      IF @currchar IN (' , ',' (',' ' ,'=' , '<' , '>' , ' !' ) 
        AND @nextchar BETWEEN '0' AND ' 9' 
      BEGIN 
        SET @mode = 'number' ; 
        SET @p2 = LEFT(@p2,@p2len) + ' #'; 
        SET @p2len = @p2len + 1; 
      END  
      IF @currchar = '' ' ' 
      BEGIN 
        SET @mode = 'literal ' ; 
        SET @p2 = LEFT(@p2,@p2len) + ' #'' ' ; 
        SET @p2len = @p2len + 2; 
      END 
    END 
    ELSE IF @mode = 'number' AND @nextchar IN (' ,' , ' )', ' ', ' =',' <' ,' >' ,'! ' ) 
      SET @mode= 'command'; 
    ELSE IF @mode = 'literal ' AND @currchar = ' ' '' 
      SET @mode= 'command'; 
 
    SET @pos = @pos + 1; 
  END 
  RETURN @p2; 
END 

GO
