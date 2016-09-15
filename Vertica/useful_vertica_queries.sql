-- Check environment
select version();
select * from nodes;

-- Find where Vertica keeps information
select * from system_tables;
select * from system_tables where table_name like '%pool%'; -- or anything else you're looking for
select * from configuration_parameters;
select * from configuration_parameters where parameter_name ilike '%EE%';
select component, table_name, description from data_collector;
select component, table_name, description from data_collector where component ilike '%resource%';

-- Get a list of all queries running on the cluster
select session_id, query, query_duration_us from query_profiles 
where transaction_id in (select transaction_id from execution_engine_profiles where is_executing);

-- Get active loads
select table_name, read_bytes, input_file_size_bytes, accepted_row_count, rejected_row_count, sort_complete_percent 
from load_streams where is_executing
order by table_name;

-- Kill query
-- Interrupts the specified statement (within an external session), rolls back the current transaction, and writes a success or failure message to the log file.
select interrupt_statement( 'session_id', statement_id );

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

-- Get queries sitting in the queue waiting on resources
select pool_name
, avg(memory_requested_kb) memory_requested_kb , count(distinct transaction_id) num_of_sql ,
current_statement sql_statement
from ( select a.node_name, a.pool_name , a.transaction_id , b.current_statement
, sum(a.memory_requested_kb) memory_requested_kb from
resource_queues a left join sessions b using (transaction_id) group by 1,2,3, 4) t group by 1, 4;

-- Get all resource pool usage
select pool_name, sum(memory_inuse_kb) from resource_acquisitions where is_executing group by pool_name;


 
-- Top operator for query by execution time
-- or choose whatever you want from the list in the next query
select operator_name, path_id, sum(counter_value) 
from v_monitor.execution_engine_profiles 
--where transaction_id = 45035996273739352 and statement_id = 59 
where counter_name ilike 'execution%' group by operator_name, path_id order by 3 desc;

-- Totals for the counters
select counter_name, sum(counter_value) from v_monitor.execution_engine_profiles 
--where transaction_id = 45035996273739352 and statement_id = 59 
group by counter_name order by 2 desc;

select distinct(event_type) from dc_execution_engine_events; 

-- Find the overall cpu usage and I/O disk latency data in a Vertica cluster:
Create View cpu_io_performance
AS
Select B.start_time, B.node_name, C.avg_latency_ms, B.IO_Wait_Percent, B.average_cpu_usage_percent, (round(case when C.perc>=100 then 100 else C.perc end, 1.0)) as Disk_Utilization_Percent
From ( Select node_name,
timestamp_trunc(start_time, 'MI') as start_time,
timestamp_trunc(end_time, 'MI') as end_time,
round((CAST(Actual_IO_Wait_Time*1.00/Total_CPU_Time As DEC(4,2))*100),1.0) As IO_Wait_Percent,
round((CAST(Actual_Idle_CPU_Time*1.00/Total_CPU_Time As DEC(4,2))*100),1.0) As Idle_CPU_Percent,
round((100 - CAST(Actual_Idle_CPU_Time*1.00/Total_CPU_Time As DEC(4,2))*100),1.0) As average_cpu_usage_percent
From (
SELECT node_name,start_time,end_time,
(io_wait_microseconds_end_value - io_wait_microseconds_start_value )//(1024*1024) As Actual_IO_Wait_Time,
(idle_microseconds_end_value - idle_microseconds_start_value)//(1024*1024) As Actual_Idle_CPU_Time,
(user_microseconds_end_value + nice_microseconds_end_value + system_microseconds_end_value
+ idle_microseconds_end_value + io_wait_microseconds_end_value + irq_microseconds_end_value
+ soft_irq_microseconds_end_value + steal_microseconds_end_value + guest_microseconds_end_value
- user_microseconds_start_value - nice_microseconds_start_value - system_microseconds_start_value
- idle_microseconds_start_value - io_wait_microseconds_start_value - irq_microseconds_start_value
- soft_irq_microseconds_start_value - steal_microseconds_start_value - guest_microseconds_start_value)//(1024*1024) As Total_CPU_Time
FROM v_internal.dc_cpu_aggregate_by_minute ) As A ) As B
INNER JOIN
( select timestamp_trunc(start_time,'MI') as start_time,
node_name ,
max((( total_read_mills_end_value-total_read_mills_start_value + total_written_mills_end_value-total_written_mills_start_value )/NULLIFZERO(total_reads_end_value+total_writes_end_value-total_reads_start_value-total_writes_start_value))::DEC(4,2)) As avg_latency_ms ,
max((total_ios_mills_end_value-total_ios_mills_start_value)/((extract('epoch' from end_time)-extract('epoch' from start_time))*1000))*100 as perc
from dc_io_info_by_minute
group by timestamp_trunc(start_time, 'MI'), node_name ) As C
ON ( B.node_name = C.node_name
AND B.start_time = C.start_time );

