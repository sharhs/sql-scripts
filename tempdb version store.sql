USE tempdb;
WITH file_space_usage 
     AS
     (
         SELECT 
                DB_NAME(database_id) AS [database_name]
               ,[file_id]
               ,COALESCE(total_page_count*1./128 ,0) AS total_page_mb
               ,COALESCE(unallocated_extent_page_count*1./128 ,0) AS free_space_mb
               ,COALESCE(user_object_reserved_page_count*1./128 ,0) AS user_object_mb
               ,COALESCE(internal_object_reserved_page_count*1./128 ,0) AS internal_objects_mb
               ,COALESCE(version_store_reserved_page_count*1./128 ,0) AS version_store_mb
               ,COALESCE(mixed_extent_page_count*1./128 ,0) AS mixed_extents_mb
         FROM   sys.dm_db_file_space_usage
     )

SELECT 
       [database_name]
      ,[file_id]
      ,SUM(total_page_mb)        AS total_page_mb
      ,SUM(free_space_mb)        AS free_space_mb
      ,SUM(user_object_mb)       AS user_object_mb
      ,SUM(internal_objects_mb)  AS internal_objects_mb
      ,SUM(version_store_mb)     AS version_store_mb
      ,SUM(mixed_extents_mb)     AS mixed_extents_mb
FROM   file_space_usage
GROUP BY
       GROUPING SETS(
           ()
          ,(
               [database_name]
              ,[file_id]
              ,total_page_mb
              ,free_space_mb
              ,user_object_mb
              ,internal_objects_mb
              ,version_store_mb
              ,mixed_extents_mb
           )
       )
ORDER BY
       GROUPING([file_id])
      ,[file_id];
GO

SELECT 
       tas.session_id
      ,CONVERT(TIME ,DATEADD(SECOND ,tas.elapsed_time_seconds ,0)) AS elapsed_time
      ,es.[status]
      ,es.login_name
      ,es.[host_name]
      ,es.[program_name]
      ,QUOTENAME(DB_NAME(es.database_id)) AS [database_name]
      ,QUOTENAME(OBJECT_SCHEMA_NAME(est.objectid ,est.[dbid]))+N'.'+QUOTENAME(OBJECT_NAME(est.objectid ,est.[dbid])) AS 
       [object_name]
      ,CASE 
            WHEN LEN(est.text)<(er.statement_end_offset/2)+1 THEN est.text
            WHEN SUBSTRING(est.text ,(er.statement_start_offset/2) ,2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
            ELSE CASE 
                      WHEN er.statement_start_offset>0 THEN SUBSTRING(
                               est.text
                              ,((er.statement_start_offset/2)+1)
                              ,CASE 
                                    WHEN er.statement_end_offset=-1 THEN 2147483647
                                    ELSE ((er.statement_end_offset- er.statement_start_offset)/2)+1
                               END
                           )
                      ELSE est.text
                 END
       END                              AS query_text
      ,tas.transaction_id
      ,tas.is_snapshot
      ,tas.max_version_chain_traversed
      ,tas.average_version_chain_traversed
FROM   sys.dm_tran_active_snapshot_database_transactions AS tas WITH (NOLOCK)
       INNER JOIN sys.dm_exec_sessions  AS es WITH (NOLOCK)
            ON  tas.session_id = es.session_id
       LEFT JOIN sys.dm_exec_requests   AS er WITH (NOLOCK)
            ON  er.session_id = es.session_id
       OUTER APPLY sys.dm_exec_sql_text(er.[sql_handle]) AS est
ORDER BY
       elapsed_time DESC;
GO
