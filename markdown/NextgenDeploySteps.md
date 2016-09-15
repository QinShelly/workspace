# Deploy Steps on rsicorp shared server Engv2QA3.eng.rsicorp.local #
### Open deploy environment ###

    cd deploy
    setenv.cmd

## Deploy Hub Steps ##

### Create hub config on cp ### 

    ant -DsiloID=Hub -Ddw.server.name=devverticanxg.eng.rsicorp.local -Ddb.server.name=engv2qa3.eng.rsicorp.local   create-hub-config
 
To change CP, add 2 more parameters
-Dremote.cp.db.host=ENGV2NGQCPDB1-Dremote.cp.db.name=CENTRALPROVISION2

### Create hub DB & Deploy hub tables/sp/jobs ###

    ant -DsiloID=Hub_WM -Ddeploy.release.name=Ken  create-app-db deploy-silo
 
For RV only

    ant -DsiloID=Hub -Ddeploy.release.name=Ken package
    ant -DsiloID=Hub -Ddeploy.release.name=Ken deploy-app-jee
    
Hub URL
rsi.hub.portal.url in RSI_CORE_CFGPROPERTY 
  
After install Hub
- Run job #AttributeFromCP
- Run job #metadataETL step  "Metrics load"
- Run job #TransferAllMasterData, from step AttributeLoad. 
- Run job #TransferAllMasterData, from step Dimension Data. 
- (optional) Run #OraMDLoader job step 2 OraMDLoader, make sure -run is true in file C:\RSI\FusionV\scripts\dw\etl\mdload.ps1
. "$PSScriptRoot\mdloadrv.ps1" -run $true -hubServerName $hubServerName -hubDBName $hubDBName -siloId $siloId
 
## Undeploy Hub steps ##
ant -DsiloID=Hub -Ddeploy.release.name=Ken  undeploy-silo

## Deploy Silo Steps: ##

### Create silo config on cp: ### 

    ant -DsiloID=Candy_FDCAT -Ddb.server.name=engv2qa3.eng.rsicorp.local -Ddw.server.name=devverticanxg.eng.rsicorp.local -Dhub.server.name=engv2qa3.eng.rsicorp.local -Dhub.db.name=Hub -Drsi.retailer.name="Family Dollar Category" -Drsi.vendor.name="Candy" -Dcube.metrics.retailer="Family Dollar Category" -Ddeploy.release.name=Ken -Dolap.server.name=engv2qa3.eng.rsicorp.local create-silo-config
 
If vendor/retailer name is not correctly picked by Ant command

    --silo query, better to update in CP 
    update [PEPSI_Hannaford_Ken].[dbo].[RSI_CORE_CFGPROPERTY]set value = 'HANNA' 
    where  name = 'retailer.custom.ps' 
    
    --CP query
    Must change for ODS2NXG (Ahold) SVR
    update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'ODS2NXG' where silo_id= 'PG_Ahold' and PROPERTY_NAME like '%installation.type%'
    
    --(optional) change to use live2 instance for cube
    update  RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = '\live2'
    where silo_id   = 'ahold_rsc'
    and property_name = 'olap.server.instance'
    
    -- blackout config on CP
    update RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = '201'
    where SILO_ID like 'cat%'
    and PROPERTY_NAME like '%etl.blackout.endtime%'
    
    update RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = '200'
    where SILO_ID like 'cat%'
    and PROPERTY_NAME like '%etl.blackout.starttime%'
    
### Create Silo DB & Deploy silo ###

    ant -DsiloID=PG_AHOLD -Ddeploy.release.name=Ken create-app-db deploy-silo
  
- Run #CubeUpdate job, step 'Materialize' if there is no master data.
 
Sometimes calendar is not configured on DEV CP for the ven/ret combo. We can add a 445 standard calendar manually by running below query. After this query completes, we need to run hub job #AttribsfromCP
    
    INSERT INTO CP.[dbo]. [RSI_META_CALENDAR]
       ([VENDOR_NAME]
       ,[RETAILER_NAME]
       ,[CALENDAR_KEY]
       ,[CALENDAR_NAME]
       ,[FOLDER]
       ,[OWNER_TYPE]
       ,[PREFIX]
       ,[ANALYSIS]
       ,[DEFAULT]
       ,[MONTH]
       ,[INTERNAL_NAME]
       ,[CREATE_DT]
       ,[UPDATE_DT]
       ,[UPDATE_BY]
       ,[APPLIED_DT]
       ,[STATUS]
       ,[IS_STORE_CALENDAR]
       ,[IS_REGULAR_CALENDAR])
     VALUES
       ('Nestle'
       ,'Pingo Doce'
       ,2
       ,'445 (Standard)'
       ,''
       ,''
       ,'Standard'
       ,1
       ,1
       ,1
       ,'Cal1'
       ,getdate()
       ,getdate()
       ,'Ken'
       ,null
       ,'N'
       ,null
       ,null)

