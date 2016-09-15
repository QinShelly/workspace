DECLARE @ReturnCode INT
DEclare @SiloName nvarchar(2000)='$SiloName'--'Unilever_Safeway'
DEclare @ServerName nvarchar(2000)='$databaseServer'--'Unilever_Safeway'
DEclare @BuildN nvarchar(2000)='$BuildNumber'--'Unilever_Safeway'
DEclare @Hub nvarchar(2000)='$hub'--'Unilever_Safeway'
declare @FailedCount int
set @FailedCount=0
select @FailedCount=COUNT(1) from msdb.dbo.sysjobs as job
inner join msdb.dbo.sysjobhistory  as his
on his.job_id=job.job_id
where job.name=@SiloName+'#UpdatePartition'
and step_id=4
and message like '%failed%' and run_date>=20140112
group by job.name
if @FailedCount>0
begin
select top 1 'select '+ltrim(@FailedCount)+' as cou, '''+@SiloName+''' as SiloName,'''+@ServerName+''' as ServerName, '''+@Hub+''' as hub,'''+@BuildN+''' as BuildN union all ' as Output
from sysobjects
end
else
begin
select top 1 '--null' as Output
from sysobjects
end