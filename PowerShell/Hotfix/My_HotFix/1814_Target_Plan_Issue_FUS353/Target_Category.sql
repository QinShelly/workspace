IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn$rsi_plan_sql]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fn$rsi_plan_sql]
GO

CREATE FUNCTION [dbo].[fn$rsi_plan_sql] 
(
	@day INT,
	@onHandDay INT,
	@tables VARCHAR(max)
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @startDay AS INT ;
	DECLARE @endDay AS INT ;
	DECLARE @prevDay AS INT ;
	DECLARE @lyDay AS INT ;
	DECLARE @tyaDay AS INT ;
	
	execute @startDay = [dbo].[fn$rsi_plan_range] @day, 0
	
	execute @endDay = [dbo].[fn$rsi_plan_range] @day, 1
	
	SET @lyDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -364, CONVERT(VARCHAR, @day)), 112)) ;
	SET @tyaDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -728, CONVERT(VARCHAR, @day)), 112)) ;
	SET @prevDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -1, CONVERT(VARCHAR, @day)), 112)) ;
	
	declare @onHandExists tinyint
	set @onHandExists = 0
	if exists(select top 1 period_key from [olap].[V$STORE_SALES] fact
					where fact.PERIOD_KEY = CONVERT(VARCHAR, @day) and [Store On Hand Volume Units] is not null)
		set @onHandExists = 1
		
	DECLARE @sql varchar(max)

	declare @tmpSql1 varchar(max)
	declare @tmpSql2 varchar(max)
	declare @curday int
	declare @idx int;
	set @tmpSql1 = 'coalesce (';
	set @tmpSql2 = '';
	set @idx = 0;
	set @curday = @prevDay;
	while( @curday >= @onhandDay)
	begin
		set @idx = @idx + 1;
		set @tmpSql1 = @tmpSql1+'D'+convert(varchar,@idx)+', ';
		set @tmpSql2 = @tmpSql2+',max(case when period_key = '+CONVERT(varchar,@curday)+' then [Store On Hand Volume Units Modeledx] end) d'+convert(varchar,@idx)
		set @curday = convert(int,convert(varchar(20),dateadd(day,0-@idx,convert(date,CONVERT(varchar(20),@prevDay),112)),112));
	end
	set @tmpSql1 = @tmpSql1 + 'null) [Store On Hand Volume Units Modeledx]';
		
	SET @sql = 'INSERT INTO RSI_FACT_PLAN_STAGE with (TABLOCKX)
			(VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, PERIOD_KEY, SUBVENDORID, UNIQUES_TYPE, [Scan Date]
			, [Store On Hand Volume Units Modeledx], [Store Out of Stock Indicator Modeledx]
			, [Last Store On Hand Volume Units Modeledx], [Last Store Out of Stock Indicator Modeledx]
			)
			SELECT VENDOR_KEY,RETAILER_KEY,ITEM_KEY,STORE_KEY,PERIOD_KEY,SUBVENDORID,SUM(UNIQUES_TYPE) UNIQUES_TYPE
			, MAX([Scan Date]) [Scan Date]
			, SUM([Store On Hand Volume Units Modeledx]) [Store On Hand Volume Units Modeledx]
			, SUM([Store Out of Stock Indicator Modeledx]) [Store Out of Stock Indicator Modeledx]
			, SUM([Last Store On Hand Volume Units Modeledx]) [Last Store On Hand Volume Units Modeledx]
			, SUM([Last Store Out of Stock Indicator Modeledx]) [Last Store Out of Stock Indicator Modeledx]
			from (
			SELECT fact.VENDOR_KEY, fact.RETAILER_KEY, fact.ITEM_KEY, fact.STORE_KEY, fact.PERIOD_KEY, fact.SUBVENDORID, UNIQUES_TYPE, [Scan Date]
				, [Store On Hand Volume Units Modeledx]
				, CASE WHEN [Store On Hand Volume Units Modeledx] IS NOT NULL THEN 
						CASE WHEN [Store On Hand Volume Units Modeledx] <= 0 THEN 1 ELSE 0 END 
				  END [Store Out of Stock Indicator Modeledx]
				, [Last Store On Hand Volume Units Modeledx]
				, CASE WHEN [Last Store On Hand Volume Units Modeledx] IS NOT NULL THEN 
						CASE WHEN [Last Store On Hand Volume Units Modeledx] <= 0 THEN 1 ELSE 0 END 
				  END [Last Store Out of Stock Indicator Modeledx]
			FROM (
					SELECT fact.VENDOR_KEY, fact.RETAILER_KEY, fact.ITEM_KEY, fact.STORE_KEY, fact.SubvendorId , fact.PERIOD_KEY
					, CASE WHEN [Store On Hand Volume Units] is null then
						CASE WHEN prev.[Store On Hand Volume Units Modeledx] IS NOT NULL THEN
						prev.[Store On Hand Volume Units Modeledx] - COALESCE([Total Sales Volume Units], 0) + COALESCE([Store Receipts Volume Units], 0)
						END
					  ELSE [Store On Hand Volume Units] END	[Store On Hand Volume Units Modeledx]
					 , prev.[Store On Hand Volume Units Modeledx] [Last Store On Hand Volume Units Modeledx]
					 , (power(2,0)
						+CASE WHEN COALESCE([Total Sales Volume Units],0) <> 0 THEN power(2,1) ELSE 0 END
						+CASE WHEN COALESCE([Store On Hand Volume Units],0) > 0 THEN power(2,2) ELSE 0 END
						+CASE WHEN COALESCE(fact.[Store SKU Tracked Indicator],0)>0  THEN power(2,3) ELSE 0 END
						+CASE WHEN COALESCE(fact.[Store SKU Active Indicator],0)>0  THEN power(2,4) ELSE 0 END
						) UNIQUES_TYPE					
					, CASE WHEN COALESCE([Total Sales Volume Units],0) <> 0  then fact.PERIOD_KEY END [Scan Date]
					from (' + @tables + ') fact 
					LEFT OUTER JOIN (
						select VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SubvendorId  
						, '+ @tmpSql1 +' 
						from (
						select VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SubvendorId '+@tmpSql2+' 
						 from RSI_FACT_PLAN with (nolock) 
						where PERIOD_KEY between ' + CONVERT(VARCHAR, @onHandDay) + ' AND ' + CONVERT(VARCHAR,@prevDay) + ' 
						group by ITEM_KEY, STORE_KEY, VENDOR_KEY, RETAILER_KEY, SubvendorId
						) a1
					) prev on prev.VENDOR_KEY = fact.VENDOR_KEY and prev.RETAILER_KEY = fact.RETAILER_KEY and prev.ITEM_KEY = fact.ITEM_KEY
							and prev.STORE_KEY = fact.STORE_KEY and prev.SubvendorId = fact.SubvendorId 
					WHERE fact.PERIOD_KEY = ' + CONVERT(VARCHAR,@day) + ' 
				) fact 
				UNION ALL 
				select VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, ' + CONVERT(VARCHAR,@day) + ' AS PERIOD_KEY, SUBVENDORID , 
						(UNIQUES_TYPE&31)*power(2,5),NULL,NULL,NULL,NULL,NULL
				FROM (SELECT * FROM RSI_FACT_PLAN UNION ALL SELECT * FROM RSI_FACT_PLAN_PRE) ly 
							WHERE PERIOD_KEY = ' + CONVERT(VARCHAR, @lyDay) +' and (UNIQUES_TYPE & 31) >0 
				UNION ALL
				SELECT VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, ' + CONVERT(VARCHAR, @day) + ' AS PERIOD_KEY, SUBVENDORID, 
							(UNIQUES_TYPE&31)* power(2, 10) UNIQUES_TYPE,NULL,NULL,NULL,NULL,NULL
				FROM (SELECT * FROM RSI_FACT_PLAN UNION ALL SELECT * FROM RSI_FACT_PLAN_PRE) tya
				WHERE PERIOD_KEY = ' + CONVERT(VARCHAR, @tyaDay) + ' and (UNIQUES_TYPE & 31) >0 
				) fact 
				GROUP BY VENDOR_KEY,RETAILER_KEY,ITEM_KEY,STORE_KEY,PERIOD_KEY,SUBVENDORID';

	return @sql;
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn$rsi_plan_sql_wk]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fn$rsi_plan_sql_wk]
GO

