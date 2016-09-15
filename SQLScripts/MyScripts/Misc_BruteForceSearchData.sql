DECLARE @command NVARCHAR(MAX) --the SQL Statement that will be executed
DECLARE @SearchTerm NVARCHAR(100) --the term to be searched
SELECT @SearchTerm='%href%'
--start by assembling UNION of all rows in each table that can be checked
SELECT @command = COALESCE(@command + '
UNION ALL ', '')--use fact of null in variable to omit first UNION ALL
+ 'SELECT '
+ ''''+SCHEMA_NAME(t.schema_id) + '.' 
+ QUOTENAME(REPLACE(t.NAME,'''',''''''))+''''--table name
+ ' AS tableName, COUNT(*) AS numberOfRows, '''
+ QUOTENAME(REPLACE(c.NAME,'''','''''')) + ''' AS columnName
FROM ' + SCHEMA_NAME(t.schema_id) + '.' 
+ QUOTENAME(REPLACE(t.NAME,'''',''''''))--table name
+' WHERE '
+ CASE WHEN (ty.name IN ( 'text', 'ntext', 'xml', 'sql_variant') 
OR is_user_defined=1) 
THEN 'CONVERT(nvarchar(max), ' 
+ QUOTENAME(REPLACE(c.NAME,'''','''''')) + ')'
WHEN ty.name IN ( 'char', 'nchar', 'varchar','nvarchar') 
THEN QUOTENAME(REPLACE(c.NAME,'''',''''''))
ELSE '''''' --this must never happen!
END
+ ' LIKE '''+REPLACE(@searchTerm,'''','''''')+''' ' 

FROM sys.columns AS c --we search all possible columns
INNER JOIN sys.types AS ty --of particular data types
ON c.user_type_id = ty.user_type_id
INNER JOIN sys.tables AS t --with their tables
ON c.OBJECT_ID = t.OBJECT_ID
WHERE (ty.name IN ('char','nchar','nvarchar','varchar','text',
'ntext', 'xml', 'sql_variant')
OR is_user_defined=1 ) 
SELECT @command='
SELECT * from ('+@command+') hits
WHERE hits.numberOfRows > 0'

EXECUTE (@command)