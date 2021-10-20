select top 32 @@servername                 srvname 
      ,db_name(dt.database_id)            bd_name
      ,st.session_id
      ,st.is_user_transaction
      ,datediff(MINUTE ,dt.database_transaction_begin_time ,getdate()) [diff_min]
      ,dt.database_transaction_log_bytes_used/(1024.0*1024) space_used_mb
      ,dt.database_transaction_log_bytes_reserved/(1024.0*1024) space_res_mb
      ,dest.text
      ,[procname] = object_name(dest.objectid ,dest.dbid) 
      ,[individual query] = substring(dest.text,der.statement_start_offset/2,(case when der.statement_end_offset=-1 then len(convert(nvarchar(max) ,dest.text))*2
																					else der.statement_end_offset 
                                                                              end- der.statement_start_offset)/2)               
from   sys.dm_tran_session_transactions st with (nolock)
       join sys.dm_tran_database_transactions dt with (nolock)
            on  st.transaction_id = dt.transaction_id
       join sys.dm_exec_connections    as dec
            on  dec.session_id = st.session_id
       left join sys.dm_exec_requests  as der
            on  der.session_id = dec.session_id
       outer apply sys.dm_exec_sql_text(dec.most_recent_sql_handle) as dest
-- where dec.session_id =  
order by
       space_used_mb desc
      ,space_res_mb desc
	  
/*
SELECT @@servername                                                    srvname
     , DB_NAME(database_id)                                            bd_name
     , st.session_id
     , st.is_user_transaction
     , dt.database_transaction_begin_time
     , DATEDIFF(MINUTE, dt.database_transaction_begin_time, GETDATE()) [diff_min]
     , dt.database_transaction_log_record_count
     , dt.database_transaction_log_bytes_used / (1024.0 * 1024)        space_used_mb
     , dt.database_transaction_log_bytes_reserved / (1024.0 * 1024)    space_res_mb
     , dt.database_transaction_begin_lsn
     , dt.database_transaction_commit_lsn
     , dt.database_transaction_last_lsn
     , dt.database_transaction_last_rollback_lsn
     , dest.text
FROM sys.dm_tran_session_transactions st WITH (NOLOCK)
JOIN sys.dm_tran_database_transactions dt WITH (NOLOCK)
    ON st.transaction_id = dt.transaction_id
JOIN sys.dm_exec_connections AS dec
    ON dec.session_id = st.session_id
OUTER APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) AS dest
--where dt.database_transaction_log_bytes_used > 0
--where st.session_id = 1099
ORDER BY space_used_mb DESC, space_res_mb DESC
*/
