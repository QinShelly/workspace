--Find Index not being used and generate drop script
select
 'drop index ' + stats.table_name + '.' + i.name as DropIndexStatement,
 stats.table_name as TableName,
 i.name as IndexName,
 i.type_desc as IndexType,
 stats.seeks + stats.scans + stats.lookups as TotalAccesses,
 stats.seeks as Seeks,
 stats.scans as Scans,
 stats.lookups as Lookups
 from
 (select
 i.object_id,
 object_name(i.object_id) as table_name,
 i.index_id,
 sum(i.user_seeks) as seeks,
 sum(i.user_scans) as scans,
 sum(i.user_lookups) as lookups
 from
 sys.tables t
 inner join sys.dm_db_index_usage_stats i
 on t.object_id = i.object_id
 group by
 i.object_id,
 i.index_id
 ) as stats
 inner join sys.indexes i
 on stats.object_id = i.object_id
 and stats.index_id = i.index_id
 where stats.seeks + stats.scans + stats.lookups = 0 --Finds indexes not being used
 and i.type_desc = 'NONCLUSTERED' --Only NONCLUSTERED indexes
 and i.is_primary_key = 0 --Not a Primary Key
 and i.is_unique = 0 --Not a unique index
 and stats.table_name not like 'sys%'
 order by stats.table_name, i.name
