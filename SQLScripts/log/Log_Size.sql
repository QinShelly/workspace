SELECT instance_name,cntr_value FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = 'SQLServer:Databases'   
and counter_name = 'Percent Log Used' 
and instance_name <> '_Total'                                                                                                                          
ORDER BY   cntr_value DESC


SELECT instance_name,cntr_value FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = 'SQLServer:Databases'   
and counter_name = 'Log File(s) Size (KB)'   
ORDER BY   cntr_value DESC

SELECT instance_name,cntr_value FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = 'SQLServer:Databases'   
and counter_name = 'Data File(s) Size (KB)'   
ORDER BY   cntr_value DESC	
