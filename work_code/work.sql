@@ -0,0 +1,174 @@
/* ------------------------------------------
Hub
-- ------------------------------------------*/
--Get latest installed/upgraded silo info
select * from (
select
a.HUB_NAME ,a. SiloId,a .BUILD_NUMBER, a.Type ,b. EVENT_TS,b .ACTION, b.STATUS ,b. TARGET_BUILD_NUMBER,b .SERVER_NAME
,row_number() over( partition by a.HUB_NAME, a.SiloId ,a. BUILD_NUMBER,a .UpdateDate order by event_ts desc) rk
from
(select 'GAHUB' HUB_NAME,SiloId, BUILD_NUMBER,UpdateDate ,Type, DB_SERVERNAME
from GAHUB.. RSI_DIM_SILO
union all
select 'CNHUB' HUB_NAME,SiloId, BUILD_NUMBER,UpdateDate ,Type, DB_SERVERNAME
from CNHUB.. RSI_DIM_SILO
union all
select 'EUROHUB' HUB_NAME,SiloId, BUILD_NUMBER,UpdateDate ,Type, DB_SERVERNAME
from EUROHUB.. RSI_DIM_SILO
union all
select 'PILOTHUB' HUB_NAME,SiloId, BUILD_NUMBER,UpdateDate ,Type, DB_SERVERNAME
from PILOTHUB.. RSI_DIM_SILO
) a
left join Fathom_CP..RSI_DEPLOY_EVENTS b
on a. SiloId=b .SILO_ID
and a. HUB_NAME=b .HUB_ID
and b. ACTION in ('UPGRADE' ,'install')
) a
where 1= 1
and rk= 1
--and a.Type='A'
order by EVENT_TS desc

/* ------------------------------------------
Dimension Fusion
-- ------------------------------------------*/
SELECT  *
FROM [dbo].[RSI_DIM_PRODUCTS]
where item_key = 1584870
and ATTRIBNAME = 'DHZ_SUPER_CATEGORY'

/* ------------------------------------------
Dimension Nextgen
-- ------------------------------------------*/
select * from dim_hub.vendor
where vendor_name like '%lor%'

select * from dim_hub.retailer
where retailer_name like '%plan%'

select * from dim_hub.subvendor
where retailer_key = 5067

select * from dim_hub.store
where retailer_key = 5067

select * from dim_hub.DC_STORE_PRODUCT limit 10

/* ------------------------------------------
FACT Fusion
-- ------------------------------------------*/
select top 100 * from dbo.RSI_FACT_JNJTARGET
where AMOUNTTYPE_KEY = 1
and PERIOD_KEY < 20160401

/* ------------------------------------------
FACT Nextgen
-- ------------------------------------------*/
truncate table Ahold_RSC.DCPD_FACT ;
truncate table Ahold_RSC.DCPD_FACT_PIVOT_Stage ;
truncate table Ahold_RSC.SPD_FACT ;
truncate table Ahold_RSC.DCPD_FACT_PIVOT_Stage ;

SELECT * FROM Ahold_RSC.DCPD_FACT limit 100;
SELECT * FROM Ahold_RSC.DCPD_FACT_PIVOT_STAGE limit 100;
SELECT * FROM Ahold_RSC.DCPD_FACT_PIVOT limit 100;

SELECT * FROM Ahold_RSC.SPD_FACT limit 100
SELECT * FROM Ahold_RSC.SPD_FACT_PIVOT_STAGE limit 100
SELECT * FROM Ahold_RSC.SPD_FACT_PIVOT limit 100

/* ------------------------------------------
Event Framework
-- ------------------------------------------*/
--Events are inserted to below table at first
select * from dbo.RSI_CORE_EVENTS

--Get event type and corresponding handling job
SELECT distinct elist.event_type ,event_desc, sub.subscriber_job
FROM dbo.RSI_CORE_EVENT_SUBSCRIBERLIST subevts
inner join RSI_CORE_EVENTLIST elist
on elist.EVENT_TYPE = subevts .EVENT_TYPE -- and elist.GROUP_EVENTS = 0
join dbo.RSI_CORE_SUBSCRIBERLIST sub
on sub.SUBSCRIBER_ID = subevts .SUBSCRIBER_ID
order by elist.EVENT_TYPE

--after Event Manager run, rows are inserted to below table
select * from dbo.RSI_CORE_EVENT_SUBSCRIBER

/* ------------------------------------------
OLAP -- Fusion
-- ------------------------------------------*/
select * from RSI_OLAP_PROCESS
order by 1 desc

/* ------------------------------------------
Paritition -- Fusion
-- ------------------------------------------*/
select convert(datetime, convert(varchar, value), 112)
from sys.partition_range_values pr
where function_id in (select function_id from sys.partition_functions
                      where name = 'F$RSI_CORE_POSRANGEPF')
and $partition.F$RSI_CORE_POSRANGEPF(convert(int, value)) = (
    select min(partition_number)
    from sys.partitions
     where object_id IN (select object_id
                         from sys.objects
                         where name in ('RSI_FACT_KMCLRKSAFWAY')
                        and type = 'U' and schema_id = SCHEMA_ID('dbo'))
     and rows > 0 )

--breakdown partition query
select convert(datetime, convert(varchar, value), 112) ,*
from sys.partition_range_values pr
where function_id in (65539) -- <functionid>
and $partition.F$RSI_CORE_POSRANGEPF(convert(int, pr.value)) = 330 -- <partion_number>

select object_id
from sys.objects
where name in ('RSI_FACT_KMCLRKSAFWAY') --<table_name>
and type = 'U' and schema_id = SCHEMA_ID('dbo')
--1933249942

select min(partition_number) as partition_number
from sys.partitions
where object_id IN (1933249942)
and rows>0
--330

--<functionid>
select function_id from sys.partition_functions
where name = 'F$RSI_CORE_POSRANGEPF'
--65539

/* ------------------------------------------
MR
-- ------------------------------------------*/
--get silo mapping
SELECT sm.mapped_silo_id, sm.vendor_key, sm.retailer_key, cc.whse_retailer_key AS dc_retailer_key
, cc.retailer_name
  FROM metadata_$($hubname).silo_mapping sm
  JOIN metadata_$($hubname).config_customers cc
    ON cc.silo_id = sm.mapped_silo_id
 WHERE sm.silo_id = '$siloID'
UNION
SELECT su.silo_id, su.vendor_key, r.retailer_key, su.whse_retailer_key, su.retailer_name
  FROM dim_$($hubname).retailer r
  JOIN metadata_$($hubname).config_customers su
    ON su.retailer_key = r.retailer_key
 WHERE su.silo_id = '$siloID'
   AND r.retailer_sname IN ($bfwRetailers)

/* ------------------------------------------
CTE find last recovered TS for any TS
--------------------------------------------*/
WITH cte AS( 
SELECT old_transfer_set_key, new_transfer_set_key, 1 AS lev 
  FROM hub_function_beta.etl.rsi_transfer_set_recovery 
 WHERE old_transfer_set_key = '63128' 
UNION ALL 
SELECT r.old_transfer_set_key, r.new_transfer_set_key, cte.lev + 1 
  FROM hub_function_beta.etl.rsi_transfer_set_recovery r, cte 
 WHERE cte.new_transfer_set_key = r.old_transfer_set_key 
) 
SELECT * FROM cte 
 WHERE lev = (SELECT MAX(lev) FROM cte
