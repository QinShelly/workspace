---------------------------------------------------------------------------
--Readme/usage Section
---------------------------------------------------------------------------
--It usually troublesome for us to create a table which is same to another table with regards to index, constraint, compression,etc.
--This script provide you a quick way to do so. The usage is listed below:
--(1) Run this whole script using Management Studio on the database
--(2) Create a clone table, for example: 
--       EXEC SP$RSI_CLONE_TABLE 'dbo', 'RSI_FACT_PIVOT_ULEVERWALMRT','dbo','RSI_FACT_PIVOT_TEMP_WM',1
--    Please replace RSI_FACT_PIVOT_ULEVERWALMRT with source table name, replace RSI_FACT_PIVOT_TEMP_WM with clone table name (any name you like) 

---------------------------------------------------------------------------
--Create Script Section
---------------------------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP$RSI_MOVE_PERIOD_KEY]') AND type in (N'P', N'PC'))
DROP PROCEDURE dbo.[SP$RSI_MOVE_PERIOD_KEY]
GO

CREATE PROCEDURE [dbo].[SP$RSI_MOVE_PERIOD_KEY]
    @pvs_SourceTable nvarchar(255),
    @pvs_DestinationTable nvarchar(255),
    @pvs_PeriodKey nvarchar(255)
AS
BEGIN
	DECLARE @lvs_PartitionNumber nvarchar(255), @lvs_sql NVARCHAR(MAX)
	SELECT @lvs_PartitionNumber = $partition.F$RSI_CORE_POSRANGEPF(CONVERT(INT, @pvs_PeriodKey))
	
	SET  @lvs_sql = 'ALTER TABLE  ' + @pvs_SourceTable + ' SWITCH PARTITION ' + @lvs_PartitionNumber + ' TO ' 
	+ @pvs_DestinationTable + ' PARTITION ' + @lvs_PartitionNumber
	
	EXECUTE(@lvs_sql)
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP$RSI_CLONE_TABLE]') AND type in (N'P', N'PC'))
DROP PROCEDURE dbo.[SP$RSI_CLONE_TABLE]
GO

CREATE PROCEDURE [dbo].[SP$RSI_CLONE_TABLE]
    @pvs_SourceSchema nvarchar(255),
    @pvs_SourceTable nvarchar(255),
    @pvs_DestinationSchema nvarchar(255),
    @pvs_DestinationTable nvarchar(255),
    @pvb_RecreateIfExists bit = 0
