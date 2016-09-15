	-- declare memory table

	DECLARE @INDEX_TABLE TABLE(
		primary_key INT IDENTITY(1,1) NOT NULL, 
		schema_name NVARCHAR(100), 
		table_name NVARCHAR(100), 
		column_name NVARCHAR(100),
		new_index_name NVARCHAR(100)
	)

	
	-- feed memory table by all foreign key without index in database
	INSERT INTO @INDEX_TABLE
		SELECT
			S.name as [Schema name],
			object_name(T.object_id) AS [Table name],
			C.name AS [Column name],
			''
		FROM 
			sys.columns C
			LEFT JOIN sys.tables T ON (C.object_id = T.object_id)
			LEFT JOIN sys.schemas S ON (S.schema_id = T.schema_id)
			LEFT JOIN sys.foreign_key_columns FKC ON (FKC.parent_object_id = C.object_id AND C.column_id = FKC.parent_column_id)
			LEFT JOIN sys.foreign_keys FK ON (FKC.constraint_object_id = FK.object_id)

			LEFT JOIN sys.index_columns IC ON (IC.object_id = C.object_id AND IC.column_id = C.column_id)	
			LEFT JOIN sys.indexes I ON (I.index_id = IC.index_id  AND I.object_id = C.object_id)
		WHERE 
			T.object_id is not null
			AND FK.name IS NOT NULL
			AND I.name IS NULL
		ORDER BY 
			S.name,
			object_name(T.object_id),
			C.name 



	DECLARE @loop_counter INT
	DECLARE @item_counter INT

	SET @loop_counter = ISNULL((SELECT COUNT(*) FROM @INDEX_TABLE),0)
	SET @item_counter = 1

	DECLARE @schema_name VARCHAR(100)
	DECLARE @table_name VARCHAR(100)
	DECLARE @column_name VARCHAR(100)
	DECLARE @query NVARCHAR(1000)
	DECLARE @index_name VARCHAR(200)

	WHILE @loop_counter > 0 AND @item_counter <= @loop_counter
	BEGIN
			
		-- get one row from memory table
			SELECT 
				@schema_name = schema_name, 
				@table_name = table_name,
				@column_name = column_name
			FROM 
				@INDEX_TABLE
			WHERE 
				primary_key = @item_counter

		
	-- prepare query
	SET @index_name = 'IX_' + @table_name + '_' + @column_name
	SET @query = 'CREATE NONCLUSTERED INDEX [' + @index_name + '] ON ['+ @schema_name+ '].[' + @table_name + '] 
		(
			[' + @column_name + '] ASC
		) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
		'
	
	EXEC sp_executesql @query

	UPDATE @INDEX_TABLE 
	SET 
		new_index_name = @index_name
	WHERE 
		primary_key = @item_counter

		SET @item_counter =  @item_counter + 1
	END

	-- present all FKey's with new index
	SELECT 
		schema_name, 
		table_name, 
		column_name,
		new_index_name
	FROM 
		@INDEX_TABLE
