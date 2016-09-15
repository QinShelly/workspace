$DebugPreference="Continue"

AddDays

$SCAN_START_DAY =  '{0:yyyyMMdd}' -f $currentDate.AddDays( -52 * 7 )

$ErrorActionPreference = "Stop"   

Set_ExecutionPolicy Unrestricted

Get-Service -Name "MSSQLServer" | Start-Service

get-childitem -recurse -Path "c:\rsi\nextgen\scripts"  "*.sql" | Select-String -pattern "RSI_GET_FACT_PARTITION_DATE_RANGE"
