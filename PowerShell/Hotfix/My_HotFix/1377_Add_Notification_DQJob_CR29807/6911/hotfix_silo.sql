declare @Job_id varchar(200)=''
declare @HasSupportAccount int=0

select @HasSupportAccount=count(1) from msdb.dbo.sysmail_account
WHERE  name = 'Support'

if @HasSupportAccount>0
begin
	select @Job_id=job_id from msdb.dbo.sysjobs
	where name='$(siloName)#DQCheckSiloGAPJob'

	if @Job_id <>''
	begin
		EXEC msdb.dbo.sp_update_job @job_id=@Job_id, 
				@notify_level_email=2,
				@notify_email_operator_name=N'Support'
		Print '    Succeed for $(siloName) on $(serverName)'
	end
	Else
	begin
		Print '    Ignored for $(siloName) on $(serverName)'
	end
end
else
begin
	Print '    No Support Account for $(siloName) on $(serverName)'
end

GO
