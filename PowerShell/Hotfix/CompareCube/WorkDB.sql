
--if OBJECT_ID('dbo.CubeMetadata2') is not null
--drop table [dbo].[CubeMetadata2]
--go
--CREATE TABLE [dbo].[CubeMetadata2](
--	[CubeName] [nvarchar](100) NULL,
--	[MeasureGroup] [nvarchar](200) NULL,
--	[MeasureName] [nvarchar](200) NULL,
--	[Visible] [nvarchar](100) NULL,
--	[FormatString] [nvarchar](100) NULL,
--	[AggregateType] [nvarchar](100) NULL,
--	[DisplayFolder] [nvarchar](100) NULL,
--	[SourceTable] [nvarchar](100) NULL,
--	[SourceColumn] [nvarchar](100) NULL,
--	[Type] [nvarchar](100) NULL
--) ON [PRIMARY]

--GO



select a.DisplayFolder,a.MeasureName,a.FormatString,a.Type,b.DisplayFolder,b.MeasureName,b.FormatString,b.Type from 
(select 'Fusion' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='WM_CATEGORY_FAMILYCARE_US') a 
full join
(select 'Nextgen' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='COFFIE_UNL_ICECREAM_WMCAT') b on a.MeasureName=b.MeasureName
WHERE a.CubeName is null or b.CubeName is null
order by --a.MeasureName,
b.MeasureName,a.type desc

/*check the core measure difference*/
select a.MeasureGroup, a.DisplayFolder,a.MeasureName,a.FormatString,a.Type
,b.MeasureGroup,b.DisplayFolder,b.MeasureName,b.FormatString,b.Type 
--SELECT A.* --INTO #T
from 
(select 'Fusion' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='SC_SALES_SUPPLYCHAIN_US') a 
full join
(select 'Nextgen' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='COFFIE_ALPHA_UNIIN_SAMCAT') b 
on a.MeasureName=b.MeasureName
--and a.Visible = b.Visible
WHERE a.CubeName is null or b.CubeName is null 
and a.DisplayFolder not like 'fuzzy%' 
and A.MeasureName not like 'LY%' 
AND A.Type <>'SET'
order by --a.MeasureName,
a.type desc,a.MeasureGroup,a.MeasureName


select * from dbo.CubeMetadata2 where CubeName='SC_SALES_SUPPLYCHAIN_US'  
and type <> 'set'
order by Type,MeasureGroup,MeasureName

SELECT 'UNION SELECT ''WMCAT'' AS RETAILER_NAME, ''' + MEASURENAME +''' AS MEASURE_NAME, '''
+ CASE WHEN MEASUREGROUP LIKE '%STORE%' THEN 'STORE' WHEN MEASUREGROUP LIKE '%WHSE%' THEN 'DC' ELSE 'STORE' END 
+''' AS MEASUREGROUP_TYPE, ''U'' AS UNITSORSALES, ''false'' AS PIT'

--RETAILER_NAME,MEASURE_NAME,MEASUREGROUP_TYPE,UNITSORSALES,PIT
FROM #T WHERE MEASURENAME IS NOT NULL AND MEASURENAME NOT LIKE 'LY%'

SELECT * FROM #T


--visible
select * from 
(select 'Fusion' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='SC_SALES_SUPPLYCHAIN_US' and Type in ('Calculated Measure','Core Measure')) a
join
(select 'Nextgen' as CubeName,MeasureGroup,MeasureName,Visible,FormatString,AggregateType,DisplayFolder,Type 
from dbo.CubeMetadata2 where CubeName='COFFIE_ALPHA_UNIIN_SAMCAT' and Type in ('Calculated Measure','Core Measure')) b 
on a.MeasureName=b.MeasureName
and a.Visible<>b.Visible
order by a.Type desc,a.Visible,a.MeasureName


select distinct cubename from dbo.CubeMetadata2


select * from dbo.CubeMetadata2 where CubeName='COFFIE_ALPHA_UNIIN_SAMCAT' 
--and Type in ('Calculated Measure')-- ('Core Measure','Calculated Measure')
--and measureName like '%Sum Avg Instock Pct%'
order by Type,MeasureGroup,MeasureName





