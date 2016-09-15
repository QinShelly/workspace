-- Run this scripts on MR Silo DB
DECLARE 
@period_key_start int = 20160320,
@period_key_end int = 20160514,
@siloId nvarchar(100) = 'NESTLE_FRANCE_RETAILER_OVERVIEW',
@threshold float = 1


IF ((SELECT VALUE FROM RSI_CORE_CFGPROPERTY where NAME='etl.silo.type')<>'MR')
BEGIN
RAISERROR (N'Current Silo is not MR silo.', 20, 1)
return
END
-- Create Table for saving result
IF EXISTS(SELECT OBJECT_ID('Fusion_Recover_MR_DTO','U'))
DROP TABLE Fusion_Recover_MR_DTO;
CREATE TABLE Fusion_Recover_MR_DTO (
silo_id nvarchar(255),
period_key int,
retailer_key int,
vendor_key int,
data_type varchar(20),
MeasureName varchar(50),
MR_Measure_Value numeric(18,4),
SVR_Measure_Value numeric(18,4),
value_diff numeric(18,4),
value_diff_pct numeric(10,4),
tieout char(1) 
)



DECLARE @MRPOSTable nvarchar(100), @MRDCTable nvarchar(100), @svrLinkedSvr nvarchar(250)
DECLARE @hub nvarchar(100)
SELECT @hub =LTRIM(RTRIM(VALUE)) FROM RSI_CORE_CFGPROPERTY where NAME='md.domain.name'

IF OBJECT_ID('tempdb..#customer') IS NOT NULL DROP TABLE #customer
Create Table #customer([SUFFIX] [varchar](20),
	[VENDOR_KEY] [int] ,
	[RETAILER_KEY] [int] ,
	[ENABLED] [char](1),
	[SILO_ID] [varchar](100) ,
	[VENDOR_NAME] [varchar](32) ,
	[RETAILER_NAME] [varchar](32) ,
	[WHSE_RETAILER_KEY] [int],
	[DB_SERVERNAME] varchar(255),
	[DB_NAME] varchar(255)
	)
