--===== Sample data #1 (#SomeTable1)--===== Create a test table and some data 
CREATE TABLE #sometable1 ( 
  YEAR    SMALLINT, 
  quarter TINYINT, 
  amount  DECIMAL(2,1)) 

GO 

INSERT INTO #sometable1 
           (YEAR, 
            quarter, 
            amount) 
SELECT 2006, 
       1, 
       1.1 
UNION ALL 
SELECT 2006, 
       2, 
       1.2 
UNION ALL 
SELECT 2006, 
       3, 
       1.3 
UNION ALL 
SELECT 2006, 
       4, 
       1.4 
UNION ALL 
SELECT 2007, 
       1, 
       2.1 
UNION ALL 
SELECT 2007, 
       2, 
       2.2 
UNION ALL 
SELECT 2007, 
       3, 
       2.3 
UNION ALL 
SELECT 2007, 
       4, 
       2.4 
UNION ALL 
SELECT 2008, 
       1, 
       1.5 
UNION ALL 
SELECT 2008, 
       3, 
       2.3 
UNION ALL 
SELECT 2008, 
       4, 
       1.9 

GO 

--===== The Cross Tab example 
SELECT YEAR, 
       Sum(CASE 
             WHEN quarter = 1 
             THEN amount 
             ELSE 0 
           END) AS [1st Qtr], 
       Sum(CASE 
             WHEN quarter = 2 
             THEN amount 
             ELSE 0 
           END) AS [2nd Qtr], 
       Sum(CASE 
             WHEN quarter = 3 
             THEN amount 
             ELSE 0 
           END) AS [3rd Qtr], 
       Sum(CASE 
             WHEN quarter = 4 
             THEN amount 
             ELSE 0 
           END) AS [4th Qtr], 
       Sum(amount) AS total 
FROM     #sometable1 
GROUP BY YEAR 

--===== The Pivot Example
SELECT   YEAR,             --(4)        
         [1]                   AS [1st Qtr], --(3)  
         [2]                   AS [2nd Qtr], 
         [3]                   AS [3rd Qtr], 
         [4]                   AS [4th Qtr], 
         [1] + [2] + [3] + [4] AS total --(5)  
FROM     (SELECT YEAR, 
                 quarter, 
                 amount 
          FROM   #sometable1) AS src --(1)  
         PIVOT 
         (Sum(amount) 
          FOR quarter IN ( [1],[2],[3],[4] ) ) AS pvt --(2)  
ORDER BY YEAR 
