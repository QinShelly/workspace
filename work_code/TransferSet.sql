
/* ------------------------------------------
ETL Transfer SET
-- ------------------------------------------*/
--Clean tranfer metadata on Hub
 truncate table  etl.RSI_TRANSFER_SET
 truncate table  etl.RSI_TRANSFER_DETAIL
 truncate table  etl.RSI_TRANSFER_FACT_DAILY

--Clean rsi_log on silo
truncate table rsi_log

--clean up transfer details and fact daily
delete from etl.RSI_TRANSFER_DETAIL
where transfer_detail_key   =2

delete from etl.RSI_TRANSFER_FACT_DAILY
where NOT ( period_key between 20151019 and 20151027)
delete from etl.RSI_TRANSFER_DETAIL where transfer_detail_key not in(
SELECT transfer_detail_key FROM etl.RSI_TRANSFER_FACT_DAILY )

update etl.RSI_TRANSFER_SET set current_flag = 'T'
,transfer_set_status = 'READY'
where transfer_set_key = 1
update etl.RSI_TRANSFER_DETAIL set transfer_detail_status = 'READY'
update etl.RSI_TRANSFER_FACT_DAILY set transfer_daily_status = 'READY'

select * from etl.RSI_TRANSFER_SET
select * from etl.RSI_TRANSFER_DETAIL
select * from etl.RSI_TRANSFER_FACT_DAILY

-- 3 tables join
select top 190 * from  etl.RSI_TRANSFER_SET ts WITH( NOLOCK)
inner join    etl.RSI_TRANSFER_DETAIL td  WITH(NOLOCK )
on td.transfer_set_key = ts.transfer_set_key
left join etl.rsi_transfer_fact_daily daily with(nolock )
on td.transfer_detail_key = daily.transfer_detail_key
where silo_id = ''
order by 1 desc

--a view for transfer set and transfer detail
select min_period_key, transfer_detail_status,dim_name , ISNULL ( number_of_rows,
 (select top 1 transferred_rows from etl. RSI_TRANSFER_FACT_DAILY where transfer_detail_key = a. transfer_detail_key) ) Transferred_Rows
,*
from etl.v$rsi_transfer_detail_status a
order by transfer_detail_key

SELECT silo_id , status_name , MIN (create_date) as min_create_date,
MAX(create_date ) as max_create_date, COUNT( dsm_trans_hdr_key) as count_transfers
FROM [GAHUB] .[etl]. [V$RSI_TRANSFER_SET_STATUS]
where current_flag = 'F'
and status_name = 'LOADED'
group by silo_id, status_name

--Transfer set for FACT
select top 20000 ts.transfer_set_key , ts.transfer_set_status,ts.current_flag, ts.transfer_set_start ,ts.transfer_set_end,
detail.transfer_detail_key,detail.dsm_trans_detail_key,detail.operation_type ,detail.transfer_detail_status, detail.min_period_key,
detail.max_period_key,detail.dim_name,detail.retailer_key,detail.vendor_key,
daily.created_by , detail.reference_type,daily.transfer_daily_start,
daily.transfer_daily_end, daily.period_key,daily.pivot_start,daily.pivot_end,daily.plan_start,daily.plan_end,daily.purge_start,daily.purge_end
from etl.RSI_TRANSFER_set ts
inner join etl.RSI_TRANSFER_DETAIL detail on detail.transfer_set_key = ts.transfer_set_key 
left join  etl.RSI_TRANSFER_FACT_DAILY daily on daily.transfer_detail_key = detail.transfer_detail_key
where ts.silo_id = 'SUN_PRODUCTS_TARGET_CATEGORY'
and reference_type = 'FACT'
and transfer_set_status not in ( 'COMPLETE', 'RECOVERED')
order by ts.transfer_set_key  desc

-- transfer set for Dim
select ts . silo_id, ts .transfer_set_key , ts. transfer_set_status ,ts .current_flag, ts.transfer_set_start ,ts. transfer_set_end,
detail.operation_type ,detail. transfer_detail_status,detail .min_period_key, detail.max_period_key ,
 detail .reference_type , detail. dim_name,detail .owner_key ,detail. retailer_key ,detail .vendor_key
 from etl .RSI_TRANSFER_DETAIL detail
 inner join etl . RSI_TRANSFER_set ts on detail . transfer_set_key = ts.transfer_set_key
 where reference_type  = 'DIM'
 

--Recovery TS to start from PIVOT
UPDATE TD
SET TD.transfer_detail_status = 'TRANSFERRED'
FROM etl.RSI_TRANSFER_SET TS
JOIN ETL.RSI_TRANSFER_DETAIL  TD
ON TS.transfer_set_key = TD.transfer_set_key
JOIN ETL.RSI_TRANSFER_FACT_DAILY TFD
ON TD.transfer_detail_key = TFD.transfer_detail_key
where silo_id = '$SILO_ID'
--AND TS.transfer_set_key in ()


/* ------------------------------------------
CTE find last recovered TS
-- ------------------------------------------*/
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
