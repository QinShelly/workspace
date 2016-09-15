CREATE TABLE t ( 
  id       VARCHAR(10), 
  SEQUENCE INT, 
  amount   INT, 
  goodname VARCHAR(10), 
  cdate    VARCHAR(10)) 

INSERT INTO t 
SELECT 'A', 
       1, 
       10, 
       'NAMEA1', 
       '2007/01/01' 
UNION ALL 
SELECT 'A', 
       2, 
       20, 
       'NAMEA2', 
       '2007/01/02' 
UNION ALL 
SELECT 'A', 
       3, 
       30, 
       'NAMEA3', 
       '2007/01/03' 
UNION ALL 
SELECT 'B', 
       1, 
       10, 
       'NAMEB1', 
       '2008/01/04' 

SELECT * 
FROM   t 

CREATE FUNCTION Aa 
               (@id VARCHAR(10)) 
RETURNS VARCHAR(100) 
AS 
  BEGIN 
    DECLARE  @s1 VARCHAR(100) 
     
    SELECT @s1 = Coalesce(@s1 + ',','') + goodname 
    FROM   t 
    WHERE  id = @id 
     
    RETURN (@s1) 
  END 

CREATE FUNCTION Bb 
               (@id VARCHAR(10)) 
RETURNS VARCHAR(100) 
AS 
  BEGIN 
    DECLARE  @s1 VARCHAR(100) 
     
    SELECT @s1 = Coalesce(@s1 + ',','') + Right(cdate,5) 
    FROM   t 
    WHERE  id = @id 
     
    RETURN (@s1) 
  END 

SELECT   id, 
         Sum(amount) AS amount, 
         dbo.Aa(id)  AS name, 
         dbo.Bb(id)  AS DATE 
FROM     t 
GROUP BY id 
