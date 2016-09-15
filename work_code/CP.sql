/* ------------------------------------------
CP
-- ------------------------------------------*/
--config change history
SELECT * FROM RSI_DEPLOY_SILO_CONFIG_HISTORY

--Upgrade history
SELECT * FROM RSI_DEPLOY_EVENTS

SELECT PROPERTY_NAME, PROPERTY_VALUE
FROM dbo.RSI_DEPLOY_SILO_CONFIG
where silo_id = 'Candy_FDCAT' 
AND HUB_ID = (SELECT TOP 1 HUB_ID FROM dbo.RSI_DEPLOY_SILO_CONFIG where silo_id = 'Candy_FDCAT' 
	AND hub_id=COALESCE(NULLIF('', ''), hub_id) ORDER BY HUB_ID)

update CP.DBO.RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = 'MR'
where SILO_ID like '%mr%'
and PROPERTY_NAME like '%etl.silo.type%'

-- Blackout config on CP
update RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = '201'
where SILO_ID like '%cat%'
and PROPERTY_NAME like '%etl.blackout.endtime%'

update RSI_DEPLOY_SILO_CONFIG
set PROPERTY_VALUE = '200'
where SILO_ID like '%cat%'
and PROPERTY_NAME like '%etl.blackout.starttime%'

-- user 
-- also used by REP
SELECT * FROM RSI_CP_USER