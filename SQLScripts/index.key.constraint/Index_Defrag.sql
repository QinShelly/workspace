/* Written by Francisco Tapia <fhtapia@gmail.com>
-- http://sqlthis.blogspot.com
-- The following is provided as is 
-- if you use this code it is appreciated if you leave 
-- this comment in your header.
*/

/* Create report container files
-- At this level first check if the exist if they do, simply truncate the data within.*/
IF OBJECT_ID('dbo.db_defrag') IS NULL 
    BEGIN
        PRINT 'CREATE db_defrag'
        CREATE TABLE [dbo].[db_defrag]
            (
              [TableOwner] [nvarchar](500) NULL,
              [TableName] [nvarchar](500) NULL,
              [TableIndexName] [sysname] NULL,
              [avg_fragmentation_in_percent] [float] NULL,
              [ROWS] [bigint] NOT NULL,
              [TIMESTAMP] DATETIME DEFAULT GETDATE()
            )
        ON  [PRIMARY]
		
    END
ELSE 
    BEGIN
        PRINT 'TRUNCATE TABLE db_defrag'
        TRUNCATE TABLE db_defrag
    END
---------------------------------------------
IF OBJECT_ID('dbo.db_defrag_complete') IS NULL 
    BEGIN
        PRINT 'CREATE db_defrag_complete'
        CREATE TABLE [dbo].[db_defrag_complete]
            (
              [TableOwner] [nvarchar](500) NULL,
              [TableName] [nvarchar](500) NULL,
              [TableIndexName] [sysname] NULL,
              [avg_fragmentation_in_percent] [float] NULL,
              [ROWS] [bigint] NOT NULL,
              [TIMESTAMP] DATETIME DEFAULT GETDATE()
            )
        ON  [PRIMARY]
    END
ELSE 
    BEGIN
        PRINT 'TRUNCATE TABLE db_defrag_complete'
        TRUNCATE TABLE db_defrag_complete
    END

--

SET NOCOUNT ON
DECLARE @db_id SMALLINT,
    @db_name varchar(6),
    @message varchar(255),
    @dba as varchar(255), -- This will be your email address
    @squery varchar(1000) -- For Email 
SET @dba = 'YourEmailAddress@domain.com'
SET @db_id = DB_ID()
SET @db_name = DB_NAME()

/* I've setup Database Mail on my servers in order to get results for typical mainteance
-- You want to be notified that way you know if you need to re-act in case something goes awry */
SET @message = 'Collecting Statistics ' + CONVERT(VARCHAR(12), GETDATE(), 108)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
			

/* Sql Server 2005 introduces DMV's (Dynamic Management Views).  DMV's offer some great reporting
-- functionality.  In this instance I am using the index physical statistics DMV which provides me
-- with a sampling of indexes over 5% fragmentation as my where clause implies.  I am also limiting
-- my search for tables over 100000 rows as most tables with below this amount don't tend to need as much
-- TLC.  */			
INSERT  INTO db_defrag
        (
          TableOwner,
          TableName,
          TableIndexName,
          avg_fragmentation_in_percent,
          [ROWS]
        )
        SELECT  u.NAME AS TableOwner,
                OBJECT_NAME(i.object_id) AS TableName,
                i.name AS TableIndexName,
                phystat.avg_fragmentation_in_percent,
                ROWS
        FROM    sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL,
                                               'SAMPLED') phystat
                INNER JOIN sys.indexes i ON i.object_id = phystat.object_id
                                            AND i.index_id = phystat.index_id
                INNER JOIN sys.partitions p WITH ( NOLOCK ) ON p.OBJECT_ID = i.OBJECT_ID
                INNER JOIN sys.sysobjects o WITH ( NOLOCK ) ON o.ID = i.OBJECT_ID
                INNER JOIN sys.sysusers u WITH ( NOLOCK ) ON u.uid = o.uid
        WHERE   phystat.avg_fragmentation_in_percent >= 5
                AND ROWS >= 100000

SET @message = 'Collecting Statistics Completed'
    + CONVERT(VARCHAR(12), GETDATE(), 108)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
    @recipients = @dba, @subject = @message
			


	
