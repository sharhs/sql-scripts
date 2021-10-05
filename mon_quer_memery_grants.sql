SELECT eq.session_id
     ,blcked =  er.blocking_session_id
     , er.status
     , er.wait_type
     , eq.wait_order
     , er.database_id
     , object_schema_name(st.[objectid], st.[dbid]) + '.' + OBJECT_NAME(st.[objectid], st.[dbid]) AS objname
     , SUBSTRING(st.text, er.statement_start_offset / 2, (CASE
           WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(Nvarchar(Max), st.text)) * 2
           ELSE er.statement_end_offset
       END - er.statement_start_offset) / 2) AS [individual query]

     , eq.query_cost     
     , eq.requested_memory_kb / 1024.0       AS requested_memory_mb
     , eq.granted_memory_kb / 1024.0         AS granted_memory_mb
     , er.granted_query_memory
     , eq.required_memory_kb / 1024.0        AS required_memory_mb
     , eq.used_memory_kb / 1024.0            AS used_memory_mb
     , eq.max_used_memory_kb / 1024.0        AS max_used_memory_mb
     , eq.ideal_memory_kb / 1024.0           AS ideal_memory_mb
     , eq.request_time
     , eq.grant_time
     
     , eq.timeout_sec
     , eq.dop
     , eq.resource_semaphore_id
     , eq.queue_id
     , eq.wait_order
     , eq.is_next_candidate
     , eq.wait_time_ms
     , er.wait_type
     , er.wait_time
     , er.last_wait_type
     , er.wait_resource
     , eq.group_id
     , eq.pool_id
     , eq.is_small
     , eq.request_id
     , er.open_transaction_count
     , er.context_info
     , er.cpu_time
     , er.total_elapsed_time
     , er.reads
     , er.writes
     , er.logical_reads
     , er.row_count
     , er.nest_level
FROM sys.dm_exec_query_memory_grants eq
LEFT JOIN sys.dm_exec_requests er
    ON er.session_id = eq.session_id
OUTER APPLY sys.dm_exec_sql_text((eq.sql_handle)) st
ORDER BY eq.[requested_memory_kb]  DESC

/*

SELECT * FROM  sys.dm_os_schedulers 

SELECT * FROM  sys.dm_os_threads




*/
