SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_PADDING ON
GO

----Create Util schema if it doesn't exist
--IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name='Util') EXECUTE ('CREATE SCHEMA Util')
--GO

--IF OBJECT_ID('Util.Util_FKSearch', 'P') IS NOT NULL DROP PROCEDURE Util.Util_FKSearch
--GO

/*
*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
Util_FKSearch
By Jesse Roberge - YeshuaAgapao@Yahoo.com

Searches for actual and potental foreign key columns for a given primary key reference.
Generates code for creating, dropping, enabling, and disabling a FK constraint.
Also generates simple template code for merge and delete.
Also generates Util_FKSearch calls for the next lower dependency tiers.
@PKTable/@PKColumn must be a valid table/column combination or no data will be returned.
It doesn't check if @PKColumn is actually a member of a primary key or unique key constraint though.
It doesn't support composite keys, but if the one provided PK column is a member of a composite FK constraint,
	it will consider it as having a FK constraint declared on it.
Requires the VIEW DATABASE STATE database permission.

Update 2009-09-21:
	Added FindMode 0 to represent the PK table
	Added pre-built Util_FKSearch call for the next lower tier of possible referential dependencies.
	Added SimpleDelete, FKCreate, FKDrop, FKDisable, FKEnable code template output colunms

Required Input Parameters:
	@PKTable VarChar(250),			Table of the primary key reference
	@PKColumn VarChar(250),			Column of the primary key reference

Optional Input Parameters:
	@PKSchema VarChar(250)='dbo',	Schema of the primary key reference column's table
	@FKColumn VarChar(250)='',		If the FK columns might be named differently, provide this
	@MaxFindMethod int				How poor of a match level is permitted to be outputted

Usage:
	EXECUTE Util_FKSearch @PKTable='orders', @PKColumn='order_id'
	EXECUTE Util_FKSearch @PKSchema='dbo', @PKTable='orders', @PKColumn='order_id', @FKColumn='ORDERS_ORDER_ID'

Copyright:
	Licensed under the L-GPL - a weak copyleft license - you are permitted to use this as a component of a proprietary database and call this from proprietary software.
	Copyleft lets you do anything you want except plagiarize, conceal the source, or prohibit copying & re-distribution of this script/proc.

	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    see <http://www.fsf.org/licensing/licenses/lgpl.html> for the license text.

*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
*/

CREATE PROCEDURE Util.Util_FKSearch
	@PKTable VarChar(250),
	@PKColumn VarChar(250),
	@PKSchema VarChar(250)='dbo',
	@FKColumn VarChar(250)='',
	@MaxFindMethod int=8
AS

