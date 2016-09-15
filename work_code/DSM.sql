EXEC master .dbo. sp_addlinkedserver @server = N'POC2CC1', @srvproduct=N'Oracle' , @provider=N'OraOLEDB.Oracle' , @datasrc=N'(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.36.71)(PORT=1526))(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.36.71)(PORT=1521))(LOAD_BALANCE=yes))(SDU=32767)(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=POC2CC1)))'

Login :192.168.36.71

account: app_mss
Password: app_mss
Db: poc2cc1
Connect as Normal

select * from rsnet_dim.retailer_vendor_dim
where active = 'T'

select * from rsnet.novrts_daily

select * from RSNET.POS_LAST_LOAD_STATISTICS 
where supplier_key = 647 and retailer_key =  101 
