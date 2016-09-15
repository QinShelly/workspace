SELECT cur + 1 AS start_range, nxt - 1 AS end_range 
FROM (SELECT col1 AS cur, (SELECT MIN(col1) 
FROM dbo.T1 AS B WHERE
B.col1 > A.col1) AS nxt 
FROM dbo.T1 AS A) AS D 
WHERE nxt - cur > 1
