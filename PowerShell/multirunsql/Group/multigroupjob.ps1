param($groupName='2')

$Server = "wal1wnfshub.colo.retailsolutions.com"
$Database = "GAHUB" 

$con = "server=$Server;database=$Database;Integrated Security=sspi" 
$cmd = @"
SELECT DB_SERVERNAME,DB_NAME,NTILE(4) OVER(order by siloid) AS Quartile 
 FROM rsi_dim_silo where SiloId in ('COTY_WALGREENS'
, 'DANNON_AHOLD'
,	'CONAGRA_FOODLION')
"@ 

$da = new-object System.Data.SqlClient.SqlDataAdapter ($cmd, $con) 

$dt = new-object System.Data.DataTable 

$da.fill($dt) | out-null 

foreach ($srv in ($dt | Where-Object {$_.Quartile -eq $groupName})) 
{ 
    new-object PSObject -Property @{ServerName=$($srv.DB_SERVERNAME);DBName=$($srv.DB_NAME)} 
    . E:\Ken\SSAS_Info\multirunsql\silo.ps1 -databaseServer $srv.DB_SERVERNAME -databasename $srv.DB_NAME 
} 