CREATE FUNCTION [dbo].[fn$rsi_plan_sql_wk] 
(
	@day INT,
	@onHandDay INT,
	@tables VARCHAR(max)
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @startDay AS INT ;
	DECLARE @endDay AS INT ;
	DECLARE @prevDay AS INT ;
	DECLARE @lyDay AS INT ;
	DECLARE @tyaDay AS INT ;
	
	execute @startDay = [dbo].[fn$rsi_plan_range] @day, 0
	
	execute @endDay = [dbo].[fn$rsi_plan_range] @day, 1
	
	SET @lyDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -364, CONVERT(VARCHAR, @day)), 112)) ;
	SET @tyaDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -728, CONVERT(VARCHAR, @day)), 112)) ;
	SET @prevDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -1, CONVERT(VARCHAR, @day)), 112)) ;
	
	declare @onHandExists tinyint
	set @onHandExists = 0
	IF EXISTS(SELECT TOP 1 PERIOD_KEY FROM [olap].[V$STORE_SALES] fact
					WHERE fact.PERIOD_KEY = CONVERT(VARCHAR, @day) and [Store On Hand Volume Units] IS NOT NULL)
		SET @onHandExists = 1

	DECLARE @sql VARCHAR(max)

	declare @tmpSql1 varchar(max)
	declare @tmpSql2 varchar(max)
	declare @curday int
	declare @idx int;
	set @tmpSql1 = 'coalesce (';
	set @tmpSql2 = '';
	set @idx = 0;
	set @curday = @prevDay;
	while( @curday >= @startDay)
	begin
		set @idx = @idx + 1;
		set @tmpSql1 = @tmpSql1+'D'+convert(varchar,@idx)+', ';
		set @tmpSql2 = @tmpSql2+',max(case when period_key = '+CONVERT(varchar,@curday)+' then [Store On Hand Volume Units Modeledx] end) d'+convert(varchar,@idx)
		set @curday = convert(int,convert(varchar(20),dateadd(day,0-@idx,convert(date,CONVERT(varchar(20),@prevDay),112)),112));
	end
	set @tmpSql1 = @tmpSql1 + 'null) [Store On Hand Volume Units Modeledx]';
		
	SET @sql = 'INSERT INTO RSI_FACT_PLAN_STAGE with (TABLOCKX)
			(VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, PERIOD_KEY, SUBVENDORID, UNIQUES_TYPE, [Scan Date]
				, [Store On Hand Volume Units Modeledx], [Store Out of Stock Indicator Modeledx])
			SELECT fact.VENDOR_KEY, fact.RETAILER_KEY, fact.ITEM_KEY, fact.STORE_KEY, fact.PERIOD_KEY, fact.SUBVENDORID
				, SUM(UNIQUES_TYPE) UNIQUES_TYPE, max([Scan Date]) [Scan Date]
				, SUM([Store On Hand Volume Units Modeledx]) [Store On Hand Volume Units Modeledx]
				, SUM(CASE WHEN [Store On Hand Volume Units Modeledx] IS NOT NULL THEN CASE WHEN [Store On Hand Volume Units Modeledx] <= 0 THEN 1 ELSE 0 END END ) [Store Out of Stock Indicator Modeled]
			FROM (SELECT fact.VENDOR_KEY, fact.RETAILER_KEY, fact.ITEM_KEY, fact.STORE_KEY, fact.SUBVENDORID, fact.PERIOD_KEY, UNIQUES_TYPE, [Scan Date]
					, CASE WHEN [Store On Hand Volume Units] IS NULL THEN
						CASE WHEN prev.[Store On Hand Volume Units Modeledx] IS NOT NULL THEN
							prev.[Store On Hand Volume Units Modeledx] - COALESCE([Total Sales Volume Units SoFar], 0) + COALESCE([Store Receipts Volume Units soFar], 0)
						ELSE NULL END
					 ELSE [Store On Hand Volume Units] END AS [Store On Hand Volume Units Modeledx]
				  FROM (SELECT factwk.VENDOR_KEY, factwk.RETAILER_KEY, factwk.ITEM_KEY, factwk.STORE_KEY, factwk.SubvendorId , ' + CONVERT(VARCHAR,@day) + ' PERIOD_KEY				
							, MAX(CASE WHEN factwk.PERIOD_KEY = ' + CONVERT(VARCHAR,@day) + ' THEN factwk.[Store On Hand Volume Units] END) [Store On Hand Volume Units]
							, SUM(CASE WHEN factwk.PERIOD_KEY = ' + CONVERT(VARCHAR,@day) + ' THEN factwk.[Total Sales Volume Units] end)  [Total Sales Volume Units SoFar]
							, SUM(CASE WHEN factwk.PERIOD_KEY = ' + CONVERT(VARCHAR,@day) + ' THEN factwk.[Store Receipts Volume Units] end)   [Store Receipts Volume Units soFar]
							, MAX(case when factwk.period_key = ' + CONVERT(VARCHAR, @day) + ' THEN
								(power(2,0)
								+CASE WHEN COALESCE([Total Sales Volume Units],0) <> 0 THEN power(2,1) ELSE 0 END
								+CASE WHEN COALESCE([Store On Hand Volume Units],0) > 0 THEN power(2,2) ELSE 0 END
								+CASE WHEN COALESCE(factwk.[Store SKU Tracked Indicator],0)>0  THEN power(2,3) ELSE 0 END
								+CASE WHEN COALESCE(factwk.[Store SKU Active Indicator],0)>0  THEN power(2,4) ELSE 0 END
								)	
								ELSE 1 END) UNIQUES_TYPE	
							, MAX(CASE WHEN factwk.PERIOD_KEY <= ' + CONVERT(VARCHAR,@day) + ' and COALESCE([Total Sales Volume Units],0) <> 0  THEN factwk.PERIOD_KEY END) [Scan Date]				
						FROM (' + @tables + ') factwk 
						where PERIOD_KEY between ' + CONVERT(VARCHAR, @startDay) + ' AND ' + CONVERT(VARCHAR, @endDay) + ' 
						group by factwk.VENDOR_KEY, factwk.RETAILER_KEY, factwk.ITEM_KEY, factwk.STORE_KEY, factwk.SubvendorId
					) fact 
					left outer hash join (
						select VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SubvendorId  
						, '+ @tmpSql1 +' 
						from (
						select VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SubvendorId '+@tmpSql2+' 
						 from RSI_FACT_PLAN with (nolock) 
						where PERIOD_KEY between ' + CONVERT(VARCHAR, @startDay) + ' AND ' + CONVERT(VARCHAR,@prevDay) + ' 
							and UNIQUES_TYPE &1 = 1 
						group by ITEM_KEY, STORE_KEY, VENDOR_KEY, RETAILER_KEY, SubvendorId
						) a1
					) prev on prev.VENDOR_KEY = fact.VENDOR_KEY and prev.RETAILER_KEY = fact.RETAILER_KEY and prev.ITEM_KEY = fact.ITEM_KEY
							and prev.STORE_KEY = fact.STORE_KEY and prev.SubvendorId = fact.SubvendorId 
					UNION ALL 
					SELECT VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SubvendorId , ' + CONVERT(VARCHAR,@day) + ' as period_key, 
							(UNIQUES_TYPE&31)*power(2,5),NULL,NULL 
					FROM (SELECT * FROM rsi_fact_plan UNION ALL SELECT * FROM rsi_fact_plan_pre) ly 
							WHERE PERIOD_KEY = ' + CONVERT(VARCHAR, @lyDay) +' and (UNIQUES_TYPE & 31) >0 
					UNION ALL
					SELECT VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, SUBVENDORID,  ' + CONVERT(VARCHAR, @day) + ' as PERIOD_KEY,
							(UNIQUES_TYPE&31)* power(2, 10),NULL,NULL 
							FROM (SELECT * FROM rsi_fact_plan UNION ALL SELECT * FROM rsi_fact_plan_pre) tya
							WHERE PERIOD_KEY = ' + CONVERT(VARCHAR, @tyaDay) + ' and (UNIQUES_TYPE & 31) >0 
				)fact
				GROUP BY VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, period_key, subvendorid, PERIOD_KEY';
	return @sql;
END

GO

 