AS
BEGIN
/*
 ===========================================================================================================================
 Author:				Peter Nie
 Create date:			20130322
 Description:			Add the following besides "SELECT INTO ": PRIMARY KEY, INDEX,
						CLUSTERED_INDEX, UNIQUE/INCLUDE INDEX, constraint, compression, partition		
 ============================================================================================================================
 */
	BEGIN TRY
		SET NOCOUNT ON;
		DECLARE @lvs_PartitionScheme nvarchar(255)
		DECLARE @lvs_PartitionKey nvarchar(255)
	    
		BEGIN TRANSACTION
	    
		SELECT  @lvs_PartitionScheme = ps.name 
		FROM sys.TABLES t
			 JOIN sys.indexes i ON t.object_id = i.object_id
			 JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
			 JOIN sys.schemas s ON t.schema_id = s.schema_id
		WHERE s.name =  @pvs_SourceSchema AND t.name = @pvs_SourceTable 
		
	     
		SELECT @lvs_PartitionKey = c.name 
		FROM sys.tables t
			JOIN sys.indexes i ON(i.object_id = t.object_id AND i.index_id < 2) 
			JOIN sys.index_columns ic ON(ic.partition_ordinal > 0 AND ic.index_id = i.index_id and ic.object_id = t.object_id)
			JOIN sys.columns c ON(c.object_id = ic.object_id AND c.column_id = ic.column_id)
		 WHERE t.object_id = object_id(@pvs_SourceSchema + '.' + @pvs_SourceTable)     	
	     
		--drop the table
		if EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @pvs_DestinationSchema AND TABLE_NAME = @pvs_DestinationTable)
		BEGIN
			if @pvb_RecreateIfExists = 1
			BEGIN
				exec('DROP TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + ']')
			END
			ELSE
				RETURN
		END

		--create the table
		exec('SELECT TOP (0) * INTO [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] FROM [' + @pvs_SourceSchema + '].[' + @pvs_SourceTable + ']')

		DECLARE @lvs_PKSchema nvarchar(255), @lvs_PKName nvarchar(255)
		SELECT TOP 1 @lvs_PKSchema = CONSTRAINT_SCHEMA, @lvs_PKName = CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = @pvs_SourceSchema AND TABLE_NAME = @pvs_SourceTable AND CONSTRAINT_TYPE = 'PRIMARY KEY'

		--create primary key
		IF NOT @lvs_PKSchema IS NULL AND NOT @lvs_PKName IS NULL
		BEGIN
			DECLARE @lvs_PKColumns nvarchar(MAX)
			SET @lvs_PKColumns = ''

			SELECT @lvs_PKColumns = @lvs_PKColumns + '[' + COLUMN_NAME + '],'
				FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
				WHERE TABLE_NAME = @pvs_SourceTable and TABLE_SCHEMA = @pvs_SourceSchema AND CONSTRAINT_SCHEMA = @lvs_PKSchema AND CONSTRAINT_NAME= @lvs_PKName
				ORDER BY ORDINAL_POSITION

			SET @lvs_PKColumns = LEFT(@lvs_PKColumns, LEN(@lvs_PKColumns) - 1)

			exec('ALTER TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] ADD  CONSTRAINT [PK_' + @pvs_DestinationTable + '] PRIMARY KEY CLUSTERED (' + @lvs_PKColumns + ')  ON ' + @lvs_PartitionScheme +'(' + @lvs_PartitionKey + ')');
		END

		--create other indexes
		DECLARE @lvn_IndexId int, @lvs_IndexName nvarchar(255), @lvb_IsUnique bit, @lvb_IsUniqueConstraint bit, @lvs_FilterDefinition nvarchar(max)
		,@lvb_IsCluster bit

		DECLARE cur_indexcursor CURSOR FOR
		SELECT index_id, name, is_unique, is_unique_constraint, filter_definition FROM sys.indexes WHERE type IN (1,2) and object_id = object_id('[' + @pvs_SourceSchema + '].[' + @pvs_SourceTable + ']')
		OPEN cur_indexcursor;
		FETCH NEXT FROM cur_indexcursor INTO @lvn_IndexId, @lvs_IndexName, @lvb_IsUnique, @lvb_IsUniqueConstraint, @lvs_FilterDefinition;
		WHILE @@FETCH_STATUS = 0
		   BEGIN
				DECLARE @lvs_Unique nvarchar(255)
				SET @lvs_Unique = CASE WHEN @lvb_IsUnique = 1 THEN ' UNIQUE ' ELSE '' END
				IF @lvn_IndexId = 1 SET @lvb_IsCluster = 1

				DECLARE @lvs_KeyColumns nvarchar(max), @lvs_IncludedColumns nvarchar(max)
				SET @lvs_KeyColumns = ''
				SET @lvs_IncludedColumns = ''

				select @lvs_KeyColumns = @lvs_KeyColumns + '[' + c.name + '] ' + CASE WHEN is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END + ',' FROM sys.index_columns ic
				inner JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
				WHERE index_id = @lvn_IndexId and ic.object_id = object_id('[' + @pvs_SourceSchema + '].[' + @pvs_SourceTable + ']') and key_ordinal > 0
				order by index_column_id

				select @lvs_IncludedColumns = @lvs_IncludedColumns + '[' + c.name + '],' FROM sys.index_columns ic
				inner JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
				WHERE index_id = @lvn_IndexId and ic.object_id = object_id('[' + @pvs_SourceSchema + '].[' + @pvs_SourceTable + ']') and key_ordinal = 0
				order by index_column_id

				IF LEN(@lvs_KeyColumns) > 0
					SET @lvs_KeyColumns = LEFT(@lvs_KeyColumns, LEN(@lvs_KeyColumns) - 1)

				IF LEN(@lvs_IncludedColumns) > 0
				BEGIN
					SET @lvs_IncludedColumns = ' INCLUDE (' + LEFT(@lvs_IncludedColumns, LEN(@lvs_IncludedColumns) - 1) + ')'
				END

				IF @lvs_FilterDefinition IS NULL
					SET @lvs_FilterDefinition = ''
				ELSE
					SET @lvs_FilterDefinition = 'WHERE ' + @lvs_FilterDefinition + ' '

				IF @lvb_IsUniqueConstraint = 0
					IF(@lvb_IsCluster <> 1)
						exec('CREATE ' + @lvs_Unique + ' NONCLUSTERED INDEX [' + @lvs_IndexName + '] ON [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] (' + @lvs_KeyColumns + ')' + @lvs_IncludedColumns + @lvs_FilterDefinition)
					ELSE
						exec('CREATE ' + @lvs_Unique + ' CLUSTERED INDEX [' + @lvs_IndexName + '] ON [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] (' + @lvs_KeyColumns + ')' + @lvs_IncludedColumns + @lvs_FilterDefinition 
							+ ' ON ' + @lvs_PartitionScheme +'(' + @lvs_PartitionKey + ')');
				ELSE
					BEGIN
						SET @lvs_IndexName = REPLACE(@lvs_IndexName, @pvs_SourceTable, @pvs_DestinationTable)
						exec('ALTER TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] ADD  CONSTRAINT [' + @lvs_IndexName + '] UNIQUE NONCLUSTERED (' + @lvs_KeyColumns + ')');
					END

				FETCH NEXT FROM cur_indexcursor INTO @lvn_IndexId, @lvs_IndexName, @lvb_IsUnique, @lvb_IsUniqueConstraint, @lvs_FilterDefinition;
		   END;
		CLOSE cur_indexcursor;
		DEALLOCATE cur_indexcursor;

		--create constraints
		DECLARE @lvs_ConstraintName nvarchar(max), @lvs_CheckClauseme nvarchar(max)
		DECLARE cur_constraintcursor CURSOR FOR
			SELECT (c.CONSTRAINT_NAME+'1') AS CONSTRAINT_NAME, CHECK_CLAUSE FROM INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE t
			INNER JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS c ON c.CONSTRAINT_SCHEMA = TABLE_SCHEMA AND c.CONSTRAINT_NAME = t.CONSTRAINT_NAME
			 WHERE TABLE_SCHEMA = @pvs_SourceSchema AND TABLE_NAME = @pvs_SourceTable
		OPEN cur_constraintcursor;
		FETCH NEXT FROM cur_constraintcursor INTO @lvs_ConstraintName, @lvs_CheckClauseme;
		WHILE @@FETCH_STATUS = 0
		   BEGIN
				exec('ALTER TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] WITH NOCHECK ADD  CONSTRAINT [' + @lvs_ConstraintName + '] CHECK ' + @lvs_CheckClauseme)
				exec('ALTER TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + '] CHECK CONSTRAINT [' + @lvs_ConstraintName + ']')
				FETCH NEXT FROM cur_constraintcursor INTO @lvs_ConstraintName, @lvs_CheckClauseme;
		   END;
		CLOSE cur_constraintcursor;
		DEALLOCATE cur_constraintcursor;
	    
		--Create compression
		DECLARE @lvn_pNo INT, @lvn_objid INT, @lvs_compress NVARCHAR(20), @lvs_sql NVARCHAR(MAX)
		SELECT @lvn_objid = object_id(@pvs_SourceSchema +'.'+ @pvs_SourceTable)
		SELECT @lvn_pNo = MAX(partition_number) FROM sys.partitions  WHERE object_id = @lvn_objid

		-- Compression status
		SET @lvs_compress = (SELECT TOP 1 data_compression_desc FROM sys.partitions WHERE object_id = @lvn_objid and partition_number = @lvn_pNo)
		SET @lvs_sql = 'ALTER TABLE [' + @pvs_DestinationSchema + '].[' + @pvs_DestinationTable + ']  REBUILD PARTITION = ALL with (DATA_COMPRESSION = ' + @lvs_compress + ')';
		EXECUTE(@lvs_sql);

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		DECLARE
			@lvs_err_msg	NVARCHAR(4000),
			@lvn_err_sev	INT,
			@lvn_err_state	INT,
			@lvs_log    NVARCHAR(4000) = 'LOG:'

		SELECT 
			@lvs_err_msg = ERROR_MESSAGE(),
			@lvn_err_sev = ERROR_SEVERITY(),
			@lvn_err_state = ERROR_STATE();
			
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION;
		
		RAISERROR ( @lvs_err_msg, @lvn_err_sev, @lvn_err_state ); 
		
	END CATCH	

    
END
