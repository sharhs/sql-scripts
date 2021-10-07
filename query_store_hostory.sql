DECLARE @time DATETIME = GETDATE() 
		,@minus INT = -30
		,@object_name SYSNAME = NULL --  '[dbo].[rests_recalc]' 
		
DECLARE @DateEnd       DATETIMEOFFSET=CONVERT(DATETIME ,@time) AT TIME ZONE 'Russian Standard Time' AT TIME ZONE 'UTC';
DECLARE @DateStart     DATETIMEOFFSET=CONVERT(DATETIME ,DATEADD(minute, @minus,@time)) AT TIME ZONE 'Russian Standard Time' AT TIME ZONE 'UTC';


; WITH qs AS 
(
         SELECT rsi.start_time AT TIME ZONE 'Russian Standard Time' AS start_time
               ,rsi.end_time AT TIME ZONE 'Russian Standard Time' AS end_time
               ,cast(rs.first_execution_time AT TIME ZONE 'Russian Standard Time'as datetime) AS first_execution_time
               ,cast(rs.last_execution_time AT TIME ZONE 'Russian Standard Time'as datetime) AS last_execution_time
               ,cnt = rs.count_executions
               ,QUOTENAME(OBJECT_SCHEMA_NAME(q.[object_id]))+N'.'+QUOTENAME(OBJECT_NAME(q.[object_id])) AS [object_name]
               ,qt.query_sql_text
               ,qt.[query_text_id]
               ,[avg_dur_ms] = rs.avg_duration/1000
               ,[sum_dur_ms] = (rs.avg_duration/1000)*rs.count_executions
               ,[sum_tmp_used] = (rs.[avg_tempdb_space_used]/128)*rs.count_executions
               ,rs.avg_cpu_time
               ,avg_lg_reads = rs.avg_logical_io_reads
               ,avg_lg_writes = rs.avg_logical_io_writes
               ,avg_ph_reads = rs.avg_physical_io_reads
               ,[avg_tmp_used_mb] = rs.[avg_tempdb_space_used]/128
               ,sum_cpu_time = rs.avg_cpu_time*rs.count_executions
               
               ,sum_logical_io_reads = rs.avg_logical_io_reads*rs.count_executions
               ,sum_logical_io_writes = rs.avg_logical_io_writes*rs.count_executions
               ,sum_physical_io_reads = rs.avg_physical_io_reads*rs.count_executions
               ,[sum_tempdb_space_used mb] = rs.[avg_tempdb_space_used]/128*rs.count_executions
               ,[last_duration_ms] = rs.last_duration/1000
               ,[min_duration_ms] = rs.min_duration/1000
               ,[max_duration_ms] = rs.[max_duration]/1000
               ,[stdev_duration_ms] = rs.stdev_duration/1000
               ,rs.avg_rowcount
               ,rs.last_cpu_time
               ,rs.min_cpu_time
               ,rs.max_cpu_time
               ,rs.stdev_cpu_time
               ,rs.last_logical_io_reads
               ,rs.min_logical_io_reads
               ,rs.max_logical_io_reads
               ,rs.stdev_logical_io_reads
               ,rs.last_logical_io_writes
               ,rs.min_logical_io_writes
               ,rs.max_logical_io_writes
               ,rs.stdev_logical_io_writes
               ,rs.last_physical_io_reads
               ,rs.min_physical_io_reads
               ,rs.max_physical_io_reads
               ,rs.stdev_physical_io_reads
               ,rs.avg_clr_time
               ,rs.last_clr_time
               ,rs.min_clr_time
               ,rs.max_clr_time
               ,rs.stdev_clr_time
               ,rs.avg_dop
               ,rs.last_dop
               ,rs.min_dop
               ,rs.max_dop
               ,rs.stdev_dop
               ,rs.last_rowcount
               ,rs.min_rowcount
               ,rs.max_rowcount
               ,rs.stdev_rowcount
               ,rs.avg_query_max_used_memory
               ,rs.last_query_max_used_memory
               ,rs.min_query_max_used_memory
               ,rs.max_query_max_used_memory
               ,rs.stdev_query_max_used_memory
               ,[last_tempdb_space_used mb] = rs.[last_tempdb_space_used]/128
               ,[min_tempdb_space_used mb] = rs.[min_tempdb_space_used]/128
               ,[max_tempdb_space_used mb] = rs.[max_tempdb_space_used]/128
               ,[stdev_tempdb_space_used mb] = rs.[stdev_tempdb_space_used]/128
               ,N'SELECT
CONVERT(xml, query_plan) AS query_plan
FROM
sys.query_store_plan
WHERE 
plan_id = '+CONVERT(NVARCHAR(MAX) ,rs.plan_id)+N';' AS query_plan
               ,
                N'SELECT 
qsws.wait_category_desc
, qsws.execution_type_desc
, qsws.avg_query_wait_time_ms
, qsws.total_query_wait_time_ms
, qsws.last_query_wait_time_ms
, qsws.min_query_wait_time_ms
, qsws.max_query_wait_time_ms
, qsws.stdev_query_wait_time_ms
FROM 
sys.query_store_wait_stats as qsws
WHERE
qsws.plan_id = '+CONVERT(NVARCHAR(MAX) ,rs.plan_id)+'
AND qsws.runtime_stats_interval_id = '+CONVERT(NVARCHAR(MAX) ,rsi.runtime_stats_interval_id)+N';' AS wait_stats
         FROM   sys.query_store_runtime_stats AS rs
                INNER JOIN sys.query_store_runtime_stats_interval AS rsi
                     ON  rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
                INNER JOIN sys.query_store_plan AS p
                     ON  rs.plan_id = p.plan_id
                INNER JOIN sys.query_store_query AS q
                     ON  p.query_id = q.query_id
                INNER JOIN sys.query_store_query_text AS qt
                     ON  q.query_text_id = qt.query_text_id
     ) 

