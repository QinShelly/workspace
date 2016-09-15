CREATE Procedure USP_MergerStatementGenerator
    @SourceDB as varchar(MAX),
    @TargetDB as varchar(MAX) = @SourceDB,
    @SourceTableName as varchar(MAX),
    @TargetTableName as varchar(MAX)
AS
BEGIN

  -- Written by Mitch Spruill 
  -- 9/11/11
  -- Assumptions
    -- Uses the default .dbo. schema
    -- The names of the columns are the same in both tables.
    -- There is an identity column or a primary key
  
  declare @Tables TABLE(TableName varchar(MAX))
  declare @Columns TABLE(ColId int, ColumnName varchar(MAX))
  declare @ColumnList varchar(MAX)
  declare @UnequalList varchar(MAX)
  declare @EqualList varchar(MAX)
  declare @InsertList varchar(MAX)
  declare @SQL as nvarchar(MAX)
  declare @IdCol as TABLE(IdCol varchar(100))
  declare @SID as varchar(100)
  declare @MatchColumns as TABLE(ColumnName varchar(100))
  declare @MatchOnList as varchar(MAX)
  
  SET nocount on
  
  -- init working table
  DELETE from @Columns
  
  -- get list of columns in the table. Exclude the timestamp column
  SET @SQL = 'SELECT ORDINAL_POSITION,COLUMN_NAME From ' + @SourceDB + '.' + 'INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''' + @SourceTableName + ''' and DATA_TYPE != ''Timestamp'' order by ORDINAL_POSITION'
  INSERT @Columns EXECUTE (@SQL)

  -- get the table identity column to link the source to the target
  DELETE @IdCol
  SET @SQL = 'SELECT COLUMN_NAME From ' + @SourceDB + '.' + 'INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''' + @SourceTableName + ''' and columnproperty(object_id(table_name), column_name,''IsIdentity'') = 1';
  
  delete @MatchColumns
  insert @MatchColumns EXECUTE (@SQL)
  SET @MatchOnList = null
  SELECT @MatchOnList='T.' + ColumnName + ' = S.' + ColumnName from @MatchColumns

  -- if there is an identity column use it, but if not then look for primary keys
  if (@MatchOnList is null)
    begin
      SET @SQL = 'SELECT u.column_name FROM information_schema.key_column_usage u inner join INFORMATION_SCHEMA.TABLE_CONSTRAINTS c on c.CONSTRAINT_NAME = u.CONSTRAINT_NAME WHERE c.TABLE_NAME = ''' + @SourceTableName + '''and c.CONSTRAINT_TYPE=''Primary Key'' order by u.ORDINAL_POSITION'
      insert @MatchColumns EXECUTE (@SQL)
      SELECT @MatchOnList = coalesce(@MatchOnList + ' AND T.[' + ColumnName +'] = S.[' + ColumnName +']' , 'T.[' + ColumnName +'] = S.[' + ColumnName +']') FROM @MatchColumns 
      
      if (@MatchOnList is null)
      begin
        SET @MatchOnList='T.<TargetColumnName> = S.<SourceColumnName>'
      end
    end
  
  -- coalesce the columns
  SET @ColumnList = null
  SELECT @ColumnList = coalesce(@ColumnList + ', [' + ColumnName +']', '[' + ColumnName + ']') FROM @Columns order by ColId

  -- coalesce the unequal columns (used to locate changes)
  SET @UnequalList = null
  SELECT @UnequalList = coalesce(@UnequalList + ' or T.[' + c.ColumnName +'] != S.[' + c.ColumnName +']', 'T.[' + c.ColumnName +'] != S.[' + c.ColumnName +']') FROM @Columns c left outer join @IdCol i on c.ColumnName=i.IdCol where i.IdCol is null

  -- coalesce the equal columns (used to update the target)
  SET @EqualList = null
  SELECT @EqualList = coalesce(@EqualList + ', T.[' + c.ColumnName +'] = S.[' + c.ColumnName +']', 'T.[' + c.ColumnName +'] = S.[' + c.ColumnName +']') FROM @Columns c left outer join @IdCol i on c.ColumnName=i.IdCol where i.IdCol is null

  -- coalesce the insert columns (used to insert the target)
  SET @InsertList = null
  SELECT @InsertList = coalesce(@InsertList + ', S.[' + ColumnName +']', 'S.[' + ColumnName +']') FROM @Columns

  -- now output the statement
  PRINT 'SET IDENTITY_INSERT ' + @TargetDB + '.[dbo].[' + @TargetTableName + '] ON'  
  PRINT ''
  PRINT 'MERGE INTO ' + @TargetDB + '.[dbo].[' + @TargetTableName + '] as T'
  PRINT 'USING ' + @SourceDB + '.[dbo].[' + @SourceTableName + '] as S'
  PRINT 'ON ' + @MatchOnList
  PRINT ' WHEN MATCHED AND ' + @UnequalList
  PRINT ' THEN UPDATE SET ' + @EqualList
  PRINT ' WHEN NOT MATCHED BY TARGET'
  PRINT ' THEN INSERT (' + @ColumnList + ')'
  PRINT ' VALUES (' + @InsertList + ')'
  PRINT ' WHEN NOT MATCHED BY SOURCE'
  PRINT ' THEN DELETE;'
  PRINT ''
  PRINT 'SET IDENTITY_INSERT ' + @TargetDB + '.[dbo].[' + @TargetTableName + '] OFF'  

  SET nocount off

END
