select st.dbid           as QueryExecutionContextDBID
      ,db_name(st.dbid)  as QueryExecContextDBNAME
      ,st.objectid       as ModuleObjectId
      ,substring(
           st.TEXT
          ,dmv_er.statement_start_offset/2+1
          ,(
               case 
                    when dmv_er.statement_end_offset=-1 then len(convert(nvarchar(max) ,st.TEXT))*2
                    else dmv_er.statement_end_offset
               end- dmv_er.statement_start_offset
           )/2
       )                 as Query_Text
      ,dmv_tsu.session_id
      ,dmv_tsu.request_id
      ,dmv_tsu.exec_context_id
      ,(
           dmv_tsu.user_objects_alloc_page_count- dmv_tsu.user_objects_dealloc_page_count
       )/128             as OutStanding_user_objects_page_MB
      ,(
           dmv_tsu.internal_objects_alloc_page_count- dmv_tsu.internal_objects_dealloc_page_count
       )/128             as OutStanding_internal_objects_page_Mb
      ,dmv_er.start_time
      ,dmv_er.command
      ,dmv_er.open_transaction_count
      ,dmv_er.percent_complete
      ,dmv_er.estimated_completion_time
      ,dmv_er.cpu_time
      ,dmv_er.total_elapsed_time
      ,dmv_er.reads
      ,dmv_er.writes
      ,dmv_er.logical_reads
      ,dmv_er.granted_query_memory
      ,dmv_es.HOST_NAME
      ,dmv_es.login_name
      ,dmv_es.program_name
from   sys.dm_db_task_space_usage dmv_tsu
       inner join sys.dm_exec_requests dmv_er
            on  (
                    dmv_tsu.session_id=dmv_er.session_id
                and dmv_tsu.request_id=dmv_er.request_id
                )
       inner join sys.dm_exec_sessions dmv_es
            on  (dmv_tsu.session_id=dmv_es.session_id)
       cross apply sys.dm_exec_sql_text(dmv_er.sql_handle) st
where  (
           dmv_tsu.internal_objects_alloc_page_count+dmv_tsu.user_objects_alloc_page_count
       )>0
order by
       (
           dmv_tsu.user_objects_alloc_page_count- dmv_tsu.user_objects_dealloc_page_count
       )+(
           dmv_tsu.internal_objects_alloc_page_count- dmv_tsu.internal_objects_dealloc_page_count
       ) desc
