
. "$PSScriptRoot\VerticaConfig.ps1"


function Create-VerticaConnection {
    PARAM($server, $dbName, $username, $password, $config=$null, [switch] $aux)
    $backupServers = ""
    if($config) {
        $username = $config.username
        $password = $config.password
        $context  = $config.context
        if(-Not $server) {
            $server = $config.serverName
        }
        if(-Not $dbName) {
            $dbName = $config.dbName
        }
        $backupServers = ";BackupServerNode=$($config.backupServers -join ',')"
    } else {
        if($username -eq $null) {
            Throw "No username specified for Create-VerticaConnection"
        }
        if($password -eq $null) {
            Throw "No password specified for Create-VerticaConnection"
        }
    }
    $loadInfo = [Reflection.Assembly]::LoadWithPartialName("Vertica.Data")
    $verticaConnection = New-Object Vertica.Data.VerticaClient.VerticaConnection
    $verticaConnection.ConnectionString = "database=$dbName;host=$server;user=$username;password=$password$backupServers;ConnectionLoadBalance=True;label=$context"
    $verticaConnection.Open()
    
    if($aux) {
        $auxConnection = New-Object Vertica.Data.VerticaClient.VerticaConnection
        $auxConnection.ConnectionString = "database=$dbName;host=$server;user=$username;password=$password$backupServers;ConnectionLoadBalance=True;label=$context"
        $auxConnection.Open()
        $verticaConnection | Add-Member AuxConnection $auxConnection
    }
    # check if connection is open
    $verticaConnection | Add-Member IsOpen -MemberType ScriptProperty -Value {
        return $this.State -eq [System.Data.ConnectionState]::Open
    }

    $verticaConnection | Add-Member CaptureError -MemberType ScriptMethod -Value {
        param($name,$stmt)
        [array]$stack = Get-PSCallStack
        $skip = 1
        try {
            &$stmt
        } catch {
            $extra = ""
            for($i = $skip; $i -lt $stack.length-2; $i++) {
                $s = $stack[$stack.length-$i-1]
                $extra += (" " * ($i-$skip)) + "$($s.ScriptName):$($s.ScriptLineNumber)`n"
            }
            $inner = $_.Exception
            while($inner.InnerException) { $inner = $inner.InnerException }
            throw "$name($sql) `nException: $($inner.Message) `n$($extra)"
        }
    }

    # Returns the results of a query (can be multiple rows)
    $verticaConnection | Add-Member Query -MemberType ScriptMethod -Value {
        Param([String]$sql, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandText    = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $adapter               = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
        $adapter.SelectCommand = $sqlCmd
        $dataSet               = New-Object System.Data.DataSet
        $this.CaptureError("Vertica.Query", {
            $adapter.Fill($dataSet) | Out-Null
        })
        $sqlCmd.Dispose()
        return $dataSet.Tables[0].Rows
    }

    $verticaConnection | Add-Member QueryTable -MemberType ScriptMethod -Value {
        Param([String]$sql, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandText    = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $adapter               = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
        $adapter.SelectCommand = $sqlCmd
        $dataSet               = New-Object System.Data.DataSet
        $this.CaptureError("Vertica.QueryTable", {
            $adapter.Fill($dataSet) | Out-Null
        })
        $sqlCmd.Dispose()
        return ,$dataSet.Tables[0]
    }

    # Returns one scalar value
    $verticaConnection | Add-Member QueryScalar -MemberType ScriptMethod -Value {
        Param([String]$sql, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $sqlCmd             = $this.CreateCommand()
        $sqlCmd.CommandText = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $res = $this.CaptureError("Vertica.QueryScalar", {
            $sqlCmd.ExecuteScalar()
        })
        $sqlCmd.Dispose()
        return $res
    }

    # Executes sql query without collecting any result
    $verticaConnection | Add-Member Execute -MemberType ScriptMethod -Value {
        Param([String]$sql, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        if($this.AuxConnection -and $sql.StartsWith("TRUNCATE")) {
            $sqlCmd = $this.AuxConnection.CreateCommand()
        } else {
            $sqlCmd = $this.CreateCommand()
        }
        $sqlCmd.CommandText = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }

        $this.CaptureError("Vertica.Execute", {
            $sqlCmd.ExecuteNonQuery() | Out-Null
        })
        $sqlCmd.Dispose()
    }

    # Executes sql query and returns affected rows count
    $verticaConnection | Add-Member ExecuteWithCount -MemberType ScriptMethod -Value {
        Param([String]$sql, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $sqlCmd             = $this.CreateCommand()
        $sqlCmd.CommandText = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }

        $res = $this.CaptureError("Vertica.ExecuteWithCount", {
            $sqlCmd.ExecuteNonQuery() 
        })
        $sqlCmd.Dispose()
        return $res
    }

    # Inserts a batch of rows into vertica
    # The $param names need to correspond to the column names
    $verticaConnection | Add-Member BatchInsert -MemberType ScriptMethod -Value {
        PARAM($table, $query, $params, $data, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $adapter                           = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
        $adapter.SelectCommand             = $this.CreateCommand()
        $adapter.SelectCommand.CommandText = "SELECT * from $table where 1 <> 0"

        $adapter.InsertCommand             = $this.CreateCommand()
        $adapter.InsertCommand.CommandText = $query

        foreach($param in $params) {
            $parameter = (New-Object Vertica.Data.VerticaClient.VerticaParameter -ArgumentList $($param[0]), $($param[1]))
            $parameter.SourceColumn = $($param[0])
            $adapter.InsertCommand.Parameters.Add($parameter) | Out-Null
            if ($trans -ne $null) { $adapter.InsertCommand.Transaction = $trans }
        }

        $adapter.UpdateBatchSize = 10000

        $ds = New-Object System.Data.DataSet
        $adapter.Fill($ds) | Out-Null
        $dt = $ds.Tables[0]
        foreach($row in $data) {
            $newRow = $dt.NewRow();
            foreach($param in $params) {
                $newRow[$($param[0])]  = $row[$($param[0])]
            }
            $dt.Rows.Add($newRow)
        }

        $rows = $adapter.Update($ds)
        return $rows
    }

    # Inserts a batch of rows into vertica with data type
    # The $param names need to correspond to the column names
    $verticaConnection | Add-Member BatchInsertWithType -MemberType ScriptMethod -Value {
        PARAM($table, $query, $params, $data, [Vertica.Data.VerticaClient.VerticaTransaction]$trans = $null)
        $adapter                           = New-Object Vertica.Data.VerticaClient.VerticaDataAdapter
        $adapter.SelectCommand             = $this.CreateCommand()
        $adapter.SelectCommand.CommandText = "SELECT * from $table where 1 <> 0"

        $adapter.InsertCommand             = $this.CreateCommand()
        $adapter.InsertCommand.CommandText = $query

        foreach($param in $params) {
            $arg=""
            $isfirst=$true;
            foreach($p in $param)
            {

                if($p -eq $null)
                {
                    $p="`$null";
                }
                else
                {
                    $p=$p.ToString().Replace('$','`$');
                }

                if($isfirst)
                {
                   $arg=$arg +$p;
                   $isfirst=$false
                }
                else
                {
                    $arg=$arg+"," +$p;
                }
            }
            $parameter="";
            $cmd="`$parameter = (New-Object Vertica.Data.VerticaClient.VerticaParameter -ArgumentList $($arg))"

            Invoke-Expression $cmd;
            #$parameter = (New-Object Vertica.Data.VerticaClient.VerticaParameter -ArgumentList $($param[0]), $($param[1]),$($param[2]))
            $parameter.SourceColumn = $($param[0])
            $adapter.InsertCommand.Parameters.Add($parameter) | Out-Null
            if ($trans -ne $null) { $adapter.InsertCommand.Transaction = $trans }
        }

        $adapter.UpdateBatchSize = 10000

        $ds = New-Object System.Data.DataSet
        $adapter.Fill($ds) | Out-Null
        $dt = $ds.Tables[0]
        foreach($row in $data) {
            $newRow = $dt.NewRow();
            foreach($param in $params) {
                $newRow[$($param[0])]  = $row[$($param[0])]
            }
            $dt.Rows.Add($newRow)
        }

        $rows = $adapter.Update($ds)
        return $rows
    }

    $verticaConnection | Add-Member SetSchema -MemberType ScriptMethod -Value {
        Param($schemaName)
        $this.Execute("SET SEARCH_PATH TO $schemaName");
    }

    return $verticaConnection
}


function Create-SqlConnection {
    PARAM($server, $dbName, $config=$null, $user=$null,$pwd=$null,$CommandTimeout = 10800)
    # default command timeout is 3 hours
    if($config) {
        if(-Not $server) {
            $server = $config.serverName
        }
        if(-Not $dbName) {
            $dbName = $config.dbName
        }
    }

    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    if($user -and $pwd) {
        Write-Host "using sqlserver auth $user"
        $sqlConnection.ConnectionString = "Server=$server;DataBase=$dbName;Password=$pwd;User ID=$user"
    } else {
        $sqlConnection.ConnectionString = "Server=$server;DataBase=$dbName;Integrated Security=SSPI"
    }
    $sqlConnection.open()

    # check if connection is open
    $sqlConnection | Add-Member IsOpen -MemberType ScriptProperty -Value {
        return $this.State -eq [System.Data.ConnectionState]::Open
    }

    $sqlConnection | Add-Member CommandTimeout -MemberType NoteProperty -Value $CommandTimeout

    # Returns the results of a query (can be multiple rows)
    $sqlConnection | Add-Member Query -MemberType ScriptMethod -Value {
        Param([String]$sql, [System.Data.SqlClient.SqlTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandText    = $sql
        $sqlCmd.CommandTimeout = $this.CommandTimeout
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $adapter               = New-Object System.Data.SqlClient.SqlDataAdapter
        $adapter.SelectCommand = $sqlCmd
        $dataSet               = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
        $sqlCmd.Dispose()
        return $dataSet.Tables[0].Rows
    }

    # Returns one scalar value
    $sqlConnection | Add-Member QueryScalar -MemberType ScriptMethod -Value {
        Param([String]$sql, [System.Data.SqlClient.SqlTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandTimeout = $this.CommandTimeout
        $sqlCmd.CommandText    = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $res = $sqlCmd.ExecuteScalar()
        $sqlCmd.Dispose()
        return $res
    }

    $sqlConnection | Add-Member QueryTable -MemberType ScriptMethod -Value {
        Param([String]$sql, [System.Data.SqlClient.SqlTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandTimeout = $this.CommandTimeout
        $sqlCmd.CommandText    = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $adapter               = New-Object System.Data.SqlClient.SqlDataAdapter
        $adapter.SelectCommand = $sqlCmd
        $dataSet               = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
        $sqlCmd.Dispose()
        return ,$dataSet.Tables[0]
    }

    # Executes sql query without collecting any result
    $sqlConnection | Add-Member Execute -MemberType ScriptMethod -Value {
        Param([String]$sql, [System.Data.SqlClient.SqlTransaction]$trans = $null)
        $sqlCmd                = $this.CreateCommand()
        $sqlCmd.CommandTimeout = $this.CommandTimeout
        $sqlCmd.CommandText    = $sql
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $sqlCmd.ExecuteNonQuery() | Out-Null
        $sqlCmd.Dispose()
    }

    # Executes sql query without collecting any result
    $sqlConnection | Add-Member ExecuteProc -MemberType ScriptMethod -Value {
        Param([String]$sql, $params = @(), [System.Data.SqlClient.SqlTransaction]$trans = $null, [int]$Timeout=1000)
        $sqlCmd             = $this.CreateCommand()
        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $sqlCmd.Commandtimeout = $Timeout
        $sqlCmd.CommandText = $sql
        foreach($param in $params) {
            $p = $sqlCmd.Parameters.Add($param.name, $param.type)
            $p.Value = $param.value
        }
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $sqlCmd.ExecuteNonQuery() | Out-Null
        $sqlCmd.Dispose()
    }

    $sqlConnection | Add-Member ExecuteProcwParam -MemberType ScriptMethod -Value {
        Param($sqlCmd, [System.Data.SqlClient.SqlTransaction]$trans = $null)
        $sqlCmd.Connection = $this
        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $sqlCmd.CommandTimeout = $this.CommandTimeout
        if ($trans -ne $null) { $sqlCmd.Transaction = $trans }
        $sqlCmd.ExecuteNonQuery() | Out-Null
        $sqlCmd.Dispose()
    }


    $sqlConnection | Add-Member BatchInsert -MemberType ScriptMethod -Value {
        PARAM($table, $query, $params, $data)
        $adapter                           = New-Object System.Data.SqlClient.SqlDataAdapter
        $adapter.SelectCommand             = $this.CreateCommand()
        $adapter.SelectCommand.CommandText = "SELECT * from $table where 1 <> 0"
        $adapter.SelectCommand.UpdatedRowSource =  New-Object  System.Data.UpdateRowSource;

        $adapter.InsertCommand             = $this.CreateCommand()
        $adapter.InsertCommand.CommandText = $query

        foreach($param in $params) {
            $adapter.InsertCommand.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter -ArgumentList "@$param", $null)) | Out-Null
            $adapter.InsertCommand.Parameters[$adapter.InsertCommand.Parameters.Count-1].SourceColumn = $param
        }
        $adapter.InsertCommand.UpdatedRowSource = New-Object System.Data.UpdateRowSource;
        $adapter.UpdateBatchSize = 10000


        $ds = New-Object System.Data.DataSet
        $dt = New-Object System.Data.DataTable -Args $table
        $ds.Tables.Add($dt) | Out-Null

        foreach($param in $params) {
            $dt.Columns.Add($param) | Out-Null
        }

        foreach($row in $data) {
            $newRow = $dt.NewRow();
            foreach($param in $params) {
                $newRow[$param]  = $row[$param]
            }
            $dt.Rows.Add($newRow)
        }
        $adapter.Update($ds, $table) | Out-Null
    }

    $sqlConnection | Add-Member BatchInsertWithType -MemberType ScriptMethod -Value {
        PARAM($table, $query, $params, $data)
        $adapter                           = New-Object System.Data.SqlClient.SqlDataAdapter
        $adapter.SelectCommand             = $this.CreateCommand()
        $adapter.SelectCommand.CommandText = "SELECT * from $table where 1 <> 0"
        $adapter.SelectCommand.UpdatedRowSource =  New-Object  System.Data.UpdateRowSource;

        $adapter.InsertCommand             = $this.CreateCommand()
        $adapter.InsertCommand.CommandText = $query

        foreach($row in $params) {
            $param = $row[0]
            $dataType = $row[1]
            $adapter.InsertCommand.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter -ArgumentList "@$param", $dataType)) | Out-Null
            $adapter.InsertCommand.Parameters[$adapter.InsertCommand.Parameters.Count-1].SourceColumn = $param
        }
        $adapter.InsertCommand.UpdatedRowSource = New-Object System.Data.UpdateRowSource;
        $adapter.UpdateBatchSize = 10000


        $ds = New-Object System.Data.DataSet
        $dt = New-Object System.Data.DataTable -Args $table
        $ds.Tables.Add($dt) | Out-Null

        foreach($param in $params) {
            $dt.Columns.Add($param[0]) | Out-Null
        }

        foreach($row in $data) {
            $newRow = $dt.NewRow();
            foreach($p in $params) {
                $param = $p[0]
                $newRow[$param]  = $row[$param]
            }
            $dt.Rows.Add($newRow)
        }
        $adapter.Update($ds, $table) | Out-Null
    }

    # Works similar to bcp
    # example: $connection.BulkInsert("myTable", @("col1","col2"), @(@{col1=1;col2=2}, @{col1=10, col2=20}))
    $sqlConnection | Add-Member BulkInsert -MemberType ScriptMethod -Value {
        PARAM($table, $columns, $data)
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy -Args $this
        $bulkCopy.BatchSize = 500;
        $bulkCopy.DestinationTableName = $table;

        if($data -is [System.Data.DataTable]) {
            $dt = $data
        } else {
            $dt = New-Object System.Data.DataTable
            foreach($column in $columns) {
                $dt.Columns.Add($column) | Out-Null
            }
            foreach($row in $data) {
                $newRow = $dt.NewRow();
                foreach($column in $columns) {
                    $newRow[$column]  = $row[$column]
                }
                $dt.Rows.Add($newRow)
            }
        }

        foreach($column in $columns) {
            $bulkCopy.ColumnMappings.Add($column, $column) | Out-Null
        }

        $bulkCopy.WriteToServer($dt) | Out-Null
    }
    
    
    #bulk copy from vertica to sql server using data reader less memory
      $sqlConnection | Add-Member BulkCopyFromVertica -MemberType ScriptMethod -Value {
          PARAM($table, $dw, $verticaQuery, $columnMapping, $batchSize = 1000)
            $loadInfo = [Reflection.Assembly]::LoadWithPartialName("Vertica.Data")
            
            $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy -Args $this
            $bulkCopy.BatchSize = $batchSize;
            $bulkCopy.BulkCopyTimeout = 3600;
            $bulkCopy.DestinationTableName = $table;
            
            $verticaCommand = New-Object Vertica.Data.VerticaClient.VerticaCommand;
            $verticaCommand.CommandText = $verticaQuery;
            $verticaCommand.Connection = $dw;
            if($columnMapping){
            
                foreach($columnMappingKey in $columnMapping.Keys){
                    $bulkCopyColumnMapping = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping($columnMappingKey, $columnMapping.Get_Item($columnMappingKey));
                    $bulkCopy.ColumnMappings.Add($bulkCopyColumnMapping) | Out-Null
                }
            }
            
            $verticaDataReader = $verticaCommand.ExecuteReader([System.Data.CommandBehavior]::Default);
            
            $bulkCopy.WriteToServer($verticaDataReader) | Out-Null

    }
    
    return $sqlConnection
}