### Load Fact Data Steps: ###
Run job  transferallfact data on silo

Then delete the period keys you don’t want in etl.transfer_fact_daily table on hub.

Then run FactETL job on silo.

## Undeploy silo steps: ##
ant -DsiloID=PEPSI_HEB -Ddeploy.release.name=Ken undeploy-silo

Other tools

 C:\RSI\nextgen\deploy>powershell ..\scripts\dw\db\factdatagen.ps1 -siloID PEPSI_FLION -siloServerName "engp3qa3\db1" -periodKeyStart 20130101 -periodKeyEnd 20140601
 
C:\rsi\nextgen\scripts\dw\olap> .\cubevalidation.ps1  -siloServerName engp3qa3\db1 -siloDBName Dannon_Meijer -siloID Dannon_Meijer

# DEPLOY MR: #

- Create MR silo config

    ant -DsiloID=PG_MR -Ddb.server.name= engp3qa3  -Ddw.server.name=10.172.32.16 -Dhub.server.name= engp3qa3  -Dhub.db.name=Hub -Drsi.retailer.name="Multi-Retailer" -Drsi.vendor.name="Procter & Gamble" -Dcube.metrics.retailer="Multi-Retailer" -Ddeploy.release.name= Ken -Dolap.server.name=engp3qa3   create-silo-config
    