SELECT cast(q.start_time as datetime) start_time, cast(q.end_time as datetime) end_time, q.first_execution_time, q.cnt, q.[object_name],
       q.query_sql_text, q.query_text_id, q.avg_dur_ms, q.sum_dur_ms,
       q.sum_tmp_used, q.avg_cpu_time, q.avg_lg_reads , q.avg_lg_writes,
       q.avg_ph_reads, q.avg_tmp_used_mb, q.sum_cpu_time, q.sum_logical_io_reads,
       q.sum_logical_io_writes, q.sum_physical_io_reads,
       q.[sum_tempdb_space_used mb], q.last_duration_ms, q.min_duration_ms,
       q.max_duration_ms, q.stdev_duration_ms, q.avg_rowcount, q.last_cpu_time,
       q.min_cpu_time, q.max_cpu_time, q.stdev_cpu_time, q.last_logical_io_reads,
       q.min_logical_io_reads, q.max_logical_io_reads, q.stdev_logical_io_reads,
       q.last_logical_io_writes, q.min_logical_io_writes, q.max_logical_io_writes,
       q.stdev_logical_io_writes, q.last_physical_io_reads,
       q.min_physical_io_reads, q.max_physical_io_reads, q.stdev_physical_io_reads,
       q.avg_clr_time, q.last_clr_time, q.min_clr_time, q.max_clr_time,
       q.stdev_clr_time, q.avg_dop, q.last_dop, q.min_dop, q.max_dop, q.stdev_dop,
       q.last_rowcount, q.min_rowcount, q.max_rowcount, q.stdev_rowcount,
       q.avg_query_max_used_memory, q.last_query_max_used_memory,
       q.min_query_max_used_memory, q.max_query_max_used_memory,
       q.stdev_query_max_used_memory, q.[last_tempdb_space_used mb],
       q.[min_tempdb_space_used mb], q.[max_tempdb_space_used mb],
       q.[stdev_tempdb_space_used mb], q.query_plan, q.wait_stats
FROM   qs AS q
WHERE  q.start_time>=@DateStart
AND    q.start_time<@DateEnd
AND   ( q.[object_name] = @object_name
OR  @object_name IS NULL)
ORDER BY sum_logical_io_reads DESC
        --  avg_physical_io_reads * count_executions DESC;
GO
