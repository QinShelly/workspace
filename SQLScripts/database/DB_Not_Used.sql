select [name] from sys.databases 
where database_id > 4
AND [name] NOT IN 
(select DB_NAME(database_id) 
from sys.dm_db_index_usage_stats
where coalesce(last_user_seek, last_user_scan, last_user_lookup,'1/1/1970') > 
(select login_time from sysprocesses where spid = 1))