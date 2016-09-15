USE [msdb]
GO

IF EXISTS (SELECT job_id
           FROM   msdb.dbo.sysjobs_view
           WHERE  name = N'$(dbName)#DQSendAlertEmailJob')
  EXEC msdb.dbo.Sp_delete_job
    @job_name=N'$(dbName)#DQSendAlertEmailJob',
    @delete_unused_schedule=1

GO

/****** Object:  Job [DQSendAlertEmailJob]    Script Date: 01/31/2013 18:21:06 ******/
BEGIN TRANSACTION

DECLARE @ReturnCode INT

SELECT @ReturnCode = 0

/****** Object:  JobCategory [[ALL]]]    Script Date: 01/31/2013 18:21:07 ******/
IF NOT EXISTS (SELECT name
               FROM   msdb.dbo.syscategories
               WHERE  name = N'[$(dbName)]'
                      AND category_class = 1)
  BEGIN
      EXEC @ReturnCode = msdb.dbo.Sp_add_category
        @class=N'JOB',
        @type=N'LOCAL',
        @name=N'[$(dbName)]'

      IF ( @@ERROR <> 0
            OR @ReturnCode <> 0 )
        GOTO QuitWithRollback
  END

DECLARE @jobId BINARY(16)

EXEC @ReturnCode = msdb.dbo.Sp_add_job
  @job_name=N'$(dbName)#DQSendAlertEmailJob',
  @enabled=1,
  @notify_level_eventlog=0,
  @notify_level_email=0,
  @notify_level_netsend=0,
  @notify_level_page=0,
  @delete_level=0,
  @description=N'No description available.',
  @category_name=N'[$(dbName)]',
  @owner_login_name=N'',
  @job_id = @jobId OUTPUT

IF ( @@ERROR <> 0
      OR @ReturnCode <> 0 )
  GOTO QuitWithRollback

/****** Object:  Step [Send Email]    Script Date: 01/31/2013 18:21:07 ******/
EXEC @ReturnCode = msdb.dbo.Sp_add_jobstep
  @job_id=@jobId,
  @step_name=N'Send Email',
  @step_id=1,
  @cmdexec_success_code=0,
  @on_success_action=1,
  @on_success_step_id=0,
  @on_fail_action=2,
  @on_fail_step_id=0,
  @retry_attempts=0,
  @retry_interval=0,
  @os_run_priority=0,
  @subsystem=N'TSQL',
  @command=N'


exec [dbo].[SP$RSI_DQ_SEND_EMAIL]',
  @database_name=N'$(dbName)',
  @flags=0

IF ( @@ERROR <> 0
      OR @ReturnCode <> 0 )
  GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.Sp_update_job
  @job_id = @jobId,
  @start_step_id = 1

IF ( @@ERROR <> 0
      OR @ReturnCode <> 0 )
  GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.Sp_add_jobschedule
  @job_id=@jobId,
  @name=N'Run at 22:00 PM every day',
  @enabled=1,
  @freq_type=4,
  @freq_interval=1,
  @freq_subday_type=1,
  @freq_subday_interval=0,
  @freq_relative_interval=0,
  @freq_recurrence_factor=0,
  @active_start_date=20130131,
  @active_end_date=99991231,
  @active_start_time=220000,
  @active_end_time=235959

IF ( @@ERROR <> 0
      OR @ReturnCode <> 0 )
  GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.Sp_add_jobserver
  @job_id = @jobId,
  @server_name = N'(local)'

PRINT 'Successfull database: $(dbName)'

IF ( @@ERROR <> 0
      OR @ReturnCode <> 0 )
  GOTO QuitWithRollback

COMMIT TRANSACTION

GOTO EndSave

QUITWITHROLLBACK:
PRINT 'Failed database: $(dbName)'
IF ( @@TRANCOUNT > 0 )
  ROLLBACK TRANSACTION

ENDSAVE:

GO 
