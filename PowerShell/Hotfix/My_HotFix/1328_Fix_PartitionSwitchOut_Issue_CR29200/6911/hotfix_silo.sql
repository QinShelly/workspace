Alter PROCEDURE SP$RSI_UPD_PARTITION_FUNCTION (@update AS NVARCHAR(1), @callPre AS NVARCHAR(1) = 'Y')
AS
BEGIN
	-- Update partitions of pre fact tables
	if UPPER(@callPre) = 'Y'
	begin
		print 'call SP$RSI_UPD_PRE_PARTITION_FUNCTION ' + @update
		exec SP$RSI_UPD_PRE_PARTITION_FUNCTION @update
	end	
	
	DECLARE @PERIOD_KEYs AS VARCHAR(MAX)
	DECLARE @StartDate DATETIME
	DECLARE @EndDate DATETIME
	
	EXEC [dbo].[SP$RSI_GET_FACT_PARTITION_DATE_RANGE] @StartDate OUTPUT,@EndDate OUTPUT
	
	DECLARE @CurrMinInt AS INT
	DECLARE @CurrMaxInt AS INT
	SELECT @CurrMaxInt = MAX(CONVERT(INT, value))
			, @CurrMinInt = MIN(CONVERT(INT, value))
		FROM
			sys.partition_range_values
		WHERE function_id = (SELECT function_id FROM sys.partition_functions WHERE name = N'F$RSI_CORE_POSRANGEPF');

	IF (@CurrMaxInt IS NULL)
		SET @update = 'n'

	DECLARE @sql AS VARCHAR(MAX)

	IF (@update IS NULL OR @update = 'y')
	BEGIN -- Update partition function
		DECLARE @CurrMin AS DATETIME
		DECLARE @CurrMax AS DATETIME
		SET @CurrMin = CONVERT(DATETIME, CONVERT(NVARCHAR(8), @CurrMinInt), 112);
		SET @CurrMax = CONVERT(DATETIME, CONVERT(NVARCHAR(8), @CurrMaxInt), 112);
		DECLARE @dayIdx AS DATETIME
		
		DECLARE  @invalidDates table (date datetime)
		declare @remove int
		
		set @remove = 0
			
		if @CurrMin < @StartDate
		begin
			set @dayIdx = @CurrMin
			while @dayIdx < @StartDate
			begin
				insert into @invalidDates(date) values(@dayIdx)
				set @dayIdx = @dayIdx + 1
			end	
			set @remove = 1	
		end
		
		if @CurrMax > @EndDate 
		begin
			set @dayIdx = @CurrMax
			while @dayIdx > @EndDate
			begin
				insert into @invalidDates(date) values(@dayIdx)
				set @dayIdx = @dayIdx - 1
			end	
			set @remove = 1	
		end
		
		IF @remove = 1
		BEGIN
			-- Purge old parition data
			DECLARE @tableName varchar(100);
			DECLARE rsiptn cursor for
			SELECT distinct OBJECT_NAME(p.object_id) AS table_name 
			FROM sys.partitions AS p INNER JOIN sys.indexes AS i 
			ON p.object_id = i.object_id AND p.index_id = i.index_id 
			INNER JOIN sys.partition_schemes ps 
			ON i.data_space_id=ps.data_space_id 
			where ps.name <> 'PrePOSDatePScheme'
			and ps.name not in (select name from sys.partition_schemes where name like '%week%');
						
			OPEN rsiptn
			FETCH NEXT FROM rsiptn into @tableName
			WHILE @@FETCH_STATUS = 0 
			BEGIN
				print 'upd ' + @tableName + ' partitions'
				-- Drop and create temp table
				IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RSI_TEMPTBL4PU]') AND type in (N'U'))
				DROP TABLE [dbo].[RSI_TEMPTBL4PU]
				
				SET @sql = 'SELECT * INTO RSI_TEMPTBL4PU FROM ' + @tableName + ' WHERE 1 = 2';
				EXECUTE(@sql);
				
				DECLARE @objid INT
				SELECT  @objid = object_id FROM sys.all_objects WHERE object_id = OBJECT_ID(@tableName) ;

				DECLARE
					@indid SMALLINT ,
					@groupid INT ,
					@indname SYSNAME ,
					@groupname SYSNAME ,
					@status INT ,
					@keys NVARCHAR(2126) ,
					@dbname SYSNAME ,
					@ignore_dup_key BIT ,
					@is_unique BIT ,
					@is_hypothetical BIT ,
					@is_primary_key BIT ,
					@is_unique_key BIT ,
					@auto_created BIT ,
					@no_recompute BIT
				
				DECLARE @temp_name1 NVARCHAR(76) ;
				DECLARE @pri NVARCHAR(76) ;
				DECLARE @clu NVARCHAR(76) ;
				DECLARE @uni NVARCHAR(76) ;
				DECLARE @CreateTempIndex VARCHAR(8000) ;

				--SELECT  @indid = i.index_id ,
				--	@groupid = i.data_space_id ,
				--	@indname = i.name ,
				--	@ignore_dup_key = i.ignore_dup_key ,
				--	@is_unique = i.is_unique ,
				--	@is_hypothetical = i.is_hypothetical ,
				--	@is_primary_key = i.is_primary_key ,
				--	@is_unique_key = i.is_unique_constraint ,
				--	@auto_created = s.auto_created ,
				--	@no_recompute = s.no_recompute
				--FROM sys.indexes i
				--JOIN sys.stats s 
				--ON i.object_id = s.object_id
				--	AND i.index_id = s.stats_id
				--WHERE i.object_id = @objid and i.type = 1 -- Only clustered
				
				--Filtering out weekly partition schema
				SELECT @indid = i.index_id,@groupid = i.data_space_id ,
					@indname = i.name ,
					@ignore_dup_key = i.ignore_dup_key ,
					@is_unique = i.is_unique ,
					@is_hypothetical = i.is_hypothetical ,
					@is_primary_key = i.is_primary_key ,
					@is_unique_key = i.is_unique_constraint
				FROM sys.indexes i 
				JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
				JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
				where i.object_id = @objid and i.type =1
				AND pf.name NOT IN (SELECT name FROM sys.partition_functions WHERE name LIKE '%week%')
				


				DECLARE 
					@ii INT ,
					@thiskey NVARCHAR(131)-- 128+3

				SELECT @temp_name1 = @indname ,
					@pri = CONVERT(VARCHAR(210), CASE WHEN @is_primary_key <> 0 THEN 'primary key ' ELSE '' END) ,
					@uni = CONVERT(VARCHAR(210), CASE WHEN @is_unique <> 0 THEN 'unique ' ELSE '' END) ,
					@clu = 'clustered '
	                                     
				IF NOT ( @pri = '' )
					SET @uni = '' ;
		
				SELECT @keys = INDEX_COL(@tablename, @indid, 1), @ii = 2
				
				IF ( INDEXKEY_PROPERTY(@objid, @indid, 1, 'isdescending') = 1 ) 
					SELECT @keys = '[' + @keys + ']' + ' DEC'
				ELSE 
					SELECT @keys = '[' + @keys + ']' + ' ASC'

				SELECT @CreateTempIndex = 'ALTER TABLE RSI_TEMPTBL4PU'
					+ ' ADD  CONSTRAINT [TEMP_' + @temp_name1 + '] ' + @uni + @pri
					+ @clu + '(' + @keys ;
	    
				SELECT @thiskey = INDEX_COL(@tablename, @indid, @ii)
				IF ((@thiskey IS NOT NULL) AND (INDEXKEY_PROPERTY(@objid, @indid, @ii, 'isdescending') = 1)) 
					SELECT @thiskey = '[' + @thiskey + ']' + ' DEC';
				ELSE 
					SELECT  @thiskey = '[' + @thiskey + ']' + ' ASC';
			
				SELECT  @CreateTempIndex = @CreateTempIndex + ',' + @thiskey ;

				WHILE ( @thiskey IS NOT NULL ) 
				BEGIN
					SELECT @ii = @ii + 1
					SELECT @thiskey = INDEX_COL(@tablename, @indid, @ii)
					IF ((@thiskey IS NOT NULL) AND (INDEXKEY_PROPERTY(@objid, @indid, @ii, 'isdescending') = 1)) 
						SELECT @thiskey = '[' + @thiskey + ']' + ' DEC'
					ELSE 
						SELECT @thiskey = '[' + @thiskey + ']' + ' ASC'
					
					IF ( @thiskey IS NOT NULL ) 
						SELECT  @CreateTempIndex = @CreateTempIndex + ',' + @thiskey ;
				END

				SELECT  @CreateTempIndex = @CreateTempIndex + ')' ;
				-- Create index for temp table
				EXECUTE(@CreateTempIndex);
				
				-- Compression status
				DECLARE @compress VARCHAR(128)
				SET @compress = (
					SELECT TOP 1 data_compression_desc 
					FROM sys.partitions a
					JOIN sys.indexes b
					on a.object_id = b.object_id AND a.index_id=b.index_id
					WHERE a.object_id = @objid and b.type = 1
					ORDER BY a.partition_number
				)
				SET @sql = 'ALTER TABLE RSI_TEMPTBL4PU REBUILD PARTITION = ALL with (DATA_COMPRESSION = ' + @compress + ')';
				EXECUTE(@sql);
				
				-- Switch old partitions out
				DECLARE @pNo AS INT
				DECLARE @rowcount AS INT
				
				DECLARE date_cur cursor for
				SELECT date from @invalidDates
				OPEN date_cur
				FETCH NEXT FROM date_cur into @dayIdx
				WHILE @@FETCH_STATUS = 0 
				BEGIN
					SET @pNo = $partition.F$RSI_CORE_POSRANGEPF(CONVERT(NVARCHAR, @dayIdx, 112));
					SET @rowcount = (SELECT MAX(rows) FROM sys.partitions WHERE object_id = @objid AND partition_number = @pNo);
					IF (@rowcount > 0)
					BEGIN
						--To switch out successfully, the partition's compression for temp table has to be same to the #pNo one of current fact table
						DECLARE @compress_MainTable VARCHAR(128),
								@compress_TempTable VARCHAR(128)
						SELECT TOP 1 @compress_MainTable = data_compression_desc
						FROM   sys.partitions
						WHERE  object_id = Object_id(@tablename, 'u')
							   AND partition_number = @pNo
						SELECT TOP 1 @compress_TempTable = data_compression_desc
						FROM   sys.partitions AS par
						WHERE  object_id = Object_id('RSI_TEMPTBL4PU', 'u')
						IF( @compress_TempTable <> @compress_MainTable )
						  BEGIN
							  SET @sql = 'ALTER TABLE RSI_TEMPTBL4PU REBUILD PARTITION = ALL with (DATA_COMPRESSION = '
										 + @compress_MainTable + ')';
							  EXEC (@sql)
						  END
						
						-- Switch partition out
						SET @sql = 'ALTER TABLE ' + @tablename + ' SWITCH PARTITION '
							+ CONVERT(VARCHAR, @pNo) + ' TO RSI_TEMPTBL4PU';
						--print @sql	
						EXECUTE(@sql);
						-- Truncate data				
						TRUNCATE TABLE RSI_TEMPTBL4PU
					END
					FETCH NEXT FROM date_cur into @dayIdx
				END
				close date_cur
				DEALLOCATE date_cur
				
				FETCH NEXT FROM rsiptn into @tableName;
			END		
			CLOSE rsiptn		
			DEALLOCATE rsiptn
		END
		
		declare @nbDayIdx as datetime
		declare @neDayIdx as datetime
		
		if @CurrMin <= @EndDate
			set @nbDayIdx = @CurrMin - 1
		else
			set @nbDayIdx = @EndDate	
			
		if @CurrMax >= @StartDate
			set @neDayIdx = @CurrMax + 1
		else
			set @neDayIdx = @StartDate		
		
		-- Create 1 new partitions to the beginning
		SET @dayIdx = @nbDayIdx
		IF(@dayIdx >= @StartDate)
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() SPLIT RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			ALTER PARTITION SCHEME POSDatePScheme NEXT USED [PRIMARY];
			EXECUTE (@sql);
		END
		
		-- Create 1 new partitions to the end
		SET @dayIdx = @neDayIdx
		IF(@dayIdx <= @EndDate)
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() SPLIT RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			ALTER PARTITION SCHEME POSDatePScheme NEXT USED [PRIMARY];
			EXECUTE (@sql);
		END
		
		-- Merge old beginning partitions
		SET @dayIdx = @CurrMin
		WHILE (@dayIdx <= @CurrMax) and (@dayIdx < @StartDate) 
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() MERGE RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			EXECUTE (@sql);
			SET @dayIdx = @dayIdx + 1
		END
		
		-- Merge old end partitions
		SET @dayIdx = @CurrMax
		WHILE (@dayIdx >= @CurrMin) and (@dayIdx > @EndDate)
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() MERGE RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			EXECUTE (@sql);
			SET @dayIdx = @dayIdx - 1
		END

		-- Append new partitions to the beginning of needed
		SET @dayIdx = @nbDayIdx - 1
		WHILE @dayIdx >= @StartDate
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() SPLIT RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			ALTER PARTITION SCHEME POSDatePScheme NEXT USED [PRIMARY];
			EXECUTE (@sql);
			SET @dayIdx = @dayIdx - 1
		END
		
		-- Create new partitions to the end
		SET @dayIdx = @neDayIdx + 1
		WHILE @dayIdx <= @EndDate
		BEGIN
			SET @sql = 'ALTER PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF]() SPLIT RANGE (' + CONVERT(NVARCHAR, @dayIdx, 112) + ')';
			ALTER PARTITION SCHEME POSDatePScheme NEXT USED [PRIMARY];
			EXECUTE (@sql);
			SET @dayIdx = @dayIdx + 1
		END
	END
	ELSE
	BEGIN -- Create partition function
		DECLARE @i as INT
		DECLARE @StartDateStr varchar(8)
		DECLARE @DateLen INT
		
		set @StartDateStr = CONVERT(VARCHAR, @StartDate, 112);
		set @DateLen = DATEDIFF(DAY, @StartDate, @EndDate);
		
		set @i = 1
		SET @PERIOD_KEYs = @StartDateStr
		WHILE @i <= @DateLen
		BEGIN
			SELECT @PERIOD_KEYs = @PERIOD_KEYs + ',' + CONVERT(VARCHAR, DATEADD(DAY, @i, @StartDate), 112)
			SET @i = @i + 1
		END

		IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'F$RSI_CORE_POSRANGEPF')
		DROP PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF];

		SET @sql = 'CREATE PARTITION FUNCTION [F$RSI_CORE_POSRANGEPF](int) AS RANGE RIGHT FOR VALUES(' + @PERIOD_KEYs + ')';
		SELECT @sql
		EXECUTE (@sql);
	END
END
