CREATE TABLE #t(
ID INT,
POS INT,
NAME NVARCHAR(500)
)
;with cte as
(select 1 as ID,1 as pos,'ab&' as name
union all 
select 1 as ID,2 as pos,'cd&' as name
union all
select 1 as ID,3 as pos,'wef&' as name
union all
select 1 as ID,4 as pos,'cdf&' as name
union all
select 2 as ID,1 as pos,'ab2' as name
union all
select 2 as ID,2 as pos, 'cd2' as name)
INSERT INTO #t
select * from cte
GO
CREATE CLUSTERED INDEX IX_TMP_T ON #t (ID ASC, pos ASC)
GO
DECLARE @ID INT
DECLARE @Name NVARCHAR(50)
SELECT @ID = -1
UPDATE #t
SET Name = @Name,
@Name = 
CASE 
WHEN @ID <> ID THEN Name
WHEN @ID = ID THEN @Name + '/' + Name
END,
@ID = ID
;WITH CTE AS (
SELECT ID, NAME, ROW_NUMBER() OVER (Partition BY ID ORDER BY pos DESC) AS ROWNUMBER
FROM #t
)
SELECT * FROM CTE WHERE ROWNUMBER = 1
DROP TABLE #t
