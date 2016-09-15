SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT  er.wait_time/1000/60.0 wait_time_in_minutes,er.statement_end_offset, [Individual Query] = SUBSTRING(qt.text, er.statement_start_offset / 2,
                                       ( CASE WHEN er.statement_end_offset = -1
                                              THEN LEN(CONVERT(NVARCHAR(MAX), qt.text))
                                                   * 2
                                              ELSE er.statement_end_offset
                                         END - er.statement_start_offset ) / 2) ,
        [Parent Query] = qt.text ,
        Program = program_name ,
        db_name(database_id) as 'database name',
        session_id,
        Hostname ,
        nt_domain ,
        start_time,
        er.status,
        er.wait_resource,
        er.wait_type,
        pl.*
FROM    sys.dm_exec_requests er
        INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
        CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
        CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) AS pl
WHERE   session_Id > 50              -- Ignore system spids.
        AND session_Id NOT IN ( @@SPID )     -- Ignore this current statement.
            --and db_name(database_id)='KRAFT_GROCERY_WINN_DIXIE'
ORDER BY 1 , 2
