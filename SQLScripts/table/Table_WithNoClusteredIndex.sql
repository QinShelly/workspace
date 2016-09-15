SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_PADDING ON
GO

--Create Util schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name='Util') EXECUTE ('CREATE SCHEMA Util')
GO

IF OBJECT_ID('Util.Util_TablesWithoutPKOrCL', 'P') IS NOT NULL DROP PROCEDURE Util.Util_TablesWithoutPKOrCL
GO

/**
*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
Util_TablesWithoutPKOrCL
By Jesse Roberge - YeshuaAgapao@Yahoo.com

Lists Schema/Object of tables that are missing a Primary Key, missing a Clustered Index, or the clustered index is not declared as unique,
	along with aggregate data for size, rows, indexes, and columns.
Has the same output as Util_TableSearch Mk2 but only outputs tables that are missing a Primary Key or Clustered Index (or both) rather than performing a name pattern search.
Requires the VIEW DATABASE STATE database permission.

Update 2009-01-14:
	Fixed Rows Output - Was being erroneously multiplied by (1+#NonClusteredIndexes)
		SUM(Rows) Should be SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN row_count ELSE 0 END)

Update 2009-09-21:
	Added HasUniqueIndex, ClusteredIndexIsUnique, PrimaryKeyIsClustered, and NonPKUniqueIndexCount.

Required Input Parameters
	none

Optional Input Parameters
	none

Usage
	EXECUTE Util_TablesWithoutPKOrCL

Copyright:
	Licensed under the L-GPL - a weak copyleft license - you are permitted to use this as a component of a proprietary database and call this from proprietary software.
	Copyleft lets you do anything you want except plagarize, conceal the source, proprietarize modifications, or prohibit copying & re-distribution of this script/proc.

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
**/

--CREATE PROCEDURE Util.Util_TablesWithoutPKOrCL AS

SELECT
	schemas.schema_id, schemas.name AS schema_name,
	objects.object_id, objects.name AS object_name,
	objects.type, objects.type_desc,
	partitions.PartitionCount, partitions.Rows,
	partitions.SizeMB, partitions.SizeMBIndexes,
	indexes.NonClusteredIndexCount,
	columns.ColumnCount, columns.TotalMaxColumnLength,
	indexes.HasUniqueIndex, indexes.HasPrimarykey,
	indexes.HasClusteredIndex, CASE WHEN indexes.HasClusteredIndex=1 THEN indexes.ClusteredIndexIsUnique END AS ClusteredIndexIsUnique,
	CASE WHEN indexes.HasPrimarykey=1 AND indexes.HasClusteredIndex=1 THEN indexes.PrimaryKeyIsClustered END AS PrimaryKeyIsClustered,
	indexes.NonPKUniqueIndexCount
FROM
	sys.objects AS objects
	JOIN sys.schemas AS schemas ON objects.schema_id=schemas.schema_id
	--Space usage stats for the table
	JOIN (
		SELECT
			object_id, SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN row_count ELSE 0 END) AS Rows,
			CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN in_row_reserved_page_count+lob_reserved_page_count+row_overflow_reserved_page_count ELSE 0 END))/CONVERT(numeric(19,3), 128)) AS SizeMB,
			CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(CASE WHEN index_id>1 THEN in_row_reserved_page_count+lob_reserved_page_count+row_overflow_reserved_page_count ELSE 0 END))/CONVERT(numeric(19,3), 128)) AS SizeMBIndexes,
			SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN 1 ELSE 0 END) AS PartitionCount
		FROM sys.dm_db_partition_stats
		GROUP BY object_id
	) AS partitions ON objects.object_id=partitions.object_id
	--Get index flags
	JOIN (
		SELECT
			object_id,
			MAX(CONVERT(tinyint, is_primary_key)) AS HasPrimarykey,
			MAX(CONVERT(tinyint, is_unique)) AS HasUniqueIndex,
			SUM(CASE WHEN is_primary_key=1 THEN 0 ELSE CONVERT(tinyint, is_unique) END) AS NonPKUniqueIndexCount,
			SUM(CASE WHEN index_id=1 THEN 1 ELSE 0 END) AS HasClusteredIndex,
			SUM(CASE WHEN index_id=1 AND is_unique=1 THEN 1 ELSE 0 END) AS ClusteredIndexIsUnique,
			SUM(CASE WHEN index_id>1 THEN 1 ELSE 0 END) AS NonClusteredIndexCount,
			SUM(CASE WHEN index_id=1 AND is_primary_key=1 THEN 1 ELSE 0 END) AS PrimaryKeyIsClustered
		FROM sys.indexes
		GROUP BY object_id
	) AS indexes ON objects.object_id=indexes.object_id
	--Get column counts
	JOIN (
		SELECT
			object_id, COUNT(*) AS ColumnCount,
			SUM(max_length) AS TotalMaxColumnLength
		FROM sys.columns
		GROUP BY object_id
	) AS columns ON objects.object_id=columns.object_id
WHERE
	objects.type='U'
	AND (HasPrimarykey=0 OR HasUniqueIndex=0 OR HasClusteredIndex=0 OR ClusteredIndexIsUnique=0)
ORDER BY
	Indexes.HasUniqueIndex+Indexes.HasPrimarykey+Indexes.HasClusteredIndex+Indexes.ClusteredIndexIsUnique,
	Indexes.HasUniqueIndex, Indexes.HasPrimarykey, Indexes.HasClusteredIndex, Indexes.ClusteredIndexIsUnique, CASE WHEN Indexes.NonPKUniqueIndexCount>0 THEN 1 ELSE 0 END,
	schemas.name, objects.name
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
