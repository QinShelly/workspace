-- Generate Column Profiling Queries 
-------------------------------------------------------------------------------------
--USE AdventureWorksDW2008R2

DECLARE @otablename sysname 
DECLARE @tablename sysname 
DECLARE  @columnname sysname
DECLARE  @schemaname sysname
DECLARE  @TypeID INT
DECLARE  @SQL_TEMPLATE NVARCHAR(MAX)
DECLARE @EXEC_SQL NVARCHAR(MAX)
DECLARE @RecordCount VARCHAR(512)
DECLARE  @DistinctCount VARCHAR(512)
DECLARE  @MinColumn VARCHAR(512)
DECLARE  @MinColumnPattern VARCHAR(512)
DECLARE @MaxColumnPattern VARCHAR(512)
DECLARE @MaxColumn VARCHAR(512)
DECLARE @MinLength VARCHAR(512)
DECLARE  @MaxLength VARCHAR(512)
DECLARE @NullCount VARCHAR(512)
DECLARE @BlankCount VARCHAR(512)
DECLARE @IsDate VARCHAR(512)
DECLARE @IsNumeric VARCHAR(512)
DECLARE  @InferredType VARCHAR(512)
SET @tablename ='DimTime'
SET  @columnname ='TimeID' 
SET  @schemaname='dbo'
-------------------------------------------------------------------------------------
-- Create Pattern Function
-------------------------------------------------------------------------------------
if NOT EXISTS (select * from dbo.sysobjects where id = object_id('dbo.fn_Pattern'))
BEGIN
  EXEC('CREATE FUNCTION dbo.fn_Pattern (@inString NVARCHAR(MAX)) 
    RETURNS NVARCHAR(MAX) AS

    BEGIN
      IF @inString IS NULL
      BEGIN
        RETURN ''NULL''
      END
      
      DECLARE @C NCHAR(1)
      DECLARE @len INT
      DECLARE @offset INT

      SET  @inString = UPPER(RTRIM(@inString))
      SET @len = LEN(@inString)
      SET @offset = 1

      WHILE @offset <= @len
      BEGIN
        SET  @C = SUBSTRING(@inString, @offset, 1)
        SET  @inString = STUFF  (@inString,  @offset, 1,
                    (CASE  WHEN @C BETWEEN ''0'' AND ''9'' THEN ''9''
                        WHEN @C BETWEEN ''A'' AND ''Z'' THEN ''x''
                        WHEN @C = '' ''        THEN ''b''
                        ELSE @C 
                    END))
        
        SET  @offset = @offset + 1
      END

      RETURN @inString
    END')
END
SET @SQL_TEMPLATE = 
'SET NOCOUNT ON 
SELECT  ''<schemaname>'' [SchemaName], 
    ''<tablename>'' [TableName], 
    ''<columnname>'' [ColumnName], 
    (<RecordCount>) [RecordCount], 
    (<DistinctCount>) [DistinctDomainCount], 
    (<MinColumn>) [MinDomain], 
    (<MaxColumn>) [MaxDomain], 
    (<MinColumnPattern>) [MinColumnPattern], 
    (<MaxColumnPattern>) [MaxColumnPattern], 
    (<MinLength>) [MinDomainLength], 
    (<MaxLength>) [MaxDomainLength], 
    (<NullCount>) [NullDomainCount], 
    (<BlankCount>) [BlankDomainCount]
FROM  [<schemaname>].[<tablename>] '

SET  @RecordCount = 'select count(*) from [<schemaname>].[<tablename>] '
SET  @DistinctCount = 'count(distinct [<columnname>])'
SET  @MinColumn = 'min([<columnname>])'
SET @MaxColumn = 'max([<columnname>])'
SET @MinLength = 'select min(len([<columnname>])) from [<schemaname>].[<tablename>] '
SET  @MaxLength = 'select max(len([<columnname>])) from [<schemaname>].[<tablename>] '
SET @IsDate = '(select min(isdate([<columnname>])) from [<schemaname>].[<tablename>])'
SET @IsNumeric = '(select min(isnumeric([<columnname>])) from [<schemaname>].[<tablename>])'
SET @NullCount = @RecordCount + ' where [<columnname>] IS NULL '
SET @BlankCount = @RecordCount + ' where [<columnname>] IS NOT NULL AND rtrim([<columnname>]) = '''' '
SET @MinColumnPattern = 'select min(dbo.fn_Pattern([<columnname>])) from [<schemaname>].[<tablename>] '
SET @MaxColumnPattern = 'select max(dbo.fn_Pattern([<columnname>])) from [<schemaname>].[<tablename>] '

  
  SET @EXEC_SQL = @SQL_TEMPLATE

  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<RecordCount>', @RecordCount)

  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<DistinctCount>', @DistinctCount)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MinColumn>', @MinColumn)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MaxColumn>', @MaxColumn)
 SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MinColumnPattern>', @MinColumnPattern)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MaxColumnPattern>', @MaxColumnPattern)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MinLength>', @MinLength)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<MaxLength>', @MaxLength)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<IsDate>', @IsDate)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<IsNumeric>', @IsNumeric)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<NullCount>', @NullCount)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<BlankCount>', @BlankCount)
  --SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<InferredType>', @InferredType)

  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<schemaname>', @SchemaName)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<tablename>', @TableName)
  SET @EXEC_SQL = REPLACE(@EXEC_SQL,'<columnname>', @ColumnName)

 PRINT @EXEC_SQL
  EXEC (@EXEC_SQL)
  go
