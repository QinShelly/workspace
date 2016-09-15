Solution with CTE
--WITH CTE AS
--(
--select 1 AS GroupID,'AAA' AS String UNION ALL
--select 2 AS GroupID,'BBB' AS String UNION ALL
--select 3 AS GroupID,'ZZZ' AS String UNION ALL
--select 4 AS GroupID,'Tbc' AS String UNION ALL
--select 3 AS GroupID,'Nez' AS String UNION ALL
--select 1 AS GroupID,'Todd' AS String UNION ALL
--select 2 AS GroupID,'Half' AS String UNION ALL
--select 2 AS GroupID,'Nice' AS String
--)
--insert into #test
--SELECT * FROM CTE
--drop table #test
--create table #test 
--(GroupID int,String nvarchar(100) )
;WITH CTE AS
(
SELECT 
RN = ROW_NUMBER() OVER(PARTITION BY GroupID ORDER BY String)
,* FROM #test
)
select * from CTE;
;WITH CTE AS
(
SELECT 
RN = ROW_NUMBER() OVER(PARTITION BY GroupID ORDER BY String)
,* FROM #test
),
CTE1 AS
(
SELECT GroupID,String,RN FROM CTE WHERE RN =1
UNION ALL
SELECT cte.GroupID,CONVERT(NVARCHAR(100),cte.String + ',' + cte1.String) AS String,cte.rn
FROM CTE1 JOIN CTE
ON cte1.RN + 1 = cte.RN AND cte.GroupID = cte1.GroupID
),
CTE2 AS
(
SELECT GroupID,MAX(RN) AS MaxRN FROM CTE 
GROUP BY GroupID
)
SELECT CTE1.* 
FROM CTE1 JOIN CTE2 ON cte1.GroupID = cte2.GroupID AND cte1.RN = cte2.MaxRN