--Usage example:
Select * From cpu_io_performance B
Where B.start_time BETWEEN CAST('2013-09-11 13:00:00' As TIMESTAMP) - interval '30 minutes' AND CAST('2013-09-11 13:00:00' As TIMESTAMP)
AND B.node_name ILIKE '%node0004%'
AND B.IO_Wait_Percent > 0
Order By 1,2 ASC;

--How Many Tables Are There In The Database:
SELECT COUNT(*) FROM tables;

--Stop using projection(s) in plans/queries:
SELECT set_optimizer_directives('AvoidUsingProjections=$a_p1,$a_p2');

--To enable again:
SELECT set_optimizer_directives('AvoidUsingProjections=');

--How Many Projections Does Each Table Have:
SELECT 	COUNT(anchor_table_name), 
	anchor_table_name 
FROM projections 
GROUP BY anchor_table_name;

--How Many Rows Does Each Table Have:
SELECT 	SUM(row_count), 
	anchor_table_name 
FROM projection_storage 
GROUP BY anchor_table_name;

SELECT    SUM(a.row_count),
    a.anchor_table_schema,
    a.anchor_table_name
FROM	projection_storage a
	INNER JOIN (SELECT MIN(c.projection_id) AS projection_id,c.anchor_table_name,c.projection_schema 
	FROM projections c GROUP BY 2,3) b
	ON a.projection_id = b.projection_id
GROUP BY 2,3;

--List Storage Consumption Per Projection Per Table:
SELECT SUM(used_bytes), 
anchor_table_name, 
projection_name 
FROM projection_storage 
GROUP BY projection_name, anchor_table_name 
ORDER BY anchor_table_name;

--List Storage Consumption Per Table:
SELECT SUM(used_bytes), 
	anchor_table_name 
FROM projection_storage 
GROUP BY anchor_table_name 
ORDER BY anchor_table_name;

--List The Total Number Or Roses Per Node, Per Projection:
SELECT ros_count, 
	node_name, 
	projection_name, 
	anchor_table_name 
FROM projection_storage 
ORDER BY anchor_table_name;

--List Projections With No Statistics:
SELECT projection_name 
FROM projections 
WHERE NOT has_statistics
and projection_schema like '%<schemaname>%';
;

--List All Errors In DB In The Last 4 Hours:
SELECT error_level,error_code,message,detail,hint, event_timestamp 
FROM error_messages 
WHERE event_timestamp >= NOW() - INTERVAl '4 hours';

--List all non-up-to-date projections:
SELECT projection_schema, projection_name, anchor_table_name, is_up_to_date 
FROM projections 
WHERE NOT is_up_to_date;

--List all dc tables available:
SELECT * FROM data_collector;

--List the current resource pool settings:
SELECT * FROM resource_pools;

--How to see the current projection refresh status:
SELECT * FROM projection_refreshes;

--List the current sessions:
SELECT * FROM sessions;

--How to find the definition of a view given its name:
SELECT view_definition 
FROM views 
WHERE table_name ILIKE '<VIEW_TO_BE_DEFINED>';

--How to find the definition of tables and projections:
SELECT export_objects('','<TABLE_OR_PROJECTION_NAME>');

