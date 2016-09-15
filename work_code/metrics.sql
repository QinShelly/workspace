/* ------------------------------------------
Metrics Fusion
-- ------------------------------------------*/
select * from RSI_META_MEASURES_CORE_AMOUNTTYPE
where retailer_name = 'TARGET'

select distinct RETAILER_NAME from RSI_META_MEASURES_CORE
where RETAILER_NAME  like 'B%'

select * from RSI_META_MEASURES_description
where measure_name like '%store on hand volume units model%'

select * from RSI_CORE_CFGPROPERTY
where name = 'cube.metrics.retailer'


-- Get Propagate
select * from RSI_META_MEASURES_description
where measure_name like '%Propagate%'

-- Get Modeled
select * from RSI_META_MEASURES_description
where measure_name like 'Store On Hand Volume Units'
and description like '%modeled%'

/* ------------------------------------------
Metrics
-- ------------------------------------------*/
select * from metadata_hub_function_beta.MEASURES_RETAILER
where  measure_name in ('DC On Hand Amount')
and retailer_name in ('savers')

select * from metadata_hub.MEASURES_core
where  measure_name = 'Store Receipts Amount'
and retailer_name in ('savers')

select * from metadata_hub.MEASURES_CORE_AMOUNTTYPE
where  measure_name = 'Store Authorized Date'
and retailer_name in ('savers')

select * from metadata_hub.MEASURES_conversion
where  measure_name = 'DC On Hand Amount'
and retailer_name in ('savers')

select * from metadata_hub.MEASURES_description
where retailer_name like 'l%'
and  measure_name like '%Store Inventory on Requisition volume unit%'

select * from metadata_hub.MEASURES
where measure_name like '%DC On Order Volume Equivalent Units%'

select * from metadata_hub.MEASURES_propagate
where  measure_name = 'Store On Hand Amount'

select * from metadata_hub.MEASURES_core a
inner join metadata_hub.MEASURES_description  b
on a.measure_name = b.MEASURE_NAME
limit 100

SELECT distinct retailer_name FROM metadata_hub.MEASURES_description a
where retailer_name like 'wal%'
and not exists(
SELECT * FROM metadata_hub.MEASURES_description
where retailer_name = 'target category'
and measure_name = a.measure_name
--and description <> a.description
)
SELECT * FROM metadata_hub.MEASURES_description a
where retailer_name = 'target category'
and exists (
SELECT * FROM metadata_hub.MEASURES_description
where retailer_name = 'target'
and measure_name = a.measure_name
and description <> a.description
)