SELECT
	FKSearch.SchemaName, FKSearch.TableName, FKSearch.ColumnName
	,MAX(Rows) AS Rows, MAX(SizeMB) AS SizeMB
	,MIN(FKSearch.FindMethod) AS FindMethod
	, CASE MIN(FKSearch.FindMethod)
		WHEN 0 THEN 'The parameter-fed primary key table'
		WHEN 1 THEN 'Foreign key constraint declared on column'
		WHEN 2 THEN 'Column name matches FK naming convention'
		WHEN 3 THEN 'Identical column name to @PKColumn'
		WHEN 4 THEN 'Identical column name to @FKColumn'
		WHEN 5 THEN 'Column name begins/ends with @PKColumn'
		WHEN 6 THEN 'Column name begins/ends with @FKColumn'
		WHEN 7 THEN '@PKColumn in middle of column name'
		WHEN 8 THEN '@FKColumn in middle of column name'
	END AS FindMethodDesc
	,MAX(FKSearch.PKColumnName) AS PKColumnName
	,MAX(FKSearch.TypeMatch) AS TypeMatch, MAX(FKSearch.LengthMatch) AS LengthMatch
	,MAX(FKSearch.FKEnabled) AS FKEnabled, MAX(FKSearch.FKTrusted) AS FKTrusted
	,CASE WHEN MIN(FKSearch.FindMethod)=0 OR MAX(FKSearch.PKColumnName) IS NULL THEN NULL ELSE 'EXECUTE Util.Util_FKSearch @PKTable=''' + FKSearch.TableName + ''', @PKColumn=''' + MAX(FKSearch.PKColumnName) + ''', @PKSchema=''' + FKSearch.SchemaName + ''', @MaxFindMethod=' + CONVERT(VarChar(3), @MaxFindMethod) END AS FKSearchCall
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'ALTER TABLE ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' ADD CONSTRAINT ' + MAX(FKSearch.FKName) + ' FOREIGN KEY (' + FKSearch.ColumnName + ') REFERENCES ' + @PKSchema + '.' + @PKTable + ' (' + @PKColumn + ')' END AS FKCreate
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'ALTER TABLE ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' DROP CONSTRAINT ' + MAX(FKSearch.FKName) END AS FKDrop
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'ALTER TABLE ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' WITH CHECK CHECK CONSTRAINT ' + MAX(FKSearch.FKName) END AS FKEnable
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'ALTER TABLE ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' NOCHECK CONSTRAINT ' + MAX(FKSearch.FKName) END AS FKDisable
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'UPDATE ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' SET ' + FKSearch.ColumnName + '=@KeepID WHERE ' + FKSearch.ColumnName + '=@MergeID' END AS SimpleMergeUpdate
	,CASE WHEN MIN(FKSearch.FindMethod)=0 THEN NULL ELSE 'DELETE FROM ' + FKSearch.SchemaName + '.' + FKSearch.TableName + ' WHERE ' + FKSearch.ColumnName + '=@DeleteID' END AS SimpleDelete
FROM
	(
		--Check foriegn key constraints
			SELECT
				sysSchemasFK.name AS SchemaName, sysObjectsFK.name AS TableName,
				sysColumnsFK.name AS ColumnName,
				1-foreign_keys.is_disabled AS FKEnabled, 1-foreign_keys.is_not_trusted AS FKTrusted,
				CASE WHEN columns.user_type_id=columns.user_type_id THEN 1 ELSE 0 END AS TypeMatch,
				CASE WHEN columns.max_length=columns.max_length AND columns.precision=columns.precision AND columns.scale=columns.scale THEN 1 ELSE 0 END AS LengthMatch,
				1 AS FindMethod,
				partitions.Rows, partitions.SizeMB,
				columns_index.name AS PKColumnName,
				foreign_keys.name AS FKName
			FROM
				sys.objects
				JOIN (
					SELECT
						object_id, SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN row_count ELSE 0 END) AS Rows,
						CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(in_row_reserved_page_count+lob_reserved_page_count+row_overflow_reserved_page_count))/CONVERT(numeric(19,3), 128)) AS SizeMB
					FROM sys.dm_db_partition_stats
					WHERE dm_db_partition_stats.index_id BETWEEN 0 AND 1 --0=Heap; 1=Clustered; only 1 per table
					GROUP BY object_id
				) AS partitions ON objects.object_id=partitions.object_id
				JOIN sys.schemas ON objects.schema_id=schemas.schema_id
				JOIN sys.columns ON objects.object_id=columns.object_id
				JOIN sys.foreign_key_columns ON
					columns.object_id=foreign_key_columns.referenced_object_id
					AND columns.column_id=foreign_key_columns.referenced_column_id
				JOIN sys.foreign_keys ON foreign_key_columns.constraint_object_id=foreign_keys.object_id
				JOIN sys.columns AS sysColumnsFK ON
					foreign_key_columns.parent_object_id=sysColumnsFK.object_id
					AND foreign_key_columns.parent_column_id=sysColumnsFK.column_id
				JOIN sys.objects AS sysObjectsFK ON sysColumnsFK.object_id=sysObjectsFK.object_id
				JOIN sys.schemas AS sysSchemasFK ON sysObjectsFK.schema_id=sysSchemasFK.schema_id
				LEFT OUTER JOIN sys.indexes ON
					objects.object_id=indexes.object_id
					AND indexes.is_primary_key=1
				LEFT OUTER JOIN sys.index_columns ON
					indexes.object_id=index_columns.object_id
					AND indexes.index_id=index_columns.index_id
					AND index_columns.key_ordinal=1
				LEFT OUTER JOIN sys.columns AS columns_index ON
					index_columns.object_id=columns_index.object_id
					AND index_columns.column_id=columns_index.column_id
			WHERE
				schemas.name=@PKSchema AND objects.type='u'
				AND objects.name=@PKTable AND columns.name=@PKColumn
		--Check for column name matches
		UNION ALL
			SELECT
				schemas.name AS SchemaName, objects.name AS TableName,
				columns.name AS ColumnName,
				NULL AS FKEnabled, NULL AS FKTrusted,
				CASE WHEN PKTable.user_type_id=columns.user_type_id THEN 1 ELSE 0 END AS TypeMatch,
				CASE WHEN PKTable.max_length=columns.max_length AND PKTable.precision=columns.precision AND PKTable.scale=columns.scale THEN 1 ELSE 0 END AS LengthMatch,
				CASE
					WHEN schemas.name=@PKSchema AND objects.name=@PKTable THEN 0
					WHEN columns.name='FK_' + @PKTable + 'ID' THEN 2
					WHEN columns.name=@PKColumn THEN 3
					WHEN @FKColumn<>'' AND columns.name=@FKColumn THEN 4
					WHEN columns.name LIKE @PKColumn + '%' OR columns.name LIKE '%' + @PKColumn THEN 5
					WHEN @FKColumn<>'' AND (columns.name LIKE @FKColumn + '%' OR columns.name LIKE '%' + @FKColumn) THEN 6
					WHEN columns.name LIKE '%' + @PKColumn + '%' THEN 7
					WHEN @FKColumn<>'' THEN 8
				END AS FindMethod,
				partitions.Rows, partitions.SizeMB,
				columns_index.name AS PKColumnName,
				'FK__' + schemas.name + '_' + objects.name + '__' + @PKSchema + '_' + @PKTable + '__' + REPLACE(REPLACE(columns.name, 'PK_', ''), 'FK_', '') + '__' + REPLACE(REPLACE(@PKColumn, 'PK_', ''), 'FK_', '') AS FKName
			FROM
				(
					SELECT
						columns.user_type_id, columns.max_length,
						columns.precision, columns.scale
					FROM
						sys.objects
						JOIN sys.schemas ON objects.schema_id=schemas.schema_id
						JOIN sys.columns ON objects.object_id=columns.object_id
					WHERE
						schemas.name=@PKSchema AND objects.type='u'
						AND objects.name=@PKTable AND columns.name=@PKColumn
				) AS PKTable
				CROSS JOIN sys.objects
				JOIN (
					SELECT
						object_id, SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN row_count ELSE 0 END) AS Rows,
						CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(in_row_reserved_page_count+lob_reserved_page_count+row_overflow_reserved_page_count))/CONVERT(numeric(19,3), 128)) AS SizeMB
					FROM sys.dm_db_partition_stats
					WHERE dm_db_partition_stats.index_id BETWEEN 0 AND 1 --0=Heap; 1=Clustered; only 1 per table
					GROUP BY object_id
				) AS partitions ON objects.object_id=partitions.object_id
				JOIN sys.schemas ON objects.schema_id=schemas.schema_id
				JOIN sys.columns ON objects.object_id=columns.object_id
				LEFT OUTER JOIN sys.indexes ON
					objects.object_id=indexes.object_id
					AND indexes.is_primary_key=1
				LEFT OUTER JOIN sys.index_columns ON
					indexes.object_id=index_columns.object_id
					AND indexes.index_id=index_columns.index_id
					AND index_columns.key_ordinal=1
				LEFT OUTER JOIN sys.columns AS columns_index ON
					index_columns.object_id=columns_index.object_id
					AND index_columns.column_id=columns_index.column_id
			WHERE
				objects.type IN ('u','v')
				AND (
					columns.name='FK_' + @PKTable + 'ID'
					OR columns.name LIKE '%' + @PKColumn + '%' OR @FKColumn<>'' AND columns.name LIKE '%' + @FKColumn + '%'
				)
	) AS FKSearch
WHERE FKSearch.FindMethod<=@MaxFindMethod
GROUP BY FKSearch.TableName, FKSearch.SchemaName, FKSearch.ColumnName
ORDER BY
	MIN(FKSearch.FindMethod),
	MAX(FKSearch.TypeMatch) DESC, MAX(FKSearch.LengthMatch) DESC,
	MAX(FKSearch.FKEnabled) DESC, MAX(FKSearch.FKTrusted) DESC,
	FKSearch.SchemaName, FKSearch.TableName, FKSearch.ColumnName
GO
--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