After create silo config of MR
    
    --below CP table will be imported to metadata_hub.silo_mapping table
    insert into CP.dbo.RSI_DEPLOY_SILO_MAPPING
    VALUES('hub' ,'PG_MR', 'PG_TARGET',15 ,300)
    insert into CP.dbo.RSI_DEPLOY_SILO_MAPPING
    VALUES('hub' ,'PG_MR', 'PG_AHOLD',267 ,300)
    
    --below CP table will be imported to config_customer 
    INSERT INTO [CP] .[dbo] . [RSI_DEPLOY_SILO_RV] ( [SILO_ID] , [VENDOR_NAME] , [RETAILER_NAME] , [ETL_PATH] , [VENDOR_KEY] , [RETAILER_KEY] , [WHSE_RETAILER_KEY] , [SUFFIX] , [UPDATE_DT] , [UPDATE_BY] , [HUB_ID] , [DISPLAY_ORDER])
    VALUES ( 'PG_MR' , 'Procter & Gamble' , 'TARGET' , 'c:\' , 300 , 15 , 153 , 'PNGTARGET' ,NULL ,NULL , 'HUB' , 1)
    INSERT INTO [CP] .[dbo] . [RSI_DEPLOY_SILO_RV] ( [SILO_ID] , [VENDOR_NAME] , [RETAILER_NAME] , [ETL_PATH] , [VENDOR_KEY] , [RETAILER_KEY] , [WHSE_RETAILER_KEY] , [SUFFIX] , [UPDATE_DT] , [UPDATE_BY] , [HUB_ID] , [DISPLAY_ORDER])
    VALUES ( 'PG_MR' , 'Procter & Gamble' , 'AHOLD' , 'c:\' , 300 , 267 , 268 , 'PNGAHOLD' ,NULL ,NULL , 'HUB' , 2) 
    
    update CP.DBO.RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = 'MR'
    where SILO_ID like 'mr%'
    and PROPERTY_NAME like '%etl.silo.type%'
    
    update RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = 'mrcalculations.mdx'
    where SILO_ID like 'mr%'
    and PROPERTY_NAME like '%cube.calcmetrics.mdx%'

- Deploy MR silo

    ant -DsiloID=PG_MR -Ddeploy.release.name=Ken create-app-db deploy-silo



# Deploy RSC #

--Update Is_Dummy to 0 to run ant on hub
update RSI_DIM_VENDOR
set is_dummy = 0
where vendor_name like '%Retailer Scorecard%'

ant -DsiloID=Ahold_RSC -Ddb.server.name=engp3qa3 -Ddw.server.name=10.172.32.16 -Dhub.server.name=engp3qa3 -Dhub.db.name=Hub -Drsi.retailer.name="Ahold" -Drsi.vendor.name="Retailer Scorecard" -Dcube.metrics.retailer="AHOLD Scorecard" -Ddeploy.release.name=Ken -Dolap.server.name=engp3qa3  create-silo-config

--update Is_Dummy back to 1
update RSI_DIM_VENDOR
set is_dummy = 1
where vendor_name like '%Retailer Scorecard%'

--CP
update  RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = '\live1'
where silo_id   = 'ahold_rsc'
and property_name = 'olap.server.instance'

delete from RSI_DEPLOY_SILO_RV
where SILO_ID  = 'ahold_rsc'

INSERT [dbo] .[RSI_DEPLOY_SILO_RV] ([SILO_ID], [VENDOR_NAME], [RETAILER_NAME], [ETL_PATH], [VENDOR_KEY], [RETAILER_KEY], [WHSE_RETAILER_KEY], [SUFFIX], [UPDATE_DT], [UPDATE_BY], [HUB_ID], [DISPLAY_ORDER]) VALUES (N'Ahold_RSC' , N'Procter & Gamble', N'Ahold', N'C:', 300 , 267, 268, N'PGAHOLD', NULL, NULL, N'Hub', NULL)
INSERT [dbo] . [RSI_DEPLOY_SILO_RV] ( [SILO_ID], [VENDOR_NAME] , [RETAILER_NAME], [ETL_PATH], [VENDOR_KEY], [RETAILER_KEY] , [WHSE_RETAILER_KEY], [SUFFIX], [UPDATE_DT], [UPDATE_BY] , [HUB_ID], [DISPLAY_ORDER]) VALUES (N'Ahold_RSC' , N'PepsiCo' , N'Ahold' , N'C:' , 55 , 267, 268, N'PepsiAHOLD', NULL, NULL, N'Hub', NULL)
  
insert into CP.dbo.RSI_DEPLOY_SILO_MAPPING values('Hub' ,'Ahold_RSC', 'PG_Ahold',267 ,300)
insert into CP.dbo.RSI_DEPLOY_SILO_MAPPING values('Hub' ,'Ahold_RSC', 'Pepsi_Ahold',267 ,55)

update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'AHOLDRSC' where silo_id='Ahold_RSC' and PROPERTY_NAME like '%retailer.custom.ps%'
update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE='rsccalculations.mdx' where silo_id= 'Ahold_RSC' and PROPERTY_NAME like '%cube.calcmetrics.mdx%'
update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'RSC' where silo_id='Ahold_RSC' and PROPERTY_NAME like '%etl.silo.type%'
update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'AHOLD Scorecard' where silo_id ='Ahold_RSC' and PROPERTY_NAME like '%cube.metrics.retailer%'
update CP.dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'ODS2NXG' where silo_id='Ahold_RSC' and PROPERTY_NAME like '%installation.type%'
update CP. dbo.RSI_DEPLOY_SILO_CONFIG set PROPERTY_VALUE= 'FALSE'
where silo_id= 'Ahold_RSC' and PROPERTY_NAME like '%cube.advancemetrics.enabled%'


ant -DsiloID=Ahold_RSC -Ddeploy.release.name=Ken create-app-db

ant -DsiloID=Ahold_RSC -Ddeploy.release.name=Ken deploy-silo

# Deploy CAT #

ant -DsiloID =Candy_WAGCAT -Ddb.server.name=engp3qa3 -Ddw.server.name=10.172.32.16 -Dhub.server.name= engp3qa3  -Dhub.db.name=Hub -Drsi.retailer.name= "Walgreens Category" -Drsi.vendor.name ="Candy" -Dcube.metrics.retailer=Walgreens -Ddeploy.release.name=Ken -Dolap.server.name= engp3qa3   create-silo-config

update CP.DBO.RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = 'CAT'
where SILO_ID like 'cat%'
and PROPERTY_NAME like '%etl.silo.type%'

update CP.RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = 'catcalculations.mdx'
where SILO_ID like 'cat%'
and PROPERTY_NAME like '%cube.calcmetrics.mdx%'

--must be Category
update RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = 'category'
where SILO_ID like '%cat%'
and PROPERTY_NAME like '%retailer.custom.ps%'

ant -DsiloID=Candy_WAGCAT -Ddeploy.release.name=Ken create-app-db

ant -DsiloID=Candy_WAGCAT -Ddeploy.release.name=Ken deploy-silo

# Deploy WM #
First deploy RDP （Use RDP project)

	ant -DsiloID=RDP -Ddeploy.release.name=8010  create-rdp-config -Ddb.server.name=engp3qa3 -Ddw.server.name=10.172.32.16

	ant -DsiloID=RDP -Ddeploy.release.name=8010  create-app-db

	ant -DsiloID=RDP -Ddeploy.release.name=8010  deploy-rdp

Be noted: Replace SEAN to some other work

    ant -f build-wm.xml -DsiloID=WM_HUB -Ddw.server.name=10.172.32.16 -Ddb.server.name=engp3qa3  create-wm-hub-config

--Create Hub DB
	ant -DsiloID=WM_HUB  -Ddeploy.release.name=8010  create-app-db

--Deploy Hub
	ant -DsiloID=WM_HUB  -Ddeploy.release.name=8010  deploy-silo

--Create Silo Config
	ant  -f build-wm.xml -DsiloID=Unilever_WM -Ddb.server.name=engp3qa3 -Ddw.server.name=10.172.32.16 -Dhub.server.name=engp3qa3 -Dhub.db.name=WM_HUB  -Dolap.server.name=engp3qa3 -Drsi.retailer.name=Walmart -Drsi.vendor.name="Unilever Internal" -Dcube.metrics.retailer=WMSSC -Detl.silo.type=WMSSC -Drdp.silo.id=RDP -Drdp.server.name = "10.172.32.16" -Drdp.schema.name=RDP create-wm-silo-config 

--Create silo DB
	ant -DsiloID=Unilever_WM  -Ddeploy.release.name=8010   create-app-db

--Deploy silo
	ant -f build-wm.xml -DsiloID=Unilever_WM -Ddeploy.release.name=8010 deploy-wm-silo

OSM  

	update  [CP] .[dbo]. [RSI_DEPLOY_SILO_CONFIG] set PROPERTY_value ='true'
	where SILO_ID ='SEAN_DEV_PEPSI_TARGET'
	and PROPERTY_NAME in ('cube.scorecard.enabled', 'cube.aaalertmetrics.enabled','cube.osacube.enabled' ,
	'cube.osmalertmetrics.enabled')
 
  
	select * from  [CP] .[dbo]. [RSI_DEPLOY_SILO_CONFIG]
	where SILO_ID ='SEAN_DEV_PEPSI_TARGET'
	and PROPERTY_NAME in ('cube.scorecard.enabled', 'cube.aaalertmetrics.enabled','cube.osacube.enabled' ,
	'cube.osmalertmetrics.enabled')

Silo deployment steps for deploying on QA ENV:

We need to do some changes in following files :
1.       $\Nextgen\deploy\build.xml :
Change value of this property
 <property name="remote.cp.db.host" value="ENGV2HCDBQA1"/>
                <property name="remote.cp.db.name" value="CENTRALPROVISION2"/>

2.       $\release_8000SP5\data\siloconfig.sql
Change instance to db6 : SELECT '$(siloId)','db.server.instance','\db6','db'

	ant -DsiloID=COLGTE_SORIAN_Pari1 -Ddb.server.name=ENGV2HSDBQA1 -Ddw.server.name=QAVERTICANXG.ENG.RSICORP.LOCAL -Dhub.server.name=ENGV2HHDBQA1\RV1 -Dhub.db.name=HUB_FUNCTION_DEV -Drsi.retailer.name= "Soriana" -Drsi.vendor.name="Colgate" -Dcube.metrics.retailer= "Soriana" -Ddeploy.release.name=COLGTE_SORIAN_Pari1 -Dolap.server.name=ENGV2HSRLPQA1 create-silo-config

	ant -DsiloID=COLGTE_SORIAN_Pari1 -Ddeploy.release.name=COLGTE_SORIAN_Pari1 create-app-db

	ant -DsiloID= COLGTE_SORIAN_Pari1 -Ddeploy.release.name=COLGTE_SORIAN_Pari1 deploy-silo


## steps for Deploy on differenct domain server ##

## Create Hub Config ##
    ant -DsiloID=HUB -Ddw.server.name=10.172.32.17 -Ddb.server.name=192.168.28.149 create-hub-config -Dremote.cp.db.host=192.168.28.149\sql2014 -Dremote.cp.db.name=CP

    update RSI_DEPLOY_SILO_CONFIG
    set PROPERTY_VALUE = '\\192.168.28.149\Data'
    where SILO_ID = 'Hub'
    and PROPERTY_NAME  = 'masterdata.data.dir'

Create db and Deploy Hub

    ant -DsiloID=HUB create-app-db deploy-silo -Ddeploy.release.name=Ken  -Dremote.cp.db.host=192.168.28.149\sql2014 -Dremote.cp.db.name=CP

## Create Silo Config ##
    ant -DsiloID=PEPSI_Meijer -Ddb.server.name=192.168.28.149 -Ddw.server.name=10.172.32.17 -Dhub.server.name=192.168.28.149 -Dhub.db.name=HUB_Shanghai -Drsi.retailer.name=Meijer -Drsi.vendor.name=PepsiCo -Dcube.metrics.retailer=Meijer -Dolap.server.name=192.168.28.149 create-silo-config -Dremote.cp.db.host=192.168.10.35\rv -Dremote.cp.db.name=CP
Create db and Deploy Silo

    ant -DsiloID=PEPSI_Meijer create-app-db deploy-silo -Ddeploy.release.name=Hub_Shanghai -Dremote.cp.db.host=192.168.10.35\rv -Dremote.cp.db.name=CP