SET NOCOUNT ON
DECLARE @defrag as bit,
    @jname AS VARCHAR(255)
SET @db_name = DB_NAME()
SET @defrag = 0


DECLARE @TableName AS VARCHAR(500),
    @TableOwner AS VARCHAR(500),
    @Rows AS BIGINT,
    @aAvg AS DECIMAL(10, 3),
    @SQL AS VARCHAR(1000)

/* It's nice to receive notifications*/
SET @message = 'Defrag Started at: ' + convert(varchar(20), getdate(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message


/**RUN BACKUP**/
SET @message = 'START BACKUP ' + CONVERT(VARCHAR(20), GETDATE(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
SET @jname = 'BACKUP - FULL - ' + @db_name
EXEC msdb.dbo.sp_start_job @jname

-- Wait for Backup to complete
DECLARE  @waittime AS DATETIME, @wait AS VARCHAR(8)
SELECT @waittime = DATEADD(minute, MAX((datediff( ss,  t3.backup_start_date, t3.backup_finish_date))/60.0) , 0)
 FROM backupset t3
 WHERE database_name = @db_name
 
 SELECT @wait = CONVERT(VARCHAR(8), @waittime, 108)

WAITFOR DELAY @wait




set @message = 'BACKUP COMPLETE ' + CONVERT(VARCHAR(20), GETDATE(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
           
--SETUP JOBS--
/* For the defrag process I like to turn off anything that may cause my DB to slowdown, I tend to turn off
-- backups, but I do backup the database before I start the defrag so this is of little consequence that the
-- backups are turned off Add to this list any of your jobs that may slow your system down during a defrag*/
SET @jname = 'BACKUP - DIFF - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 0
SET @jname = 'BACKUP - FULL - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 0
SET @jname = 'BACKUP - LOG - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 0
SET @jname = 'Maintain ' + @db_name + ' LOG' 
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 0
				
SET @jname = 'BACKUP - LOG - ' + @db_name
EXEC msdb..sp_update_alert @name = @jname, @enabled = 0

EXEC msdb..sp_update_alert @name = 'BACKUP - LOG - DEFRAG', @enabled = 1
EXEC msdb..sp_update_job @job_name = 'BACKUP - LOG - DEFRAG', @enabled = 1
    

/* Now the real fun begins */
/* So the process is a bit involved for the entire setup, but necessary.
-- The first thing I do is collect what I need to run a defrag or a re-organization on
-- Next I loop, but because this is a production system you don't get the luxury of 
-- defragging the entire system on one go (depending how long you have).
-- In my situation it was imperative that the defrag complete by a certain time.
-- On all my systems, the longest running table defrag is usually about 4 hours.  Since I need to return
-- the system to the users by that time I needed a killswitch so the processes end gracefully*/
WHILE EXISTS ( SELECT   *
               FROM     db_defrag )
    AND GETDATE() < '07/23/09 20:00:00' -- TimeOut Feature

    BEGIN
/* Start the loop, collects the first item in the list of work to do*/
        SELECT TOP 1
                @TableOwner = TableOwner,
                @TableName = TableName,
                @Rows = AVG(ROWS),
                @aAvg = AVG([avg_fragmentation_in_percent])
        FROM    db_defrag
        GROUP BY TableOwner,
                TableName
        ORDER BY AVG(ROWS) DESC


		
        IF @aAvg > 30 /* If the defrag percentage is over 30% then rebuild the index*/ 
            BEGIN
		
				/* Try to defrag the index online, incase any of your users should choose to log back into the system at that
				-- time, However not all indexes can be defragged online, for those the Try Catch feature allows you to take
				-- a separate route for your index where it will defrag it offline only in those situations */
                SET @SQL = 'BEGIN TRY ' + 'ALTER INDEX ALL ON [' + @TableOwner
                    + '].[' + @TableName
                    + '] REBUILD WITH(MAXDOP=2, ONLINE=ON)' + ' END TRY '
                    + +' BEGIN CATCH ' + 'ALTER INDEX ALL ON [' + @TableOwner
                    + '].[' + @TableName
                    + '] REBUILD WITH(MAXDOP=2, ONLINE=OFF)' + ' END CATCH '
			
                set @message = 'ReBuilding TABLE ' + @TableName + ' '
                    + CONVERT(VARCHAR(20), GETDATE(), 109)
                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                    @recipients = @dba, @subject = @message
			
                EXECUTE ( @SQL )

                set @message = 'Clearing from db_defrag table ' + @TableName
                    + ' ' + CONVERT(VARCHAR(20), GETDATE(), 109)
                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                    @recipients = @dba, @subject = @message
			

                INSERT  INTO db_defrag_complete
                        ( TableOwner,
                          TableName,
                          avg_fragmentation_in_percent,
                          ROWS )
                VALUES  ( @TableOwner,
                          @TableName,
                          @aAvg,
                          @Rows )
			/* Clear entry from work table */
                DELETE  FROM db_defrag
                WHERE   TableName = @TableName
			
			/* Keep those statistics updated */
                SET @SQL = 'UPDATE STATISTICS [' + @TableOwner + '].['
                    + @TableName + ']'
                SET @message = 'Update Statistics On ' + @TableName + ' '
                    + CONVERT(VARCHAR(20), GETDATE(), 109)
                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                    @recipients = @dba, @subject = @message
			
                EXEC ( @SQL )
            END
        ELSE 
            IF @aAvg > 5/* If the defrag percentage is over 5% but less than 30% then re-organize the index*/ 
                BEGIN
                    SET @SQL = 'ALTER INDEX ALL ON [' + @TableOwner + '].['
                        + @TableName + '] REORGANIZE' 
                    SET @message = 'ReOrganizing TABLE ' + @TableName + ' '
                        + CONVERT(VARCHAR(20), GETDATE(), 109)
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                        @recipients = @dba, @subject = @message

                    EXECUTE ( @SQL
                           )
                    SET @message = 'Clearing from db_defrag table '
                        + @TableName + ' ' + CONVERT(VARCHAR(20), GETDATE(), 109)
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                        @recipients = @dba, @subject = @message
			
                    INSERT  INTO db_defrag_complete
                            ( TableOwner,
                              TableName,
                              avg_fragmentation_in_percent,
                              ROWS )
                    VALUES  ( @TableOwner,
                              @TableName,
                              @aAvg,
                              @Rows )
			/* Clear entry from work table */
                    DELETE  FROM db_defrag
                    WHERE   TableName = @TableName
			/* Keep those statistics updated */
                    SET @SQL = 'UPDATE STATISTICS [' + @TableOwner + '].['
                        + @TableName + ']'
                    SET @message = 'Update Statistics On ' + @TableName + ' '
                        + CONVERT(VARCHAR(20), GETDATE(), 109)
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail',
                        @recipients = @dba, @subject = @message
                    EXEC ( @SQL )
                END
    END

SET @message = 'Defrag Ended at: ' + convert(varchar(20), getdate(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message


/* Remember all those jobs you disabled earlier?  
Time to re-enable them at the end of your processes */
        
SET @jname = 'BACKUP - DIFF - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 1
SET @jname = 'BACKUP - FULL - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 1
SET @jname = 'BACKUP - LOG - ' + @db_name
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 1
SET @jname = 'Maintain ' + @db_name + ' LOG' 
EXEC msdb..sp_update_job @job_name = @jname, @enabled = 1
                            
SET @jname = 'BACKUP - LOG - ' + @db_name
EXEC msdb..sp_update_alert @name = @jname, @enabled = 1

EXEC msdb..sp_update_alert @name = 'BACKUP - LOG - DEFRAG', @enabled = 0
EXEC msdb..sp_update_job @job_name = 'BACKUP - LOG - DEFRAG', @enabled = 0

SET @message = 'START BACKUP ' + CONVERT(VARCHAR(20), GETDATE(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
            

SET @jname = 'BACKUP - FULL - ' + @db_name
EXEC msdb.dbo.sp_start_job @jname
--Wait for Backup to complete
WAITFOR DELAY @wait

SET @message = 'BACKUP COMPLETE ' + CONVERT(VARCHAR(20), GETDATE(), 109)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
		



SET @db_id = DB_ID()
SET @db_name = DB_NAME()
IF OBJECT_ID('dbo.db_defrag_report') IS NULL
/* Almost to the home streatch.  It's nice to re-run the DMV and collect the changes to your work.
-- Now you can report what the table defrag was, and what it is now.  Nice! */

/* Setup the collection table for your report */ 
    BEGIN
        PRINT 'CREATE db_defrag_Report'
        CREATE TABLE [dbo].[db_defrag_report]
            (
              [TableOwner] [nvarchar](500) NULL,
              [TableName] [nvarchar](500) NULL,
              [TableIndexName] [sysname] NULL,
              [avg_fragmentation_in_percent] [float] NULL,
              [ROWS] [bigint] NOT NULL,
              [TIMESTAMP] DATETIME DEFAULT GETDATE()
            )
        ON  [PRIMARY]
    END
ELSE 
    BEGIN
        PRINT 'Truncate Report Table'
        TRUNCATE TABLE db_defrag_report
    END

SET @message = 'Collecting REPORT Statistics '
    + CONVERT(VARCHAR(12), GETDATE(), 108)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
			

INSERT  INTO db_defrag_report
        (  TableOwner,
          TableName,
          TableIndexName,
          avg_fragmentation_in_percent,
          [ROWS] )
        SELECT  u.NAME AS TableOwner,
                OBJECT_NAME(i.object_id) AS TableName,
                i.name AS TableIndexName,
                phystat.avg_fragmentation_in_percent,
                ROWS
        FROM    sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL,
                                               'SAMPLED') phystat
                INNER JOIN sys.indexes i ON i.object_id = phystat.object_id
                                            AND i.index_id = phystat.index_id
                INNER JOIN sys.partitions p WITH ( NOLOCK ) ON p.OBJECT_ID = i.OBJECT_ID
                INNER JOIN sys.sysobjects o WITH ( NOLOCK ) ON o.ID = i.OBJECT_ID
                INNER JOIN sys.sysusers u WITH ( NOLOCK ) ON u.uid = o.uid
        WHERE   ROWS >= 100000

SET @message = 'Collecting REPORT Statistics Completed'
    + CONVERT(VARCHAR(12), GETDATE(), 108)
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @subject = @message
			

--sp_send_dbmail
--DEFRAG REPORT
/* Email the report to your list of contacts (or yourself), in my situation I email everything to myself
-- when I am done reviewing I forward on to my colleagues that need access to the system once the system is
-- availalbe agian.  You can opt to make a variable for the receipients and update the script accordingly.
*/ 
SET @squery = 'SELECT CAST(a.TableOwner AS VARCHAR(3)) TableOwner, 
	   CAST(a.TableName AS VARCHAR(25)) TableName, 
		a.ROWS, 
		a.avg_fragmentation_in_percent PreviousFragmentation,
		b.AvgFragmentation CurrentFragmentation
	FROM ' + @db_name + '.dbo.db_defrag_complete a
	INNER JOIN  (
				SELECT 
					TableOwner,
					TableName
					,AVG(ROWS) Rows, AVG(avg_fragmentation_in_percent) AvgFragmentation
					FROM ' + @db_name + '.dbo.db_defrag_report
				GROUP BY TableOwner, TableName
				) b ON a.TableOwner = b.TableOwner AND a.TableName = b.TableName'
SET @message = @db_name + ' De-fragmentation Results'
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBMail', @recipients = @dba,
    @query = @squery,
    @subject = @message,
    @attach_query_result_as_file = 1 ;

/* Display Report if running from Query Analyzer otherwise comment out below */
SELECT  CAST(a.TableOwner AS VARCHAR(3)) TableOwner,
        CAST(a.TableName AS VARCHAR(25)) TableName,
        a.ROWS,
        a.avg_fragmentation_in_percent PreviousFragmentation,
        b.AvgFragmentation CurrentFragmentation
FROM    dbo.db_defrag_complete a
        INNER JOIN ( SELECT TableOwner,
                            TableName,
                            AVG(ROWS) Rows,
                            AVG(avg_fragmentation_in_percent) AvgFragmentation
                     FROM   dbo.db_defrag_report
                     GROUP BY TableOwner,
                            TableName
                   ) b ON a.TableOwner = b.TableOwner
                          AND a.TableName = b.TableName 
