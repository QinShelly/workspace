Create table #MatchSurvey (column_name nvarchar(max), miss_count int)
DECLARE @sql NVARCHAR(MAX)
SELECT @sql = ''
Select @sql = @sql + 'insert into #MatchSurvey
select 
'''+COLUMN_NAME+''',count(fs.FactSurveyID)
from dbo.FactSurvey fs
JOIN dbo.vwFactSurvey vfs
ON fs.FactSurveyID = vfs.NativeSurveyID
AND fs.SurveyDataSourceID <> 60 AND vfs.SurveyDataSourceID <> 60
where fs.'+COLUMN_NAME+' <> vfs.'+COLUMN_NAME+' ' + CHAR(10)+ CHAR(13)

from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME = 'vwFactSurvey'
AND COLUMN_NAME NOT IN ('FactSurvey2ID','NativeSurveyID','TimeToClosesScore')
--print @sql
EXEC sp_executesql @sql

select * from #MatchSurvey

-- get diff id

DROP TABLE #SampleSurveyid
Create table #SampleSurveyid (column_name nvarchar(max), sample_survey_id int)
DECLARE @sql NVARCHAR(MAX)
SELECT @sql = ''
Select @sql = @sql + 'insert into #SampleSurveyid
select top 2
'''+column_name+''',fs.FactSurveyID
from dbo.FactSurvey fs
JOIN dbo.vwFactSurvey vfs
ON fs.FactSurveyID = vfs.NativeSurveyID
AND fs.SurveyDataSourceID <> 60 AND vfs.SurveyDataSourceID <> 60
where fs.'+column_name+' <> vfs.'+column_name+' 
AND fs.FactSurveyID > 1000' + CHAR(10)+ CHAR(13)

from #MatchSurvey
where miss_count > 0 

--print @sql

EXEC sp_executesql @sql