declare @sql nvarchar(max), @innerSQL nvarchar(max)
set @sql = '
INSERT INTO #customer
select c.[SUFFIX] ,c.[VENDOR_KEY] ,c.[RETAILER_KEY] ,c.[ENABLED] ,c.[SILO_ID] ,c.[VENDOR_NAME]  ,c.[RETAILER_NAME] ,c.[WHSE_RETAILER_KEY] ,silo.[DB_SERVERNAME]  ,silo.[DB_NAME] 
from ['+@siloId + 'HUBLINK].' + @hub + '.dbo.RSI_CONFIG_CUSTOMERS c
join RSI_CONFIG_CUSTOMERS s on c.VENDOR_KEY=s.VENDOR_KEY and c.RETAILER_KEY= s.RETAILER_KEY
and c.SUFFIX = s.SUFFIX and c.SILO_ID<> '''+@siloId + '''
join ['+@siloId + 'HUBLINK].' + @hub + '.dbo.RSI_DIM_SILO silo
on c.SILO_ID = silo.SiloId where c.silo_id not like ''%alert%'''

exec sp_executesql @sql

IF OBJECT_ID('tempdb..#MEASURES') IS NOT NULL DROP TABLE #MEASURES
CREATE TABLE #MEASURES (MEASURE_NAME VARCHAR(100), MEASURE_GROUP VARCHAR(100))

INSERT INTO #MEASURES(MEASURE_NAME, MEASURE_GROUP)
VALUES ('Total sales amount','POS'),
('Total Sales Volume Units','POS'),
('Store On Hand Volume Units','POS'),
('DC On Hand Amount','Whse'),
('DC On Hand Volume Units','Whse'),
('DC Shipment Volume Units','Whse')

--Create Temp table for saving pull data
IF OBJECT_ID('tempdb..#MRPos') IS NOT NULL DROP TABLE #MRPos
Create Table #MRPos(PERIOD_KEY int , RETAILER_KEY int, VENDOR_KEY int, [Total Sales Amount] float,  [Total Sales Volume Units] float ,[Store On Hand Volume Units] float)

IF OBJECT_ID('tempdb..#MRWHSE') IS NOT NULL DROP TABLE #MRWHSE
Create Table #MRWHSE (PERIOD_KEY int , RETAILER_KEY int, VENDOR_KEY int, [DC On Hand Amount] float,  [DC On Hand Volume Units] float, [DC Shipment Volume Units]  float, [DC Receipt Volume Units]  float)

IF OBJECT_ID('tempdb..#SVRPos') IS NOT NULL DROP TABLE #SVRPos
Create Table #SVRPos(PERIOD_KEY int , RETAILER_KEY int, VENDOR_KEY int, [Total Sales Amount] float,  [Total Sales Volume Units] float ,[Store On Hand Volume Units] float)

IF OBJECT_ID('tempdb..#SVRWHSE') IS NOT NULL DROP TABLE #SVRWHSE
Create Table #SVRWHSE (PERIOD_KEY int , RETAILER_KEY int, VENDOR_KEY int, [DC On Hand Amount] float,  [DC On Hand Volume Units] float , [DC Shipment Volume Units]  float, [DC Receipt Volume Units]  float)

--sql vars
DECLARE	@POSSelect varchar(500), @WhseSelect varchar(500), @POSSelectAgg varchar(500), @WhseSelectAgg varchar(500)

-- loop each SVR
DECLARE @Suffix nvarchar(100),@Vendorkey int, @RetailerKey int, @Enabled nvarchar(2), @SvrSiloID nvarchar(100), @VendorName nvarchar(100), @RetailerName nvarchar(100),@WHSERetailerKey int, @svrDBServer nvarchar(255), @svrSiloDB nvarchar(100)
DECLARE cust CURSOR FOR SELECT [SUFFIX],[VENDOR_KEY],[RETAILER_KEY],[ENABLED],[SILO_ID],[VENDOR_NAME],[RETAILER_NAME],[WHSE_RETAILER_KEY],[DB_SERVERNAME],[DB_NAME]  FROM #customer
OPEN cust
FETCH NEXT FROM cust INTO @Suffix,@Vendorkey, @RetailerKey, @Enabled, @SvrSiloID, @VendorName, @RetailerName,@WHSERetailerKey, @svrDBServer, @svrSiloDB
while @@FETCH_STATUS =0 
BEGIN
	--select  @Suffix,@Vendorkey, @RetailerKey, @Enabled, @SvrSiloID, @VendorName, @RetailerName,@WHSERetailerKey, @svrDBServer, @svrSiloDB
	--get SVR existing columns in table
	IF OBJECT_ID('tempdb..#SVR_EXISTING_MEASURES') IS NOT NULL DROP TABLE #SVR_EXISTING_MEASURES
	CREATE TABLE #SVR_EXISTING_MEASURES (MEASURE_NAME VARCHAR(100))

	set @innerSQL = 'SELECT DISTINCT name MEASURE_NAME
	FROM '+ @svrSiloDB +'.sys.columns c
	where c.object_id in (
		select object_id from '+ @svrSiloDB +'.sys.tables
		where name = ''''RSI_FACT_PIVOT_'+ @Suffix +'''''
		or name = ''''RSI_FACT_PIVOT_'+ @Suffix +'_WHSE''''
	)
	'
	set @sql = 'INSERT INTO #SVR_EXISTING_MEASURES (MEASURE_NAME)
	SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server='+ @svrDBServer +';Trusted_Connection=yes;'',''' + @innerSQL +''')'

	print @sql

	exec sp_executesql @sql

	select @POSSelect = STUFF((SELECT ',[' + a.MEASURE_NAME + ']' from #MEASURES a
	INNER JOIN #SVR_EXISTING_MEASURES b
	on a.MEASURE_NAME = b.MEASURE_NAME
	where MEASURE_GROUP = 'POS'
	FOR XML PATH('')),1,1,'')

	select @POSSelectAgg = STUFF((SELECT ',SUM([' + a.MEASURE_NAME + '])' from #MEASURES a
	INNER JOIN #SVR_EXISTING_MEASURES b
	on a.MEASURE_NAME = b.MEASURE_NAME
	where MEASURE_GROUP = 'POS'
	FOR XML PATH('')),1,1,'')

	select @WhseSelect = STUFF((SELECT ',[' + a.MEASURE_NAME + ']' from #MEASURES a
	INNER JOIN #SVR_EXISTING_MEASURES b
	on a.MEASURE_NAME = b.MEASURE_NAME
	where MEASURE_GROUP = 'Whse'
	FOR XML PATH('')),1,1,'')

	select @WhseSelectAgg = STUFF((SELECT ',SUM([' + a.MEASURE_NAME + '])' from #MEASURES a
	INNER JOIN #SVR_EXISTING_MEASURES b
	on a.MEASURE_NAME = b.MEASURE_NAME
	where MEASURE_GROUP = 'Whse'
	FOR XML PATH('')),1,1,'')
	
	print @POSSelect
	print @WhseSelect
	print @POSSelectAgg
	print @WhseSelectAgg

	print @Suffix
	-- aggregate MR Store Data
	set @sql =N'INSERT INTO #MRPos (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, ' + @POSSelect +')
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @POSSelectAgg +'
	FROM RSI_MR_FACT_PIVOT_' + @Suffix +' WHERE RETAILER_KEY =' + convert(nvarchar, @RetailerKey)+ ' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'

	exec sp_executesql @sql

	-- aggregate MR WHSE Data
	set @sql =N'INSERT INTO #MRWHSE (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @WhseSelect +' )
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @WhseSelectAgg +'
	FROM RSI_MR_FACT_PIVOT_' + @Suffix +'_WHSE WHERE RETAILER_KEY=' + CONVERT(nvarchar, @WHSERetailerKey) +' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'
	print @sql
	exec sp_executesql @sql

	-- aggregate SVR Store Data
	
	set @innerSQL = 'SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @POSSelectAgg +'
	FROM ' + @svrSiloDB +'.dbo.RSI_FACT_PIVOT_' + @Suffix +' WHERE RETAILER_KEY =' + convert(nvarchar, @RetailerKey)+ ' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'
	set @sql = 'INSERT INTO #SVRPos (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @POSSelect +')
	SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server='+ @svrDBServer +';Trusted_Connection=yes;'',''' + @innerSQL +''')'
	
	print @sql
	exec sp_executesql @sql

	-- aggregate SVR WHSE Data
	
	set @innerSQL = 'SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @WhseSelectAgg +'
	FROM ' + @svrSiloDB +'.dbo.RSI_FACT_PIVOT_' + @Suffix +'_WHSE WHERE RETAILER_KEY =' + convert(nvarchar, @WHSERetailerKey)+ ' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'
	set @sql = 'INSERT INTO #SVRWHSE (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, '+ @WhseSelect +')
	SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server='+ @svrDBServer +';Trusted_Connection=yes;'',''' + @innerSQL +''')'
	
	print @sql
	exec sp_executesql @sql

	FETCH NEXT FROM cust INTO @Suffix,@Vendorkey, @RetailerKey, @Enabled, @SvrSiloID, @VendorName, @RetailerName,@WHSERetailerKey, @svrDBServer, @svrSiloDB
END
CLOSE cust;
DEALLOCATE cust;


--BFW 
select @Suffix=null, @Vendorkey=null,@retailerkey=null,@WHSERetailerKey=null
DECLARE  curKeys cursor for
SELECT SUFFIX, VENDOR_KEY,RETAILER_KEY,WHSE_RETAILER_KEY  FROM RSI_CONFIG_CUSTOMERS WHERE RETAILER_NAME IN (SELECT RETAILER_NAME FROM [dbo].[fn$rsi_mr_get_bfw_retailers]())
OPEN curKeys
FETCH NEXT FROM curKeys into @Suffix, @Vendorkey,@retailerkey,@WHSERetailerKey
WHILE @@FETCH_STATUS = 0 
BEGIN
		-- aggregate MR Store Data
	set @sql =N'INSERT INTO #MRPos (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, [Total Sales Amount],  [Total Sales Volume Units])
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, sum([Total Sales Amount]),  sum([Total Sales Volume Units])
	FROM RSI_MR_FACT_PIVOT_' + @Suffix +'_BFW WHERE RETAILER_KEY =' + convert(nvarchar, @RetailerKey)+ ' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'

	exec sp_executesql @sql

	-- aggregate MR WHSE Data
	set @sql =N'INSERT INTO #MRWHSE (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, [DC Shipment Volume Units] ,  [DC Receipt Volume Units] )
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, sum([DC Shipment Volume Units]),  sum([DC Receipt Volume Units])
	FROM RSI_MR_FACT_PIVOT_' + @Suffix +'_WHSE_BFW WHERE RETAILER_KEY=' + CONVERT(nvarchar, @WHSERetailerKey) +' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'
	print @sql
	exec sp_executesql @sql
	
	--summary data
-- aggregate MR Store Data
	set @sql =N'INSERT INTO #SVRPos (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, [Total Sales Amount],  [Total Sales Volume Units])
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, SUM(POSSales),  SUM(POSQty)
	FROM RSI_MR_FACT_SUMMARY WHERE RETAILER_KEY =' + convert(nvarchar, @RetailerKey)+ ' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'

	exec sp_executesql @sql

	-- aggregate MR WHSE Data
	set @sql =N'INSERT INTO #SVRWHSE (PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, [DC Shipment Volume Units] ,  [DC Receipt Volume Units] )
	SELECT PERIOD_KEY, RETAILER_KEY, VENDOR_KEY, SUM(WhseShipsQty), SUM(WhseReceivedQty)
	FROM RSI_MR_FACT_WHSE_SUMMARY WHERE RETAILER_KEY=' + CONVERT(nvarchar, @WHSERetailerKey) +' AND PERIOD_KEY >= ' + convert(nvarchar(8),@period_key_start) + ' AND PERIOD_KEY <=' + convert(nvarchar(8),@period_key_end) +'
	GROUP BY PERIOD_KEY, RETAILER_KEY, VENDOR_KEY'
	--print @sql
	exec sp_executesql @sql

	
FETCH NEXT FROM curKeys into @Suffix, @Vendorkey,@retailerkey,@WHSERetailerKey
END
CLOSE curKeys;
DEALLOCATE curKeys;


--SELECT * FROM #MRPos
--SELECT * FROM #MRWHSE
--SELECT * FROM #SVRPos
--SELECT * FROM #SVRWHSE

INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'STORE SALES' data_type, 'Total Sales Amount' MeasureName, mr.[Total Sales Amount] MR_Measure_Value,svr.[Total Sales Amount] SVR_Measure_Value,
svr.[Total Sales Amount]-mr.[Total Sales Amount] as value_diff
,case when svr.[Total Sales Amount]<>0.0 then(mr.[Total Sales Amount]-svr.[Total Sales Amount])/svr.[Total Sales Amount] end as value_diff_pct
from #MRPos mr
Full Outer join #SVRPos svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare


INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'STORE SALES' data_type, 'Total Sales Volume Units' MeasureName, mr.[Total Sales Volume Units] MR_Measure_Value,svr.[Total Sales Volume Units] SVR_Measure_Value,
svr.[Total Sales Volume Units]-mr.[Total Sales Volume Units] as value_diff
,case when svr.[Total Sales Volume Units]<>0.0 then(mr.[Total Sales Volume Units]-svr.[Total Sales Volume Units])/svr.[Total Sales Volume Units] end as value_diff_pct
from #MRPos mr
Full Outer join #SVRPos svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare

INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'STORE SALES' data_type, 'Store On Hand Volume Units' MeasureName, mr.[Store On Hand Volume Units] MR_Measure_Value,svr.[Store On Hand Volume Units] SVR_Measure_Value,
svr.[Store On Hand Volume Units]-mr.[Store On Hand Volume Units] as value_diff
,case when svr.[Store On Hand Volume Units]<>0.0 then(mr.[Store On Hand Volume Units]-svr.[Store On Hand Volume Units])/svr.[Store On Hand Volume Units] end as value_diff_pct
from #MRPos mr
Full Outer join #SVRPos svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare

INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'DC' data_type, 'DC On Hand Amount' MeasureName, mr.[DC On Hand Amount] MR_Measure_Value,svr.[DC On Hand Amount] SVR_Measure_Value,
svr.[DC On Hand Amount]-mr.[DC On Hand Amount] as value_diff
,case when svr.[DC On Hand Amount]<>0.0 then(mr.[DC On Hand Amount]-svr.[DC On Hand Amount])/svr.[DC On Hand Amount] end as value_diff_pct
from #MRWHSE mr
Full Outer join #SVRWHSE svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare


INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'DC' data_type, 'DC On Hand Volume Units' MeasureName, mr.[DC On Hand Volume Units] MR_Measure_Value,svr.[DC On Hand Volume Units] SVR_Measure_Value,
svr.[DC On Hand Volume Units]-mr.[DC On Hand Volume Units] as value_diff
,case when svr.[DC On Hand Volume Units]<>0.0 then(mr.[DC On Hand Volume Units]-svr.[DC On Hand Volume Units])/svr.[DC On Hand Volume Units] end as value_diff_pct
from #MRWHSE mr
Full Outer join #SVRWHSE svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare

-- for BFW
INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,
coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'DC' data_type, 'DC Shipment Volume Units' MeasureName, mr.[DC Shipment Volume Units] MR_Measure_Value,svr.[DC Shipment Volume Units] SVR_Measure_Value,
svr.[DC Shipment Volume Units]-mr.[DC Shipment Volume Units] as value_diff
,case when svr.[DC Shipment Volume Units]<>0.0 then(mr.[DC Shipment Volume Units]-svr.[DC Shipment Volume Units])/svr.[DC Shipment Volume Units] end as value_diff_pct
from #MRWHSE mr
Full Outer join #SVRWHSE svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare


INSERT INTO Fusion_Recover_MR_DTO
(silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct,tieout)
SELECT silo_id ,period_key,retailer_key,vendor_key,data_type,MeasureName
,MR_Measure_Value,SVR_Measure_Value,value_diff,value_diff_pct
, CASE WHEN  coalesce(MR_Measure_Value,0)=coalesce(SVR_Measure_Value,0) THEN 'T' ELSE CASE WHEN value_diff_pct IS NOT NULL and value_diff_pct<=(@threshold/100) THEN 'T' ELSE 'F' END END  tieout
from 
(SELECT @siloId as silo_id ,coalesce(mr.period_key,svr.period_key) period_key,coalesce(mr.retailer_key,svr.retailer_key) retailer_key
,coalesce(mr.vendor_key ,svr.vendor_key) vendor_key,'DC' data_type, 'DC Receipt Volume Units' MeasureName, mr.[DC Receipt Volume Units] MR_Measure_Value,svr.[DC Receipt Volume Units] SVR_Measure_Value,
svr.[DC Receipt Volume Units]-mr.[DC Receipt Volume Units] as value_diff
,case when svr.[DC Receipt Volume Units]<>0.0 then(mr.[DC Receipt Volume Units]-svr.[DC Receipt Volume Units])/svr.[DC Receipt Volume Units] end as value_diff_pct
from #MRWHSE mr
Full Outer join #SVRWHSE svr
on mr.RETAILER_KEY=svr.RETAILER_KEY and mr.VENDOR_KEY=svr.VENDOR_KEY and mr.PERIOD_KEY=svr.PERIOD_KEY
) compare


-- Query Result
SELECT c.RETAILER_NAME,c.VENDOR_NAME,dto.* FROM Fusion_Recover_MR_DTO dto 
join
RSI_CONFIG_CUSTOMERS c
on dto.retailer_key=c.RETAILER_KEY and dto.vendor_key= c.VENDOR_KEY
 --WHERE tieout='F'
order by period_key,c.RETAILER_NAME,measureName

--select * from #customer