declare @name nvarchar(100)
declare @cmd nvarchar(1000)
declare dbnames cursor for
select name from master.dbo.sysdatabases
open dbnames
fetch next from dbnames into @name
while @@fetch_status = 0
begin
set @cmd = 'select b.database_id, db=db_name(b.database_id),p.object_id,p.index_id,buffer_count=count(*) from ' + @name + '.sys.allocation_units a, '
+ @name + '.sys.dm_os_buffer_descriptors b, ' + @name + '.sys.partitions p
where a.allocation_unit_id = b.allocation_unit_id
and a.container_id = p.hobt_id
and b.database_id = db_id(''' + @name + ''')
group by b.database_id,p.object_id, p.index_id
order by b.database_id, buffer_count desc'
exec (@cmd)
fetch next from dbnames into @name
end
close dbnames
deallocate dbnames
go
