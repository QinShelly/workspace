Select  wait_type,  
        waiting_tasks_count,  
        wait_time_ms 
from    sys.dm_os_wait_stats   
where    wait_type like 'PAGEIOLATCH%'   
order by wait_type
