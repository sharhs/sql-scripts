USE master;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @@servername                  srv,
       es.login_name,
       host = left(es.host_name,20),
       --dec.[client_net_address],
       [wait_type] = CASE 
                          WHEN er.wait_type IS NULL THEN '* ' + er.last_wait_type
                          ELSE er.wait_type
                     END,
       er.session_id,
       
       
       er.blocking_session_id     AS blck,
       DB_NAME(er.database_id)    AS dbname,
       er.status,
       --	'kill '+ cast(er.session_id AS NVARCHAR(9)),
       
       SUBSTRING(
           st.text,
           er.statement_start_offset / 2,
           (
               CASE 
                    WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2
                    ELSE er.statement_end_offset
               END - er.statement_start_offset
           ) / 2
       )                          AS [individual query],
       object_schema_name(st.[objectid], st.[dbid]) + '.' + OBJECT_NAME(st.[objectid], st.[dbid]) AS objname,
       DATEDIFF_BIG(
           SECOND,
           ISNULL(last_request_start_time,last_execution_time),
           GETDATE()
       )                          AS ddif,
       er.wait_resource,
       qs.last_execution_time,
       last_request_start_time,
       last_request_end_time,
       GETDATE()                     data_now,
       er.cpu_time,
       er.logical_reads,
       er.writes,
       --	CAST(st.text AS VARCHAR(200))    AS proctext,
       er.open_transaction_count  AS open_trancnt,
       er.granted_query_memory    AS granted_memory,
       er.[percent_complete],
       er.[estimated_completion_time] / 60000 AS estmtd_comp_time_min,
       es.host_name,
       deib.[event_info],
       'SELECT * FROM sys.dm_exec_query_plan(' 
       + CONVERT(NVARCHAR(256), er.Plan_handle, 1) + ')' [plan],
       'select CAST(query_plan	AS Xml)  from sys.dm_exec_text_query_plan(' 
       + CONVERT(NVARCHAR(256), er.Plan_handle, 1) + ',' 
       + CAST(er.Statement_start_offset AS NVARCHAR(256)) + ',' 
       + CAST(er.Statement_end_offset AS NVARCHAR(256)) + ')' [ind_plan],
       CASE LEFT(es.program_name, 8)
            WHEN 'SQLAgent' THEN 'SELECT name FROM msdb..sysjobs sj(NOLOCK) where SUBSTRING('''
                 + es.program_name + ''', 32, 32) = (SUBSTRING(sys.fn_varbintohexstr(sj.job_id), 3, 100))'
            ELSE es.program_name
       END [job_name],
       N'F:\scripts\plans\Get-QueryPlan.ps1 -ConnectionString "Server=' + @@SERVERNAME + 
       ';Trusted_Connection=True;" -PlanHandle "' 
       + CONVERT(NVARCHAR(MAX), qs.plan_handle, 1) + N'" -StartOffset ' 
       + CONVERT(NVARCHAR(MAX), er.Statement_start_offset) + N' -EndOffset ' 
       + CONVERT(NVARCHAR(MAX), er.Statement_end_offset) + N' -FilePach "F:\scripts\plans\'
       + CONVERT(NVARCHAR(MAX), NEWID()) + N'.sqlplan"' AS query_plan_send_to_file

, stat_plan=
'SELECT
qsx.query_plan
FROM
sys.dm_exec_query_statistics_xml('+ cast(er.session_id as nvarchar(22)) + ') AS qsx'

,
(
SELECT 
esws.wait_type
, esws.waiting_tasks_count
, esws.wait_time_ms
, esws.max_wait_time_ms
, esws.wait_time_ms - esws.signal_wait_time_ms AS resource_wait_time_ms -- Waiter list (SUSPENDED).
, esws.signal_wait_time_ms -- Runnable queue (RUNNABLE).
, esws.wait_time_ms AS total_wait_time_ms
, COALESCE(esws.wait_time_ms / esws.waiting_tasks_count, 0) AS avg_wait_time_ms 
FROM
sys.dm_exec_session_wait_stats AS esws
WHERE
esws.session_id = es.session_id
ORDER BY 
wait_time_ms DESC
FOR XML RAW ('wait'), TYPE
) AS session_wait_stats

FROM   sys.dm_exec_sessions es
       LEFT JOIN sys.dm_exec_requests er
            ON  er.session_id = es.session_id
                --LEFT JOIN sys.[dm_exec_connections] AS dec
                --ON dec.[session_id] = er.[session_id]
                --AND dec.[connection_id] = er.[connection_id]
                left join sys.dm_broker_activated_tasks as dbat
                on es.session_id = dbat.spid
                
       LEFT JOIN sys.dm_exec_query_stats qs
            ON  er.sql_handle = qs.sql_handle
            AND er.plan_handle = qs.plan_handle
            AND er.statement_start_offset = qs.statement_start_offset
            AND er.statement_end_offset = qs.statement_end_offset
       OUTER APPLY sys.dm_exec_input_buffer(er.session_id,er.[request_id]) AS deib
       OUTER APPLY sys.dm_exec_sql_text((er.sql_handle)) st
       
       
WHERE  last_wait_type NOT IN ('WAITFOR'
,'BROKER_RECEIVE_WAITFOR'
)

       AND es.session_id <> @@spid
       AND (es.is_user_process=1
       or dbat.spid is not null
       )
       --AND DB_NAME(er.database_id)    = 'spdb'
       -- AND	object_schema_name(st.[objectid],st.[dbid]) + '.' + object_name(st.[objectid],st.[dbid]) = 'dbo.riskev_contract_states_save'
       -- AND  es.session_id= 216
--        AND HOST_NAME = 'BD-SRV-SBLDB'
       -- AND  DB_NAME(er.database_id)           = 'bdodb'
--        and es.[login_name] LIKE '%pere%'

    -- ORDER BY er.logical_reads DESC  
	  ORDER BY ISNULL(  last_request_start_time,last_execution_time) DESC
    --  ORDER BY er.[blocking_session_id] DESC, er.[session_id] DESC
