@echo off

md "%2"
md "%2\routines"

sqlcmd -E -S %1 -d %2 -y 0 -h-1 -Q "SET NOCOUNT ON SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.Routines" -o "%2\routines\sp_list.txt"

for /f %%a in (%2\routines\sp_list.txt) do sqlcmd -E -S %1 -d %2 -y 0 -h-1 -Q "SET NOCOUNT ON SELECT definition from sys.sql_modules WHERE object_id = OBJECT_ID('%%a')" -o "%2\routines\%%a.sql"

del "%2\routines\sp_list.txt"

md "%2\views"

sqlcmd -E -S %1 -d %2 -y 0 -h-1 -Q "SET NOCOUNT ON SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS" -o "%2\views\view_list.txt"

for /f %%a in (%2\views\view_list.txt) do sqlcmd -E -S %1 -d %2 -y 0 -h-1 -Q "SET NOCOUNT ON SELECT definition from sys.sql_modules WHERE object_id = OBJECT_ID('%%a')" -o "%2\views\%%a.sql"

del "%2\views\view_list.txt"

md "%2\tables"

sqlcmd -E -S %1 -d %2 -y 0 -h-1 -Q "SET NOCOUNT ON SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -o "%2\tables\table_list.txt"

for /f %%a in (%2\tables\table_list.txt) do sqlcmd -E -S %1 -d %2 -h-1 -Q "SET NOCOUNT ON SELECT COLUMN_NAME + ' ' + DATA_TYPE + CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN '(' + CONVERT(NVARCHAR(10), CHARACTER_MAXIMUM_LENGTH) + ') ' ELSE ' ' END + CASE IS_NULLABLE WHEN 'YES' THEN 'NULL' ELSE 'NOT NULL' END FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '%%a'" -o "%2\tables\%%a.sql"

del "%2\tables\table_list.txt"
