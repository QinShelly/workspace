IF OBJECT_ID('tempdb..#INDEX_STATE') is not null drop table #INDEX_STATE
create table #INDEX_STATE (
    [Name] sql_variant
,   [Updated] sql_variant
,   [Rows] sql_variant
,   [Rows Sampled] sql_variant
,   [Steps] sql_variant
,   [Density] sql_variant
,   [Average key length] sql_variant
,   [String index] sql_variant
,   [Filter Expression] nvarchar(max)
,   [UnfilteredRows] sql_variant
)
go
declare c cursor static for
select object_id, name, index_id from sys.indexes where name like '%VersionNumber%' order by name
open c
      declare @obj int
      declare @statsname varchar(max)
      declare @indid int
      declare @tname varchar(max)
fetch next from c into @obj, @statsname, @indid
while (@@fetch_status = 0)
begin
      declare @internaltablename varchar(max)
      declare @stmt varchar(max)
      fetch next from c into @obj, @statsname, @indid
      select top 1 @tname = name from sys.objects where object_id = @obj
      select @internaltablename = t.name from sys.indexes i join sys.tables t on i.object_id = t.object_id where i.name = @statsname
      --exec ('UPDATE STATISTICS ' + @internaltablename + ' ' + @statsname ) 
      insert into #INDEX_STATE exec('dbcc show_statistics (''' + @internaltablename + ''', ''' + @statsname + ''') with  STAT_HEADER')
end
close c
deallocate c
select * from #INDEX_STATE
