
--Default pool as big_user
set resource_pool = ETL_user

--Created temp table
create local temp table test_memory on commit preserve rows as
select  * from Unilever_CRV_Performance.SPD_FACT_PIVOT limit 0

--checked memory borrowed
select general_memory_borrowed_kb--,* 
from resource_pool_status where pool_name = 'etl_user' 
/*
50826310
50826312
50623302
*/

-- Added 1 months data
insert into test_memory
select * from Unilever_CRV_Performance.SPD_FACT_PIVOT
where period_key between 20150101 and 20150131 -- 26488940

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1
/*
77905624
77905624
80563929
*/

-- Added 1 months data
insert into test_memory
select * from Unilever_CRV_Performance.SPD_FACT_PIVOT
where period_key between 20150201 and 20150230 -- 21014154

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1 
/*
24424429
25753582
25753582
*/

-- Added 1 months data
insert into test_memory
select * from Unilever_CRV_Performance.SPD_FACT_PIVOT
where period_key between 20150301 and 20150330 -- 30750499

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1 
/*
59725976
62384281
64260203
*/

-- Added 1 months data
insert into test_memory
select * from Unilever_CRV_Performance.SPD_FACT_PIVOT
where period_key between 20150401 and 20150430 -- 31710217

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1 
/*
1994144
1994144
2198944
*/

-- Added 1 months data
insert into test_memory
select * from Unilever_CRV_Performance.SPD_FACT_PIVOT
where period_key between 20150501 and 20150530 -- 28313915

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1 -- 43452859, 43452859, 43393733
/*
3988288
3988288
3988289
*/

COMMIT

--checked memory borrowed
select general_memory_borrowed_kb from resource_pool_status where pool_name = 'etl_user' order by 1 -- 43452859, 43452859, 43393733
/*
3988288
3988288
9494964
*/