--Given a projection name figure out whether it is a super projection or not:
SELECT 
	COUNT(DISTINCT column_name) + 1 = projection_column_count as "Is Super Projections" 
FROM columns, projection_storage 
WHERE anchor_table_id = table_id 
	AND projection_name ILIKE '<PROJECTION_NAME>' 
GROUP BY projection_column_count;
	
--For a specific query (given the transaction_id and statement_id),
-- find out which execution engine operator took the longest to execute
SELECT operator_name, 
	AVG(counter_value) as "Average Time Per Thread" 
FROM dc_execution_engine_profiles 
WHERE counter_name ILIKE '%execution time%' 
	AND transaction_id =<TRANSACTION_ID> 
	AND statement_id =<STATEMENT_ID> 
GROUP BY operator_name 
ORDER BY "Average Time Per Thread" DESC;

--List all SPILL events in the last 24 hours
SELECT time, 
	transaction_id, 
	statement_id, 
	request_id, 
	event_type, 
	event_description 
FROM dc_execution_engine_events 
WHERE (NOW() - time) < '24 hours' 
	AND event_type ILIKE '%SPILL%' 
ORDER BY time DESC;

--Find out what resources were used by a specific query (given its transaction_id and statement_id)
SELECT *
FROM resource_acquisitions 
WHERE transaction_id = <TRANSACTION_ID> 
	AND statement_id = <STATEMENT_ID>;
	
--List wall time vs run time for each execution engine operator given transaction_id and statement_id
SELECT operator_name, 
	counter_name,
	AVG(counter_value)
FROM dc_execution_engine_profiles
WHERE counter_name ILIKE '%time%'
GROUP BY operator_name, counter_name
ORDER BY operator_name, counter_name;

--Find the busiest hour in the day for IO
SELECT DATE_TRUNC('hour', start_time) as "HOUR", 
	(SUM(read_kbytes_per_sec) + SUM(written_kbytes_per_sec)) * 60/1024/1024 as "Total IO (GB)", 
	SUM(read_kbytes_per_sec) * 60/1024/1024 as "Read IO (GB)", 
	SUM(written_kbytes_per_sec) * 60/1024/1024 as "Write IO (GB)" 
FROM io_usage 
GROUP BY "Hour"
ORDER BY "Total IO (GB)" DESC;

--Use the following to list all the available Vertica options:
select show_all_vertica_options();

--To enable HASH JOIN SPILL At the system level
Select add_vertica_options('EE','ENABLE_JOIN_SPILL');
-- At the query level
SELECT/*+ set_vertica_options(EE,ENABLE_JOIN_SPILL) */.... 

--Find the overall WOS/ROS usage info on all nodes:
SELECT node_name,
       SUM(wos_used_bytes)//1024//1024//1024 As WOS_GB,
       SUM(wos_row_count) As WOS_RC,
       SUM(ros_used_bytes)//1024//1024//1024 As ROS_GB,
       SUM(row_row_count) As ROS_RC,
       SUM(total_used_bytes)//1024/1024//1024 As TOTAL_GB,
       SUM(total_row_count) As TOTAL_RC
FROM resource_usage
Group By 1
Order By 1;

--Get the list of encoding types:
SELECT encodings
FROM column_storage
Group By 1
Order By 1;

--Find the # of ROS containers for a projection:
SELECT 
projection_name,
       node_name,
       COUNT(DISTINCT storage_oid)
FROM storage_containers
WHERE schema_name='<schema_name>'
AND projection_name='<projection_name>'
GROUP BY 1,2
ORDER BY 1,2;

--Use the following to move table from one schema to another:
ALTER TABLE <old_schema>.<table_name> SET SCHEMA <new_schema>;

--Use the following to check for the status of a projection:
SELECT get_table_projections('<schema_name>.<table_name>');

--To cancel one or all the active sessions:
SELECT close_session(<SessionID>);
SELECT close_all_sessions();

--Assign a specific resource pool to a session:
SET SESSION RESOURCE POOL pool-name;

