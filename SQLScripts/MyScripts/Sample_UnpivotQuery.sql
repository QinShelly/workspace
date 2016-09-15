
CREATE TABLE Foo 
( keycol INT NOT NULL PRIMARY KEY, 
col1 INT NOT NULL, 
col2 INT NOT NULL, 
col3 INT NOT NULL, 
col4 INT NOT NULL); 
INSERT INTO Foo VALUES(1, 5, 0, 1, 10); 
INSERT INTO Foo VALUES(2, 0, 0, 3, 1);
INSERT INTO Foo VALUES(3, 0, 0, 0, 0);
INSERT INTO Foo VALUES(4, 9, 1, 22, 8);
INSERT INTO Foo VALUES(5, 8, 8, 8, 8);

 --max across columns with UNPIVOT
 SELECT keycol        ,
       col AS max_col,
       val AS max_val
FROM
       (SELECT  keycol,
                val   ,
                col   ,
                ROW_NUMBER() OVER(PARTITION BY keycol ORDER BY val DESC, col) AS rk
       FROM     Foo UNPIVOT(val FOR col IN (col1,
                                            col2,
                                            col3,
                                            col4)
                ) AS U
       ) AS T
WHERE  rk = 1;
  
  SELECT   keycol,
          COUNT(NULLIF(val, 0)) AS cnt_non_zero
 FROM     Foo UNPIVOT(val FOR col IN (col1,
                                      col2,
                                      col3,
                                      col4)
          ) AS U
 GROUP BY keycol;
