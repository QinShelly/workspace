    DECLARE @rows_affected BIGINT;
    DECLARE @delete_batch_size INT;
    SET @delete_batch_size = 1000;
    SET @rows_affected = @delete_batch_size;
    WHILE (@rows_affected = @delete_batch_size)
    BEGIN
        DELETE TOP (@delete_batch_size) FROM big_table 
        WHERE ready_to_archive = 1;
        SET @rows_affected = @@ROWCOUNT;
    END;

-- for better performance, sacrifice concurrency ...
    WHILE (@rows_affected = @delete_batch_size)
    BEGIN
        DELETE TOP (@delete_batch_size) FROM big_table WITH (TABLOCK)
        WHERE ready_to_archive = 1;
        SET @rows_affected = @@ROWCOUNT;
    END;


-- for better concurrency, sacrifice performance
    DELETE FROM big_table 
    WHERE ready_to_archive = 1 
    OPTION (QUERYTRACEON 1224);
