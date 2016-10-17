/* ------------------------------------------
Retailer / Vendor SQL Server
-- ------------------------------------------*/
select * from RSI_DIM_RETAILER
where RETAILER_NAME like 'b%'

select * from rsi_dim_vendor
where VENDOR_NAME like 'j%'

select * from rsi_config_customers

/* ------------------------------------------
Configurations
-- ------------------------------------------*/
--Hub Vertica
update metadata_hub.silo_config
set Value = 1
where Name = 'etl.transferset.transfernum'
and silo_id = 'ahold_rsc'

--Hub SQL Server
-- Concurrent config on Hub
select * from RSI_CORE_CFGPROPERTY
where Name like '%etl.concurrent.threshold%'

update RSI_CORE_CFGPROPERTY
set Value = 1
where Name like '%etl.concurrent.threshold%'

--silo SQL SERVER
update RSI_CORE_CFGPROPERTY
set Value = 1
where Name = 'etl.transferset.transfernum'

-- blackout config on silo
update RSI_CORE_CFGPROPERTY
set value = '201'
where  name like '%etl.blackout.endtime%'

update RSI_CORE_CFGPROPERTY
set value = '200'
where name like '%etl.blackout.starttime%'

-- common configs
select * from RSI_CORE_CFGPROPERTY
where Name not like '%osm%' and Name not like 'rsi.alert%' 
and Name not like 'rsi.baseline%' and Name not like 'rsi.rr%' 
and Name not like 'rsi.scorecard%' and Name not like 'rsi.izs%' 
and Name not like 'rsi.pm%' and Name not like 'rsi.report%' 
and Name not like 'ap%' and  Name not like 'dq%' and  Name not like 'rsi.dq%' 
and  Name not like 'report%' and  Name not like 'demo%' and  Name not like 'rsi.wm%' 
and  Name not like 'cube.aa%'
and Name like '%custom%'

select * from metadata_hub.silo

-- common configs
select * from metadata_hub.SILO_CONFIG
where Name not like '%osm%' and Name not like 'rsi.alert%' 
and Name not like 'rsi.baseline%' and Name not like 'rsi.rr%' 
and Name not like 'rsi.scorecard%' and Name not like 'rsi.izs%' 
and Name not like 'rsi.pm%' and Name not like 'rsi.report%' 
and  Name not like 'ap%' and  Name not like 'dq%' 
and  Name not like 'rsi.dq%' and  Name not like 'report%' 
and   Name not like 'demo%' and  Name not like 'rsi.wm%' 
and  Name not like 'cube.aa%'
and silo_id = 'CANDY_FDCAT'