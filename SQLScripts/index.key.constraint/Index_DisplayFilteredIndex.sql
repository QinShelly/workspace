--Create 
CREATE NONCLUSTERED INDEX [IX_tblLaborEntryCustomerInteractionReason_Pre_VersionNumber] ON [dbo].[tblLaborEntryCustomerInteractionReason_Pre] 
(
	[VersionNumber] ASC
)
WHERE ([VersionNumber]>0x00000000EA4851DD)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

--Query
SELECT ind.index_id           ,
       ind.name               ,
       ind.type_desc          ,
       par.reserved_page_count,
       par.used_page_count    ,
       par.row_count          ,
       ind.filter_definition
FROM   sys.dm_db_partition_stats par
       INNER JOIN sys.indexes ind
       ON     par.object_id = ind.object_id
          AND par.index_id  = ind.index_id
WHERE  par.object_id        = OBJECT_ID('tblLaborEntryCustomerInteractionReason_Pre')
