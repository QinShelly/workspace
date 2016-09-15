use TempDB  /* Change to database appropriate for you */
go

if object_id('usp_SQLAgentJobDocumentation','P') is null
begin
  exec('create procedure usp_SQLAgentJobDocumentation as select X=1')
end
go

/*
=========================================================================================

 Procedure usp_SQLAgentJobDocumentation
 (c)2011, Brad Schulz (brad@stockciphering.com)
 
 Produce HTML code to document SQL Agent Jobs
 
 To run this, create a SQL Agent Job of Type CMDEXEC that does the following:
 
   bcp "exec YOURDATABASEHERE.YOURSCHEMAHERE.usp_SQLAgentJobDocumentation" 
       queryout "C:\SomeFolder\$(ESCAPE_DQUOTE(MACH))_SQLAgentDocumentation.htm" 
       -S$(ESCAPE_SQUOTE(SRVR)) -T -c -w

 (For a local named instance, you may want to add $(ESCAPE_DQUOTE(INST)) to the
  filename above).
  
 Alternatively, you could create an SSIS Package that will execute this
 procedure and output the contents to a flat file destination (with an .HTM extension)
 
 For further information, go to
 http://bradsruminations.blogspot.com/2011/04/documenting-your-sql-agent-jobs.html
 
 This procedure is free to download and use for personal, educational, and internal 
 corporate purposes, provided that this header is preserved. Redistribution or sale 
 of this procedure, in whole or in part, is prohibited without the author's express 
 written consent.
  
 Apr04,2011-Brad Schulz
   Written

=========================================================================================
*/
alter procedure usp_SQLAgentJobDocumentation
  --Optional parameters here to filter jobs you want
