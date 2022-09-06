SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

select  st.[text] as [Command Text] ,
        [host_name] ,
        login_name ,
        case left(s.program_name, 29)
          when 'SQLAgent - TSQL JobStep (Job '
          then 'SQLAgent Job: '
               + ( select   name
                   from     msdb..sysjobs sj ( nolock )
                   where    substring(s.program_name, 32, 32) = ( substring(sys.fn_varbintohexstr(sj.job_id),
                                                              3, 100) )
                 ) + ' - ' + substring(s.program_name, 67,
                                       len(s.program_name) - 67)
          else s.program_name
        end [running_program_info] ,
        r.total_elapsed_time / 1000. / 60 minutes_running ,
        r.total_elapsed_time / 1000. / 60 / 60 hours_running ,
        r.session_id as [SPID] ,
        r.blocking_session_id blocking_SPID ,
        r.[status] ,
        db_name(r.database_id) as [DatabaseName],
        isnull(r.wait_type, N'None') as [Wait Type],
        r.logical_reads ,
        r.cpu_time,
             eqp.query_plan
from    sys.dm_exec_requests as r with ( nolock )
        outer apply ( select top 1
                                *
                      from      sys.dm_exec_connections as c with ( nolock )
                      where     r.session_id = c.session_id
                    ) c
        left join sys.dm_exec_sessions as s with ( nolock ) on s.session_id = r.session_id
        outer apply sys.dm_exec_sql_text(sql_handle) as st
             OUTER APPLY sys.dm_exec_query_plan ([r].[plan_handle]) [eqp] 
where   r.session_id > 50
        and r.session_id <> @@SPID
        and s.is_user_process = 1
        and ( wait_type is null
              or wait_type <> 'waitfor'
              and wait_type <> 'BROKER_RECEIVE_WAITFOR'
              and wait_type <> 'TRACEWRITE'
            )
order by r.total_elapsed_time desc

SELECT
    [owt].[session_id],
       es.login_name,
    [owt].[wait_duration_ms]/1000. [wait_duration_s],
    [owt].[wait_type],
    [owt].[blocking_session_id],
    [owt].[resource_description],
    CASE [owt].[wait_type]
        WHEN N'CXPACKET' THEN
            RIGHT ([owt].[resource_description],
            CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
        ELSE NULL
    END AS [Node ID],
    [es].[program_name],
    [est].text,
    DB_NAME( [er].[database_id]),
--   [eqp].[query_plan],
    [er].[cpu_time]
FROM sys.dm_os_waiting_tasks [owt] (NOLOCK)
LEFT JOIN sys.dm_exec_sessions [es] (NOLOCK) ON
    [owt].[session_id] = [es].[session_id]
LEFT JOIN sys.dm_exec_requests [er] (NOLOCK) ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est] 
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp] 
WHERE
    [es].[is_user_process] = 1
       AND er.wait_type<>'WAITFOR'
ORDER BY
    [owt].[session_id],
    [owt].[exec_context_id],
       er.wait_type;
GO

