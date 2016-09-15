. "$PSScriptRoot\Crypto.ps1"

function Get-VerticaConfig {
    PARAM($connection, $siloID, $context='')

    $dwUser = "dw.$($context)user.id"
    $dwPass = "dw.$($context)user.password"
    # Select username and password (encrypted)
    $result = $connection.QueryTable("
	SELECT MAX(CASE WHEN NAME='$dwUser' THEN VALUE END) username
	, MAX(CASE WHEN NAME='$dwPass' THEN VALUE END) password
	, MAX(CASE WHEN NAME='dw.server.name' THEN VALUE END) servername
	, MAX(CASE WHEN NAME='dw.db.name' THEN VALUE END) dbname
	, MAX(CASE WHEN NAME='dw.db.portno' THEN VALUE END) portno
    , MAX(CASE WHEN NAME='dw.backupserver.name' THEN VALUE END) backupservers
    FROM [dbo].[RSI_CORE_CFGPROPERTY] where silo_id = '$siloID' and name IN ('$dwUser', '$dwPass', 'dw.server.name', 'dw.db.name', 'dw.backupserver.name')")

    if($result -eq $null -or $result.IsNull('username') -or $result.IsNull('password')) {
        throw "No $dwUser or $dwPass entry for $siloID [$context]"
    }

    if($result.IsNull('backupservers')) {
        $backupservers = @()
    } else {
        $backupservers = $result.backupservers -split ','
    }

    #Adding contect to Session
    if ($context -eq '') {

        $context = 'DEPLOYMENT'
    }


    [pscustomobject]@{
        'username'      = $result.username
        'password'      = Decrypt -Code $result.password
		'serverName'    = $result.servername
        'backupServers' = $backupservers
		'dbName'        = $result.dbname
		'portNo'		= $result.portno
        'context'       = $context
        }
}
