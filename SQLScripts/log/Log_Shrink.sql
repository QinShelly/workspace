--Check Log usage
DBCC SQLPERF(logspace)

-- method 1
--Shrink log file
USE AdventureWorks;
GO

-- to obtain the file_id of the data file.
SELECT file_id, name
FROM sys.database_files;

--have been discontinued in sql 2008
--BACKUP LOG dbWarehouse_Log1 WITH TRUNCATE_ONLY

-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE AdventureWorks
SET RECOVERY SIMPLE;
GO


-- method 2

-- Shrink the truncated log file to 1 MB.
DBCC SHRINKFILE (dbWarehouse_Log1, 1);
GO
-- Reset the database recovery model.
ALTER DATABASE AdventureWorks
SET RECOVERY FULL;
GO



--The ultimate method 3)

--a) Detach the database using sp_detach_db procedure (before that ensure no processes are using the database files.) 

--b) Delete the log file. 

--c) Attach the database again using sp_attach_db procedure.