--Show Tuple Mover Operation Durations
 SELECT DATEDIFF(mi, mergeout_start.operation_start_timestamp, CASE
                        WHEN mergeout_end.operation_status = 'Running'
                                THEN now()
                        ELSE mergeout_end.operation_start_timestamp
                        END) AS Minutes_TO_Complete,
        mergeout_end.operation_status AS Mergeout_Status,
        mergeout_start.operation_start_timestamp AS MergeOut_Start,
        mergeout_end.operation_start_timestamp AS MergeOut_End,
        mergeout_start.table_name,
        mergeout_start.projection_name,
        mergeout_start.total_ros_used_bytes AS ros_bytes,
        CAST(mergeout_start.total_ros_used_bytes / 1024.0 / 1024.0 AS DECIMAL(14, 2)) AS ros_MB,
        mergeout_start.earliest_container_start_epoch AS start_epoch,
        mergeout_start.latest_container_end_epoch AS end_epoch,
        mergeout_start.ros_count
FROM (
        SELECT *
        FROM tuple_mover_operations
        WHERE operation_name = 'Mergeout'
                AND operation_status IN ('Start')
        ) AS mergeout_start
LEFT JOIN (
        SELECT *
        FROM tuple_mover_operations
        WHERE operation_name = 'Mergeout'
                AND operation_status IN (
                        'Complete',
                        'Running'
                        )
        ) AS mergeout_end ON mergeout_start.earliest_container_start_epoch = mergeout_end.earliest_container_start_epoch
        AND mergeout_start.latest_container_end_epoch = mergeout_end.latest_container_end_epoch
        AND mergeout_start.ros_count = mergeout_end.ros_count
        AND mergeout_start.total_ros_used_bytes = mergeout_end.total_ros_used_bytes
        AND mergeout_start.session_id = mergeout_end.session_id
ORDER BY CASE
                WHEN mergeout_end.operation_status = 'Running'
                        THEN 1
                ELSE 2
                END,
        mergeout_start.operation_start_timestamp DESC;

--Show projection refresh status
 create or replace view projection_refresh_monitor asselect anchor_table_name, rows_processed, table_rows,
projections_refreshing, (rows_processed::FLOAT/(table_rows *
projections_refreshing) * 100)::INTEGER as percent_complete
from (
   (select sum(counter_value)::FLOAT as rows_processed from
execution_engine_profiles where operator_name = 'DataTarget' and
counter_name = 'input rows' and is_executing=true) a
   cross join
   (select count(1)::FLOAT as projections_refreshing from
projection_refreshes where refresh_status = 'refreshing')   b
   cross join
   (select anchor_table_name from projection_refreshes where
refresh_status = 'refreshing' limit 1) c
   cross join
   (select sum(row_count) as table_rows from projection_storage where
anchor_table_name = (select anchor_table_name from projection_refreshes
where refresh_status = 'refreshing' limit 1) group by projection_name
order by 1 desc limit 1) d
) a;

--Clean Up DBD if it Failed
select dbd_drop_all_workspaces('designer');
--See DBD design status
SELECT * FROM  design_status;
--Select Bytes per Row in a Projection
SELECT projection_name, rows, bytes, bytes / rows AS bytes_per_row
FROM (
    SELECT projection_name, SUM(row_count) AS rows, SUM(used_bytes) AS bytes
    FROM projection_storage
    GROUP BY projection_name
) AS sq;
--Show last access to tables (by reading projection usage)
select table_name, max(time) as last_access, user_name from dc_projections_used where is_virtual = 'f' and table_schema not like 'v_%' group by table_name, user_name order by 2,3 desc;
--Select data distribution across nodes in order to highlight data skew due to poor segmentation key
select node_name, used_bytes from projection_storage where projection_schema = '<schema name>' and anchor_table_name = '<table name>' group by 1,2 order by 2 desc;
--Test candidate segmentation key(s) for distribution of distinct values
select min(cnt) as min_count, max(cnt) as max_count 
from ( select <candidate key(s)>, count(*) as cnt from <schema_name.table_name> group by 1 ) as foo;

