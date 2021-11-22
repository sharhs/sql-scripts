DECLARE @sessid INT= 
       
SELECT 
       er.blocking_session_id AS blck
      ,DB_NAME(er.database_id)
      ,es.[last_request_start_time]
      ,er.[sql_handle]
      ,er.reads
      ,er.writes
      ,er.logical_reads
      ,er.open_transaction_count
      ,*
FROM   sys.dm_exec_sessions es
       LEFT JOIN sys.dm_exec_requests er
            ON  er.session_id = es.session_id
WHERE  es.session_id = @sessid
       
       DBCC INPUTBUFFER(@sessid)
       
       
SELECT 
       *
FROM   sys.[dm_os_waiting_tasks] AS dowt
WHERE  dowt.[session_id] = @sessid
