
select * from nodes;
select * from host_resources;
select * from resource_pools;
select * from resource_pool_status;
select * from dc_resource_acquisitions;  
select * from MONITORING_EVENTS;
select * from network_interfaces; 

-- 1.	Which queries are locked? 
-- 2.	Which locks are not released currently?
-- 3.	All the locks held by a transaction / session
-- Locks system table output shows all queries which are locked currently. It would also provide the info on which transaction(transaction_id and transaction_description columns) has taken which lock(lock_mode) on which object(object_id and object_name). request_timestamp would give us the timestamp when this lock was requested. grant_timestamp would tell us when this lock was granted.
Select * from locks;

-- 4. Use below query to find out for how much time, a transaction has acquired lock on an object.
select time,transaction_id,node_name,time-grant_Time as duration, object_name,mode 
from dc_lock_releases  where transaction_id = 'xxxxxxxxxx';

-- 5. Use below query to find out for how much time, a transaction has waited to acquire lock on an object
select time, time-start_time as queued, node_name, transaction_id, object_name, mode 
from dc_lock_attempts where transaction_id = 'xxxxxxxxxx';

-- 6. Use below query to find top queries which were holding lock on an object for maximum time
select time,transaction_id,node_name,time-grant_Time as duration, object_name,mode 
from dc_lock_releases  order by duration desc limit 50;

-- 7. Use below query to find top queries which were waiting in queue to acquire lock for maximum time
select time, time-start_time as queued, node_name, transaction_id, object_name, mode 
from dc_lock_attempts  order by queued desc limit 50;

-- 8. Use below query to find top queries which were holding lock on global catalog for maximum time
select time,transaction_id,node_name,time-grant_Time as duration, object_name,mode 
from dc_lock_releases where object_name ilike 'Global%' order by duration desc limit 50;

-- 9. Use below query to find top queries which are in queue waiting to acquire lock on global catalog for maximum time
select time, time-start_time as queued, node_name, transaction_id, object_name, mode 
from dc_lock_attempts where object_name ilike 'Global%' order by queued desc limit 50;

-- 10. You can get the transaction from transaction_id with below query
select * from query_profiles where transaction_id = ‘xxxxxxxxxxxxx’;

-- 11. Use below query to find currently executing queries in the order of their start timestamp. This would help in identifying long running queries.
select * from query_profiles where is_executing order by query_start;

-- 12. Sessions system table monitors external sessions. Use this table to identify users who are running long queries and other query related info on active sessions
select * from sessions;

-- 13. Use below query to get information on requests pending for various resource pools. Ideally this should return 0 rows.
select * from resource_queues;

-- 14. Use this table to find out the current session's sessionID and get the duration of the previously-run query.
select * from current_session;