as
with SelectedJobs as
(
  --If you want to add parameters to the procedure to filter out
  --certain jobs, you can do it in the WHERE clause here
  select *
  from msdb.dbo.sysjobs j
  --where job_id=@Job_ID
  --where name like '%'+@JobNamePattern+'%'
  --where category_id=@JobCategoryID
)
,SysScheds as
(
  --Get all the System Schedules, getting a Frequency into readable English
  select schedule_id
        ,SchedDesc=TimeOfDay+Frequency+EffDtRange
  from msdb.dbo.sysschedules 
  cross apply 
    --Translate the dates and times into DATETIME values
    --And translate the times into HH:MM:SSam (or HH:MMam) strings
    (select StDate=convert(datetime
                          ,convert(varchar(8),active_start_date))
           ,EnDate=convert(datetime
                          ,convert(varchar(8),active_end_date))
           ,StTime=convert(datetime
                          ,stuff(stuff(right(1000000+active_start_time
                                            ,6)
                                      ,3,0,N':')
                                ,6,0,N':'))
           ,EnTime=convert(datetime
                          ,stuff(stuff(right(1000000+active_end_time
                                            ,6)
                                      ,3,0,N':')
                                ,6,0,N':'))
    ) F_DtTm
  cross apply
    --Translate the times into appropriate HH:MM:SSam or HH:MMam char formats
    (select replace(replace(replace(substring(lower(convert(varchar(30),StTime,109))
                                             ,13,14)
                                   ,N':000',N'')
                           ,N':00a',N'a')
                   ,N':00p',N'p')
           ,replace(replace(replace(substring(lower(convert(varchar(30),EnTime,109))
                                             ,13,14)
                                   ,N':000',N'')
                           ,N':00a',N'a')
                   ,N':00p',N'p')
    ) F_Tms(StTimeString,EnTimeString)
  cross apply 
    --What Time of Day? Single Time or Range of Times/Intervals
    (select case 
              when freq_subday_type=0
              then N''
              else case 
                     when freq_subday_type=1
                     then N'At '
                     else N'Every '
                         +convert(nvarchar(10),freq_subday_interval)
                         +' '
                         +case freq_subday_type
                            when 2 then N'Second'
                            when 4 then N'Minute'
                            when 8 then N'Hour'
                          end
                         +case 
                            when freq_subday_interval=1 then N'' else N's' end
                         +N' From '
                   end
                  +StTimeString
                  +case
                     when freq_subday_type=1
                     then N''
                     else N' to '+EnTimeString
                   end
                  +N' '
            end
    ) F_Tm(TimeOfDay)
  cross apply
    --Translate Frequency  
    (select case freq_type
              when 1
              then N'One Time Only'
              when 4
              then N'Every '
                  +case freq_interval 
                     when 1
                     then N'Day'
                     else convert(nvarchar(10),freq_interval)+N' Days'
                   end
              when 8
              then N'Every '
                  +case freq_recurrence_factor
                     when 1
                     then N''
                     else convert(nvarchar(10),freq_recurrence_factor)+N' Weeks on '
                   end
                  +stuff(case when freq_interval& 1<>0 then N', Sunday' else N'' end
                        +case when freq_interval& 2<>0 then N', Monday' else N'' end
                        +case when freq_interval& 4<>0 then N', Tuesday' else N'' end
                        +case when freq_interval& 8<>0 then N', Wednesday' else N'' end
                        +case when freq_interval&16<>0 then N', Thursday' else N'' end
                        +case when freq_interval&32<>0 then N', Friday' else N'' end
                        +case when freq_interval&64<>0 then N', Saturday' else N'' end
                        ,1,2,N'')
              when 16
              then N'Every '
                  +case freq_recurrence_factor 
                     when 1
                     then N'Month '
                     else convert(nvarchar(10),freq_recurrence_factor)+N' Months '
                   end
                  +N'on the '
                  +convert(nvarchar(10),freq_interval)
                  +case 
                     when freq_interval in (1,21,31)
                     then N'st'
                     when freq_interval in (2,22)
                     then N'nd'
                     when freq_interval in (3,23)
                     then N'rd'
                     else N'th'
                   end
                  +N' of the Month'
              when 32
              then N'Every '
                  +case freq_recurrence_factor 
                     when 1
                     then N'Month '
                     else convert(nvarchar(10),freq_recurrence_factor)+N' Months '
                   end
                  +N'on the '
                  +case freq_relative_interval 
                     when  1 then N'1st '
                     when  2 then N'2nd '
                     when  4 then N'3rd '
                     when  8 then N'4th '
                     when 16 then N'Last '
                   end
                  +case freq_interval 
                     when  1 then N'Sunday'
                     when  2 then N'Monday'
                     when  3 then N'Tuesday'
                     when  4 then N'Wednesday'
                     when  5 then N'Thursday'
                     when  6 then N'Friday'
                     when  7 then N'Saturday'
                     when  8 then N'Day'
                     when  9 then N'Weekday'
                     when 10 then N'Weekend Day'
                   end
                  +N' of the Month'
              when 64
              then N'When SQL Server Agent Starts'
              when 128
              then N'Whenever the CPUs become Idle'
              else N'Unknown'
            end
    ) F_Frq(Frequency)
  cross apply
    --When is it effective?
    (select N' (Effective '+convert(nvarchar(11),StDate,100)
           +case  
              when EnDate='99991231'
              then N''
              else N' thru '+convert(nvarchar(11),EnDate,100)
            end
           +N')'           
    ) F_Eff(EffDtRange)
)
,JobScheds as
(
  --Since a job can have multiple schedules, we will gather them
  --all together here by job, separating each schedule by a NCHAR(13)
  select j.job_id
        ,Schedules=stuff((select nchar(13)+SchedDesc
                          from msdb.dbo.sysjobschedules jsch
                          left join SysScheds ssch on jsch.schedule_id=ssch.schedule_id 
                          where jsch.job_id=j.job_id
                          for xml path(''),type).value('(/text())[1]','nvarchar(max)')
                         ,1,1,'')
  from SelectedJobs j
)
,JobDefs as
(  
  --Get Attributes and Values for Jobs
  select jobs.job_id
        ,AttribSeq
        ,Attrib
        ,Value
  from SelectedJobs jobs
  left join msdb.dbo.syscategories catgs on jobs.category_id=catgs.category_id
  left join master.dbo.syslogins logs on jobs.owner_sid=logs.sid
  left join JobScheds jsch on jobs.job_id=jsch.job_id
  cross apply 
    --Look at the last 100 (successful) executions for the job
    --and accumulate the Quantity (NumExecs) and Average Duration (AvgSecs)
    (select NumExecs=count(*)
           ,AvgSecs=avg(NumSecs)
     from (select top 100 NumSecs=run_duration/10000*3600
                                 +run_duration%10000/100*60
                                 +run_duration%100
           from msdb.dbo.sysjobhistory
           where job_id=jobs.job_id
             and step_id=0    --Full Job
             and run_status=1 --Succeeded
           order by run_date desc, run_time desc) x
    ) F_Hist
  cross apply
    --Translate the AvgSecs into "xx Hours xx Mins xx Secs"
    (select case NumExecs
              when 0
              then N'N/A'
              else case
                     when AvgSecs/3600>0
                     then convert(nvarchar(10),AvgSecs/3600)+N' Hour'
                         +case when AvgSecs/3600=1 then N'' else N's' end
                         +N' '
                     else N''
                   end
                  +case
                     when AvgSecs%3600/60>0
                     then convert(nvarchar(10),AvgSecs%3600/60)+N' Min'
                         +case when AvgSecs%3600/60=1 then N'' else N's' end
                         +N' '
                     else N''
                   end
                  +case 
                     when AvgSecs=0
                     then N'0 Secs'
                     when AvgSecs%60>0
                     then convert(nvarchar(10),AvgSecs%60)+N' Sec'
                         +case when AvgSecs%60=1 then N'' else N's' end
                     else N''
                   end
                  +N' (Across '+convert(nvarchar(5),NumExecs)+N' Execution'
                  +case when NumExecs=1 then N'' else N's' end
                  +N')'
            end
    ) F_AvgDur(AvgDuration)
  cross apply
    --Get alerts (if any) for the job
    (select stuff((select nchar(13)+name
                          +case when enabled=0 then N' (Disabled)' else N'' end
                   from msdb.dbo.sysalerts
                   where job_id=jobs.job_id
                   for xml path(''),type).value('(./text())[1]','nvarchar(max)')
                  ,1,1,N'')
    ) F_Alerts(AlertInfo)
  cross apply
    --Parse out the various notifications for the job
    (select stuff(case
                    when notify_level_email=0
                    then N''
                    else nchar(13)+N'Email '
                        +isnull((select name
                                 from msdb.dbo.sysoperators
                                 where id=notify_email_operator_id),N'???')
                        +N' when job '
                        +case notify_level_email 
                           when 1 then N'succeeds'
                           when 2 then N'fails'
                           when 3 then N'completes'
                         end
                  end
                +case
                   when notify_level_page=0
                   then N''
                   else nchar(13)+N'Page '
                       +isnull((select name
                                from msdb.dbo.sysoperators
                                where id=notify_page_operator_id),N'???')
                       +N' when job '
                       +case notify_level_page
                          when 1 then N'succeeds'
                          when 2 then N'fails'
                          when 3 then N'completes'
                        end
                 end
                +case
                   when notify_level_netsend=0
                   then N''
                   else nchar(13)+N'Net Send '
                       +isnull((select name
                                from msdb.dbo.sysoperators
                                where id=notify_netsend_operator_id),N'???')
                       +N' when job '
                       +case notify_level_netsend  
                          when 1 then N'succeeds'
                          when 2 then N'fails'
                          when 3 then N'completes'
                        end
                 end
                +case
                   when notify_level_eventlog=0
                   then N''
                   else nchar(13)+N'Write to Event Log when job '
                       +case notify_level_eventlog 
                          when 1 then N'succeeds'
                          when 2 then N'fails'
                          when 3 then N'completes'
                        end
                 end
                +case
                   when delete_level=0
                   then N''
                   else nchar(13)+N'Delete Job when it '
                       +case delete_level 
                          when 1 then N'succeeds'
                          when 2 then N'fails'
                          when 3 then N'completes'
                        end
                 end
                ,1,1,N'')
    ) F_Notify(NotifyInfo)
  cross apply 
    --Build AttribSeq/Attribute/Value list for the job
    (select 1,N'Description'
           ,jobs.description
     union all
     select 2,N'Status'
           ,case when jobs.enabled=1 then N'Enabled' else N'Disabled' end
     union all
     select 3,N'Created'
           ,convert(nvarchar(30),date_created,100)
     union all
     select 4,N'Modified'
           ,convert(nvarchar(30),date_modified,100)
     union all
     select 5,N'Owner'
           ,logs.name
     union all
     select 6,N'Category'
           ,catgs.name
     union all
     select 7,N'Avg Duration'
           ,AvgDuration
     union all
     select 8,N'Schedule(s)'
           ,isnull(Schedules,N'N/A')
     union all
     select 9,N'Alert(s)'
           ,AlertInfo
     union all
     select 10,N'Notification(s)'
           ,isnull(NotifyInfo,N'None')
     union all
     select 11,N'Start Step'
           ,isnull(N'Step #'+convert(nvarchar(10),start_step_id),N'N/A')
    ) F_JobDefs(AttribSeq,Attrib,Value)
)
,JobStepDefs as
(
  --Get Attributes and Values for individual Job Steps
  select job_id
        ,step_id
        ,AttribSeq
        ,Attrib
        ,Value
  from msdb.dbo.sysjobsteps s
  left join msdb.dbo.sysproxies p on s.proxy_id=p.proxy_id
  cross apply
    --On Success
    (select case on_success_action 
              when 1 then N'Quit Job with Success'
              when 2 then N'Quit Job with Failure'
              when 3 then N'Go To Next Step'
              else N'Go To Step #'+convert(nvarchar(10),on_success_step_id)
            end
    ) F_Succ(OnSuccess)
  cross apply
    --On Failure
    (select case retry_attempts
              when 0
              then N''
              else N'Attempt retry '
                  +case retry_interval
                     when 0 then N'immediately'
                     else N'in '+convert(nvarchar(10),retry_interval)
                         +N' min'+case when retry_interval=1 then N'' else N's' end
                   end
                  +case retry_attempts
                     when 1 then N''
                     else N', up to a maximum of '
                         +convert(nvarchar(10),retry_attempts)
                         +N' attempt'+case when retry_attempts=1 then N'' else N's' end
                   end
                  +nchar(13)
                  +N'If all attempts fail, '
            end
           +case on_fail_action 
              when 1 then N'Quit Job with Success'
              when 2 then N'Quit Job with Failure'
              when 3 then N'Go To Next Step'
              else N'Go To Step #'+convert(nvarchar(10),on_fail_step_id)
            end
    ) F_Fail(OnFailure)
  cross apply
    --Translate Last_Run_Duration into "xx Hours xx Mins xx Secs"
    (select case
              when last_run_date=0
              then N'N/A'
              else case
                    when last_run_duration/10000>0
                    then convert(nvarchar(10),last_run_duration/10000)+N' Hour'
                        +case when last_run_duration/10000=1 then N'' else N's' end
                        +N' '
                    else N''
                  end
                 +case
                    when last_run_duration%10000/100>0
                    then convert(nvarchar(10),last_run_duration%10000/100)+N' Min'
                        +case when last_run_duration%10000/100=1 then N'' else N's' end
                        +N' '
                    else N''
                  end
                 +case 
                    when last_run_duration=0
                    then N'0 Secs'
                    when last_run_duration%100>0
                    then convert(nvarchar(10),last_run_duration%100)+N' Sec'
                        +case when last_run_duration%100=1 then N'' else N's' end
                    else N''
                  end
            end
    ) F_LastDur(LastDuration)
  cross apply
    (select stuff(case 
                    when output_file_name is not null
                    then nchar(13)
                        +case 
                           when flags&2<>0 
                           then N'Append to File: ' 
                           else N'Overwrite File: '
                         end
                        +output_file_name 
                    else N''
                  end
                 +case
                    when flags&8<>0
                    then nchar(13)+N'Write Log to Table (Overwrite)'
                    else N''
                  end
                 +case
                    when flags&16<>0
                    then nchar(13)+N'Write Log to Table (Append)'
                    else N''
                  end
                 +case 
                    when flags&4<>0
                    then nchar(13)+N'Write to Step History'
                    else N''
                  end
                 ,1,1,N'')
    ) F_Output(OutputInfo)
  cross apply 
    (select case subsystem
              when N'ActiveScripting'
              then N'ActiveX Script (Using '+database_name+N')'
              when N'ANALYSISCOMMAND'
              then N'SSAS Command (Server='+server+N')'
              when N'ANALYSISQUERY'
              then N'SSAS Query (Server='+server+N', Database='+database_name+N')'
              when N'CmdExec'
              then N'CmdExec (Exit Code On Success='+convert(nvarchar(10),cmdexec_success_code)+N')'
              when N'Distribution'
              then N'Replication Distributer'
              when N'LogReader'
              then N'Replication Transaction-Log Reader'
              when N'Merge'
              then N'Replication Merge'
              when N'QueueReader'
              then N'Replication Queue Reader'
              when N'Snapshot'
              then N'Replication Snapshot'
              when N'SSIS'
              then N'SSIS Package'
              when N'TSQL'
              then N'TSQL (Database='+database_name+N')'
              else subsystem
            end
    ) F_Type(StepType)
  cross apply
    --Build AttribSeq/Attribute/Value list for the Job Step
    (select 1,N'On Success'
           ,OnSuccess
     union all
     select 2,N'On Failure'
           ,OnFailure
     union all
     select 3,N'Last Duration'
           ,LastDuration
     union all
     select 4,N'Output'
           ,OutputInfo
     union all
     select 5,N'Type'
           ,StepType
     union all
     select 6,N'Run As'
           ,nullif(isnull(p.name+N' ',N'')+isnull(database_user_name,N''),N'')
     union all
     select 999,N'Command'
           ,isnull(command,N'(No Command Defined)')
    ) F_StepDefs(AttribSeq,Attrib,Value)
)
,JobAndSteps as
(
  --Combine the Job and Steps together (giving the Job a Step_ID of 0)
  --Incorporate the HTML code (and translate special characters)
  --Job Titles Plus Beginning <TABLE> Tags:
  select job_id
        ,step_id=0
        ,AttribSeq=0
        ,HTM=N'<span style="font-size:x-large;"><b>'
            +replace(replace(replace(name
                                    ,N'&',N'&amp;')
                            ,N'<',N'&lt;')
                    ,N'>',N'&gt;')
            +N'</b></span>'
            +N'<table border=0><tr><td>&nbsp;&nbsp;&nbsp;</td><td>'
            +N'<table border=1 cellspacing=0 cellpadding=2>'
  from SelectedJobs 
  union all
  --Job Tables:
  select job_id
        ,step_id=0
        ,AttribSeq
        ,HTM=N'<tr><td valign=middle style="background-color=#DDDDDD;"><b>'+Attrib+N'</b></td><td>'
            +replace(replace(replace(replace(Value
                                            ,N'&',N'&amp;')
                                    ,N'<',N'&lt;')
                            ,N'>',N'&gt;')
                    ,nchar(13),N'<br/>')
            +N'</td></tr>'
  from JobDefs
  where Value is not null
  union all
  --Ending <TABLE> Tags:
  select job_id
        ,step_id=0
        ,AttribSeq=999
        ,HTM=N'</table></td></tr></table>'
  from SelectedJobs
  union all
  --Job Step Titles and Beginning <TABLE> Tags:
  select j.job_id
        ,s.step_id
        ,AttribSeq=0
        ,HTM=N'<br/><span style="font-size:large;"><b>'
            +N'Step #'+convert(nvarchar(10),s.step_id)+N': '
            +replace(replace(replace(s.step_name
                                    ,N'&',N'&amp;')
                            ,N'<',N'&lt;')
                    ,N'>',N'&gt;')
            +N'</b></span>'
            +N'<table border=0><tr><td>&nbsp;&nbsp;&nbsp;</td><td>'
            +N'<table border=1 cellspacing=0 cellpadding=2>'
  from SelectedJobs j
  join msdb.dbo.sysjobsteps s on j.job_id=s.job_id 
  --Job Step Tables (handle the "Command" Attribute in its own Table):
  union all
  select job_id
        ,step_id
        ,AttribSeq
        ,HTM=case 
               when Attrib=N'Command' 
               then N'</table></td></tr></table>'
                   +N'<table border=0><tr><td>&nbsp;&nbsp;&nbsp;</td><td>'
                   +N'<table border=0 cellpadding=10>'
                   +N'<tr><td style="font-family:Lucida Console,Courier New,Monospace;">'
               else N'<tr><td valign=middle style="background-color=#DDDDDD;"><b>'+Attrib+N'</b></td><td>'
             end
            +replace(replace(replace(replace(Value
                                            ,N'&',N'&amp;')
                                    ,N'<',N'&lt;')
                            ,N'>',N'&gt;')
                    ,nchar(13),N'<br/>')
            +case
               when Attrib=N'Command'
               then N'</td></tr></table></td></tr></table>'
               else N'</td></tr>'
             end
  from JobStepDefs
  where Value is not null
  union all
  --Ending Code for Job (Page Break):
  select job_id
        ,step_id=99999
        ,AttribSeq=0
        ,HTM=N'<br/>'
            +N'<hr style="color:#AAAAAA;page-break-after:always;">'
            +N'<br/>'
  from SelectedJobs
)
,JobSeqs as
(
  --Create a Job Sequence Number for jobs (ordered by their Name)
  select job_id
        ,JobSeq=row_number() over (order by name)
  from SelectedJobs
)
,FinalHTM as
(
  --Put together the final product
  --Beginning HTML for the entire Page:
  select JobSeq=0
        ,step_id=0
        ,AttribSeq=0
        ,HTM=N'<html>'
            +N'<head>'
            +N'<title>SQL Agent Jobs on '
            +replace(replace(replace(@@servername,N'&',N'&amp;'),N'<',N'&lt;'),N'>',N'&gt;')
            +N'</title>'
            +N'<style>'
            +N'body {font-family:Arial,Helvetica,Geneva,Swiss,Sans-Serif; font-size:small}'
            +N'th {font-family:Arial,Helvetica,Geneva,Swiss,Sans-Serif; font-size:small}'
            +N'td {font-family:Arial,Helvetica,Geneva,Swiss,Sans-Serif; font-size:small}'
            +N'</style>'
            +N'</head>'
            +N'<body>'
  union all
  --All the Job/Step Stuff (incorporating the JobSeq)
  select JobSeq
        ,step_id
        ,AttribSeq
        ,HTM
  from JobSeqs j
  join JobAndSteps js on j.job_id=js.job_id
  union all
  --Ending HTML for the Page:
  select JobSeq=99999
        ,step_id=0
        ,AttribSeq=0
        ,HTM=N'</body></html>'
)
--Output the whole thing in the appropriate order
select HTM
from FinalHTM        
order by JobSeq
        ,step_id
        ,AttribSeq


