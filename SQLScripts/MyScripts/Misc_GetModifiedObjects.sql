SELECT name, 
 TYPE, 
 type_desc, 
 create_date, 
 modify_date 
FROM sys.objects 
WHERE TYPE IN ('U','V','PK','F','D','P') 
AND modify_date >= Dateadd(HOUR,21,Cast((Cast(Getdate() - 1 AS VARCHAR(12))) AS SMALLDATETIME)) 
ORDER BY modify_date 
