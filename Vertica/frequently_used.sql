-- Basic query troubleshooting: find where resources are spend
-- Add the keyword PROFILE before your query you would like to examine
-- PROFILE generates HINT that identifies transaction_id and statement_id
profile SELECT * FROM JNJ_Boots.OLAP_ITEM limit 10;

SELECT export_objects('' ,'nestle_casino.OLAP_WHSE_FACT_COMPUTED' );

select view_definition from views
where table_name = 'olap_store_fact'
and table_schema ='Dannon_Meijer'

select * from tables
where table_name = 'olap_store_fact'
and table_schema ='Dannon_Meijer'

select * from columns
where column_name = 'DC On Hand Amount'
and table_schema = 'NESTLE_CASINO'
order by table_name
limit 1

--To cancel one or all the active sessions:
SELECT close_session(<SessionID>);
SELECT close_all_sessions();

select * from system_tables;

select * from node_states

--dim table size
select t.table_schema,
t.table_name,p.projection_name,max(ps.wos_row_count + ps.ros_row_count)
FROM tables t
   JOIN projections p ON t.table_id = p.anchor_table_id
   JOIN projection_storage ps on p.projection_id = ps.projection_id
   WHERE t.table_name = '<tableName>'
   and table_schema = '<tableSchema>'
   group by t.table_schema,
t.table_name,p.projection_name

--fact table size
select t.table_schema,
t.table_name,p.projection_name,sum(ps.wos_row_count + ps.ros_row_count)
FROM tables t
JOIN projections p ON t.table_id = p.anchor_table_id
JOIN projection_storage ps on p.projection_id = ps.projection_id
WHERE t.table_name = '<tableName>'
and table_schema = '<tableSchema>'
group by t.table_schema,t.table_name,p.projection_name

--query profile
select * from query_profiles
where query like '%PEPSICO_WALGRN_DEV%'
and identifier = 'GX_ROLAP'
and query_start >'2015-07-21 03:19:36.846274-04'
--and transaction_id  = 63050394794117164
order by query_start desc limit 1000

-- Find your query basic info
-- i.e. for query from '%fact%' table or whatever else you're looking for
select user_name, session_id, transaction_id, statement_id, trim(' ' from request), request_duration_ms, start_timestamp
from query_requests where request not ilike '%query_requests%' 
and request ilike '%fact%' 
order by start_timestamp desc limit 100;

--Given a transaction_id and statement_id corresponding to a query, find out how long did the query take to run
SELECT request_duration_ms 
FROM query_requests 
WHERE transaction_id = <TRANSACTION_ID> 
	AND statement_id = <STATEMENT_ID>;

--Use Query_Requests to track the progress info of the rebalance process:
SELECT * 
FROM query_requests 
WHERE request ILIKE 'SELECT rebalance_cluster();' 
ORDER BY start_timestamp DESC;

--Find out what resources were used by a specific query (given its transaction_id and statement_id)
SELECT *
FROM resource_acquisitions 
WHERE transaction_id = <TRANSACTION_ID> 
	AND statement_id = <STATEMENT_ID>;
	
-- Get queries that are running with resources acquired and average run time
select pool_name
, round(avg(memory_inuse_kb)/1024) memory_inuse_mbcommas
, avg(execution_minutes) avg_execution_minutes
, count(distinct transaction_id) num_of_sql
, current_statement sql_statement 
from (select a.node_name,
        a.pool_name
        ,a.transaction_id
        ,b.current_statement
        ,sum(a.memory_inuse_kb) memory_inuse_kb
        ,sum( datediff('minute',b.statement_start::timestamp,STATEMENT_TIMESTAMP())) execution_minutes
from resource_acquisitions a
left join sessions b
using (transaction_id)
where is_executing
group by 1,2,3, 4) t
where current_statement not ilike '%resource_acquisitions%'
group by 1, current_statement;

-- Get all resource pool usage
select pool_name, sum(memory_inuse_kb) from resource_acquisitions where is_executing group by pool_name;


--list the roles available to you
show available_roles; 

--set the session to an elevated role [fusion_admin]
set role fusion_admin; 

--list the enabled roles in your session
show enabled_roles; 

--Run commands that need elevated rights like CREATE/DROP SCHEMA, CREATE/DROP TABLE etc…  

--unset session from the elevated role [fusion_admin]
set role default;
