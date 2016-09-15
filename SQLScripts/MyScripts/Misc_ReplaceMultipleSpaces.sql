--===== Create and populate a test table.
     -- This is NOT a part of the solution.
DECLARE @Demo TABLE(OriginalString VARCHAR(8000))
 INSERT INTO @Demo (OriginalString)
 SELECT '  This      has multiple   unknown                 spaces in        it.   ' UNION ALL
 SELECT 'So                     does                      this!' UNION ALL
 SELECT 'As                                does                        this' UNION ALL
 SELECT 'This, that, and the other  thing.' UNION ALL
 SELECT 'This needs no repair.'

--===== Reduce each group of multiple spaces to a single space
     -- for a whole table without functions, loops, or other
     -- forms of slow RBAR.  In the following example, CHAR(7)
     -- is the "unlikely" character that "X" was used for in 
     -- the explanation.
 SELECT REPLACE(
            REPLACE(
                REPLACE(
                    LTRIM(RTRIM(OriginalString))
                ,'  ',' '+CHAR(7))  --Changes 2 spaces to the OX model
            ,CHAR(7)+' ','')        --Changes the XO model to nothing
        ,CHAR(7),'') AS CleanString --Changes the remaining X's to nothing
   FROM @Demo
  WHERE CHARINDEX('  ',OriginalString) > 0
