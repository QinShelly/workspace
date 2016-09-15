-- drop constraints on newly added columns
declare @table_name nvarchar(256)

declare @Command nvarchar(max) = ''

set @table_name = N'FactSurvey'

select @Command = @Command + 'ALTER TABLE ' + @table_name + ' drop constraint ' + d.name + CHAR(10)+ CHAR(13)
from sys.tables t
join sys.default_constraints d
on d.parent_object_id = t.object_id
join sys.columns c
on c.object_id = t.object_id
and c.column_id = d.parent_column_id
where t.name = @table_name
and c.name in ('SPTreatedAsValuedSSAT',
'SPTreatedAsValuedDSAT',
'SPTreatedAsValuedVSAT',
'SPTreatedAsValuedQoSAnnswered',
'SPTreatedAsValuedScoree',
'ProcessSSAT',
'ProcessDSAT',
'ProcessVSAT',
'ProcessQosAnswered',
'ProcessScore',
'TimeToEngineerSSAT',
'TimeToEngineerDSAT',
'TimeToEngineerVSAT',
'TimeToEngineerQosAnswered',
'TimeToEngineerScore'
)

--print @Command

execute (@Command)
