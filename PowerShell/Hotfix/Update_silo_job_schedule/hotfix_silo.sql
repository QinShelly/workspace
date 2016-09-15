USE [msdb]

GO

DECLARE @ReturnCode INT

DEclare @SiloName nvarchar(2000)='$(SiloName)'--'Unilever_Safeway'

DEclare @ServerName nvarchar(2000)='$(ServerName)'--'Unilever_Safeway'

SELECT @ReturnCode = 0

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @jobId BINARY(16)

    SELECT @jobId = job_id
    FROM   msdb.dbo.sysjobs
    WHERE  name = @SiloName+'#DQCheckSiloGAPJob'

    IF @jobId IS NOT NULL
      BEGIN
          IF EXISTS(SELECT *
                    FROM   msdb.dbo.sysjobschedules AS jobs
                           INNER JOIN msdb.dbo.sysschedules AS s
                                   ON jobs.schedule_id = s.schedule_id
                    WHERE  s.name = N'Every 6 hours daily'
                           AND jobs.job_id = @jobId)
            BEGIN
                EXEC Sp_delete_jobschedule
                  @job_id = @jobId,
                  @name = N'Every 6 hours daily'

                EXEC @ReturnCode = msdb.dbo.Sp_add_jobschedule
                  @job_id=@jobId,
                  @name=N'Every 3 hours daily',
                  @enabled=1,
                  @freq_type=4,
                  @freq_interval=1,
                  @freq_subday_type=8,
                  @freq_subday_interval=3,
                  @freq_relative_interval=0,
                  @freq_recurrence_factor=0,
                  @active_start_date=20130130,
                  @active_end_date=99991231,
                  @active_start_time=0,
                  @active_end_time=235959

                PRINT 'Successfull Server: '+@ServerName+', Silo:'+@SiloName
            END
            ELSE
            BEGIN
                PRINT 'Already updated Server: '+@ServerName+', Silo:'+@SiloName
            END
      END

    COMMIT TRANSACTION
END TRY

BEGIN CATCH
    ROLLBACK TRANSACTION;

    PRINT 'Failed Server: '+@ServerName+', Silo:'+@SiloName
END CATCH 
