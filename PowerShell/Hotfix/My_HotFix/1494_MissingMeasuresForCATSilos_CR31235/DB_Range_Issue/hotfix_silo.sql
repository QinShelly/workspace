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
	
	SET @startDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -28, CONVERT(VARCHAR, @day)), 112)) ;
	SET @endDay =  @day
	SET @prevDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -1, CONVERT(VARCHAR, @day)), 112)) ;

	SET @lyDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -364, CONVERT(VARCHAR, @day)), 112)) ;
	SET @tyaDay = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, -728, CONVERT(VARCHAR, @day)), 112)) ;	
	
	declare @sql varchar(max)
	
	declare @onHandExists tinyint
	set @onHandExists = 0
	if exists(select top 1 period_key from [olap].[V$STORE_SALES] fact
					where fact.PERIOD_KEY = CONVERT(VARCHAR, @day) and [Store On Hand Volume Units] is not null)
		set @onHandExists = 1	
		
	SET @sql = 'INSERT INTO RSI_FACT_PLAN_STAGE with (TABLOCKX) 
				(VENDOR_KEY, RETAILER_KEY, ITEM_KEY, STORE_KEY, PERIOD_KEY, SUBVENDORID, OOS_TYPE, UNIQUES_TYPE, [SCAN DATE], [Store On Hand Volume Units Modeledx], [Ranged Indicator], [Store Out of Stock Indicator Modeledx])
				SELECT 
				
				a.VENDOR_KEY, a.RETAILER_KEY, a.ITEM_KEY, a.STORE_KEY, a.PERIOD_KEY, a.SUBVENDORID, a.OOS_TYPE, a.UNIQUES_TYPE, a.[SCAN DATE], a.[Store On Hand Volume Units Modeledx], a.[Ranged Indicator], 
				, case when [Store On Hand Volume Units Modeledx] is not null 
					then 
						case when [Store On Hand Volume Units Modeledx] <= 0 then 1 else 0 end 
					end [Store Out of Stock Indicator Modeled]
				FROM (
				SELECT fact.vendor_key, fact.retailer_key, fact.ITEM_KEY, fact.STORE_KEY, fact.PERIOD_KEY
				, fact.SUBVENDORID
				, case when fact.OOS_TYPE is null and ' + convert(varchar, @onHandExists) +'=0 then coalesce(ABS(pln.OOS_TYPE),0) when fact.OOS_TYPE is null and ' + convert(varchar, @onHandExists) +'=1 then 0 else ABS(fact.OOS_TYPE) end OOS_TYPE
				, fact.UNIQUES_TYPE, fact.[Scan Date]
				, case when [Store On Hand Volume Units] is not null
				  then 
					[Store On Hand Volume Units]
				   else
						case when pln.[Store On Hand Volume Units Modeledx] is not null and ' + convert(varchar, @onHandExists) +'=0
						then
							pln.[Store On Hand Volume Units Modeledx]
							- coalesce([Total Sales Volume Units], 0)
							+ coalesce([Store Receipts Volume Units], 0) 
						else
							null
						end
				   end [Store On Hand Volume Units Modeledx]
				, fact.[Ranged Indicator] 				
				FROM (
				select  vendor_key, retailer_key, ITEM_KEY, STORE_KEY, period_key, subvendorid, sum(oos_type) oos_type, sum(UNIQUES_TYPE) UNIQUES_TYPE, max([Scan Date]) [Scan Date]
				, sum([Store On Hand Volume Units]) [Store On Hand Volume Units]
				, sum([Total Sales Volume Units]) [Total Sales Volume Units]
				, sum([Store Receipts Volume Units]) [Store Receipts Volume Units]
				, MAX([Ranged Indicator]) [Ranged Indicator]
				FROM (
					select fact.vendor_key, fact.retailer_key, fact.ITEM_KEY, fact.STORE_KEY, ' + CONVERT(VARCHAR, @day) + ' PERIOD_KEY, fact.SUBVENDORID
					, (max(CASE WHEN PERIOD_KEY = ' + CONVERT(VARCHAR, @day) + '
						THEN
							CASE WHEN [Store On Hand Volume Units] is NULL and [Total Sales Volume Units] is NULL THEN 0
                                 WHEN coalesce([Store On Hand Volume Units],0) <= 0 and coalesce( [Total Sales Volume Units],0) = 0 THEN 1 
                                 WHEN coalesce( [Store On Hand Volume Units],0) <= 0 and coalesce( [Total Sales Volume Units],0) > 0 THEN 2
                                 WHEN coalesce( [Store On Hand Volume Units], 0) > 0 and coalesce( [Total Sales Volume Units],0) = 0 THEN 4								 
	         				ELSE 0 END
	         			ELSE
	         				null
	         			END	)) OOS_TYPE
					, max(case when period_key = ' + CONVERT(VARCHAR, @day) + '
						THEN
							(	power(2,0) 
						+ CASE WHEN COALESCE([Total Sales Volume Units],0) <> 0 THEN power(2,1) ELSE 0 END
						+ CASE WHEN COALESCE([Store On Hand Volume Units],0) > 0 THEN power(2,2) ELSE 0 END 						
						+ CASE WHEN COALESCE([Ranged Indicator Internal],0) > 0 THEN power(2,3) ELSE 0 END  
						)
						ELSE
							1
						END
					) UNIQUES_TYPE
					, max(case when fact.period_key = ' + CONVERT(VARCHAR, @day) + ' 
						THEN
							CASE WHEN [Total Sales Volume Units] IS NOT NULL THEN fact.PERIOD_KEY END
						ELSE
							NULL
						END) [Scan Date]
					, max(case when fact.period_key = ' + CONVERT(VARCHAR, @day) + ' then [Store On Hand Volume Units] else null end) [Store On Hand Volume Units]
					, max(case when fact.period_key = ' + CONVERT(VARCHAR, @day) + ' then [Total Sales Volume Units] else null end) [Total Sales Volume Units]
					, max(case when fact.period_key = ' + CONVERT(VARCHAR, @day) + ' then [Store Receipts Volume Units] else null end) [Store Receipts Volume Units]
					, max(case when fact.PERIOD_KEY = ' + CONVERT(VARCHAR, @day) + ' then [Ranged Indicator Internal] else null end) [Ranged Indicator]
					from 
					(select distinct STORE_KEY from ('+ @tables +' ) tt where PERIOD_KEY = '+CONVERT(VARCHAR, @day)+') x  
					inner hash join
					(select * from  (' + @tables + ') fact  where PERIOD_KEY between ' + CONVERT(VARCHAR, @startDay) + ' and ' + CONVERT(VARCHAR, @day) + ') fact on fact.STORE_KEY=x.STORE_KEY
					group by fact.vendor_key, fact.retailer_key, fact.ITEM_KEY, fact.STORE_KEY, fact.SUBVENDORID 
					having coalesce(sum([Total Sales Volume Units]),0) > 0
					union all
					select vendor_key, retailer_key, ITEM_KEY, STORE_KEY, ' + CONVERT(VARCHAR, @day) + ' PERIOD_KEY, SUBVENDORID, '
					+' (OOS_TYPE & 7 ) * power(2, 3) OOS_TYPE,'
					+' (UNIQUES_TYPE & 7) * power(2, 3) UNIQUES_TYPE
					, null [Scan Date]	
					, null, null, null, null
					from (select * from rsi_fact_plan union all select * from rsi_fact_plan_pre) ly 
					where PERIOD_KEY = ' + CONVERT(VARCHAR, @lyDay)
					+' union all
					select vendor_key, retailer_key, ITEM_KEY, STORE_KEY, ' + CONVERT(VARCHAR, @day) + ' PERIOD_KEY, SUBVENDORID, '
					+'null OOS_TYPE,'
					+' (UNIQUES_TYPE & 7) * power(2, 6) UNIQUES_TYPE
					, null [Scan Date]
					, null, null, null, null				
					from (select * from rsi_fact_plan union all select * from rsi_fact_plan_pre) tya
					where PERIOD_KEY = ' + CONVERT(VARCHAR, @tyaDay)				
					+') fact
					group by vendor_key, retailer_key, ITEM_KEY, STORE_KEY, period_key, subvendorid
				) fact
				left outer join dbo.RSI_FACT_PLAN pln on pln.vendor_key = fact.vendor_key and pln.retailer_key = fact.retailer_key 
				and pln.item_key = fact.item_key and pln.store_key = fact.store_key and pln.SUBVENDORID = fact.SUBVENDORID
				and pln.period_key = ' + CONVERT(VARCHAR, @prevDay) + ') a';		
	return @sql;
	
	
END

GO