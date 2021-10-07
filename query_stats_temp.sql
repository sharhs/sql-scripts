/*--Скрипт мониторинга----------------------

select top 32
       [from]= min(sqst.PeriodBeg)
      ,[to] = max(sqst.PeriodBeg)
      ,ExecCnt = sum(sqst.ExecutionCnt) 
	  ,db_name(sqst.SQLDBId) dbname
      ,object_name(sqst.SQLObjId, sqst.SQLDBId) objname
     -- ,sql_preview = ( select cast(_qt.[text] as nvarchar(512)) from   sys.dm_exec_sql_text(sqst.HSQL) as _qt )
      ,sql = ( select substring( st.text ,sqst.StmtStartOffset/2
                     ,(
                          case 
                               when sqst.StmtEndOffset=-1 then len(convert(nvarchar(max) ,st.text))*2
                               else sqst.StmtEndOffset
                          end- sqst.StmtStartOffset
                      )/2
			   ) from   sys.dm_exec_sql_text((sqst.HSQL)) st )
      ,ExecInMin = sum(sqst.ExecutionCnt)*1.0/case 
                                                   when datediff(MINUTE ,min(sqst.PeriodBeg) ,max(sqst.PeriodBeg))=0 then 
                                                        0.0001
                                                   else datediff(MINUTE ,min(sqst.PeriodBeg) ,max(sqst.PeriodBeg))
                                              end
      ,ElapsedTimeTot = sum(sqst.ElapsedTimeTot)
      ,CPUTimeTot = sum(sqst.CPUTimeTot)
      ,LogicalWrTot = sum(sqst.LogicalWrTot)
      ,LogicalRdTot = sum(sqst.LogicalRdTot)
      ,PhysicalRdTot = sum(sqst.PhysicalRdTot)
      ,sum(sqst.CPUTimeTot)/sum(sqst.ExecutionCnt) avg_cpu
      ,sum(sqst.LogicalRdTot)/sum(sqst.ExecutionCnt) avg_reads
      ,sum(sqst.ElapsedTimeTot)/sum(sqst.ExecutionCnt) avg_elapsed
      ,'SELECT CAST(detqp.[query_plan] AS XML) FROM sys.[dm_exec_text_query_plan]('+convert(nvarchar(256) ,sqst.HPlan ,1) 
      +','+cast(sqst.StmtStartOffset as nvarchar(100))+','+cast(sqst.StmtEndOffset as nvarchar(100))+') AS detqp'
      ,sqst.HPlan
      ,sqst.HSQL
      ,sqst.StmtStartOffset
      ,sqst.StmtEndOffset
from   [tempdb].[dbo].[MonSrvQueryStats_tb] as sqst
group by
       sqst.HSQL
      ,sqst.StmtStartOffset
      ,sqst.StmtEndOffset
      ,sqst.HPlan
      ,sqst.SQLDBId
      ,sqst.SQLObjId
order by
       sum(sqst.LogicalRdTot)+sum(sqst.LogicalWrTot) desc;

	
	
select top 32 
       [from]= min(sqst.PeriodBeg)
      ,[to] = max(sqst.PeriodBeg)
      ,ExecCnt = sum(sqst.ExecutionCnt)
	  ,db_name(sqst.SQLDBId)
      ,object_name(sqst.SQLObjId, sqst.SQLDBId)
     -- ,sql_preview = ( select cast(_qt.[text] as nvarchar(512)) from   sys.dm_exec_sql_text(sqst.HSQL) as _qt )
      ,sql = ( select substring( st.text ,sqst.StmtStartOffset/2
                     ,(
                          case 
                               when sqst.StmtEndOffset=-1 then len(convert(nvarchar(max) ,st.text))*2
                               else sqst.StmtEndOffset
                          end- sqst.StmtStartOffset
                      )/2
			   ) from   sys.dm_exec_sql_text((sqst.HSQL)) st )
      ,ExecInMin = sum(sqst.ExecutionCnt)*1.0/case 
                                                   when datediff(MINUTE ,min(sqst.PeriodBeg) ,max(sqst.PeriodBeg))=0 then 
                                                        0.0001
                                                   else datediff(MINUTE ,min(sqst.PeriodBeg) ,max(sqst.PeriodBeg))
                                              end
      ,ElapsedTimeTot = sum(sqst.ElapsedTimeTot)
      ,CPUTimeTot = sum(sqst.CPUTimeTot)
      ,LogicalWrTot = sum(sqst.LogicalWrTot)
      ,LogicalRdTot = sum(sqst.LogicalRdTot)
      ,PhysicalRdTot = sum(sqst.PhysicalRdTot)
      ,sum(sqst.CPUTimeTot)/sum(sqst.ExecutionCnt) avg_cpu
      ,sum(sqst.LogicalRdTot)/sum(sqst.ExecutionCnt) avg_reads
      ,sum(sqst.ElapsedTimeTot)/sum(sqst.ExecutionCnt) avg_elapsed
      ,'SELECT CAST(detqp.[query_plan] AS XML) FROM sys.[dm_exec_text_query_plan]('+convert(nvarchar(256) ,sqst.HPlan ,1) 
      +','+cast(sqst.StmtStartOffset as nvarchar(100))+','+cast(sqst.StmtEndOffset as nvarchar(100))+') AS detqp'
      ,sqst.HPlan
      ,sqst.HSQL
      ,sqst.StmtStartOffset
      ,sqst.StmtEndOffset
from   [tempdb].[dbo].[MonSrvQueryStats_tb] as sqst
group by
       sqst.HSQL
      ,sqst.StmtStartOffset
      ,sqst.StmtEndOffset
      ,sqst.HPlan
      ,sqst.SQLDBId
      ,sqst.SQLObjId
order by
       sum(sqst.CPUTimeTot) desc;		
	
------------------------------------------*/

SET NOCOUNT ON;

BEGIN TRY
	CREATE TABLE [tempdb].[dbo].[MonSrvQueryStats_tb]
	(	[PeriodBeg] [datetime2](0) NOT NULL,
		[PeriodEnd] [datetime2](0) NOT NULL,
		[CreationTime] [datetime2](3) NOT NULL,
		[ExecutionTimeLast] [datetime2](3) NOT NULL,
		[HSQL] [varbinary](64) NOT NULL,
		[StmtStartOffset] [int] NOT NULL,
		[StmtEndOffset] [int] NOT NULL,
		[HPlan] [varbinary](64) NOT NULL,
		[SQLDBId] INT NULL,
		[SQLObjId] INT NULL,
		[ExecutionCnt] [bigint] NOT NULL,
		[ElapsedTimeTot] [bigint] NOT NULL,
		[ElapsedTimeMin] [bigint] NOT NULL,
		[ElapsedTimeMax] [bigint] NOT NULL,
		[CPUTimeTot] [bigint] NOT NULL,
		[CPUTimeMin] [bigint] NOT NULL,
		[CPUTimeMax] [bigint] NOT NULL,
		[LogicalWrTot] [bigint] NOT NULL,
		[LogicalWrMin] [bigint] NOT NULL,
		[LogicalWrMax] [bigint] NOT NULL,
		[LogicalRdTot] [bigint] NOT NULL,
		[LogicalRdMin] [bigint] NOT NULL,
		[LogicalRdMax] [bigint] NOT NULL,
		[PhysicalRdTot] [bigint] NOT NULL,
		[PhysicalRdMin] [bigint] NOT NULL,
		[PhysicalRdMax] [bigint] NOT NULL
	);
	
END TRY
BEGIN CATCH
	TRUNCATE TABLE [tempdb].[dbo].[MonSrvQueryStats_tb];
END CATCH;

begin try
	DROP TABLE [tempdb].[dbo].[sys.dm_exec_query_stats];
end try
begin catch end catch;

begin try
	DROP TABLE #sys_dm_exec_query_stats_now;
end try
begin catch end catch;


SELECT
	[at] = CAST(SYSDATETIME() AS DATETIME2(0))
,	eqs.creation_time
,	eqs.last_execution_time
,	eqs.sql_handle
,	eqs.statement_start_offset
,	eqs.statement_end_offset
,	eqs.plan_handle
,	statement_db_id = qa.[db_id]
,	statement_object_id = qa.[object_id]
,	eqs.execution_count
,	eqs.total_elapsed_time
,	eqs.min_elapsed_time
,	eqs.max_elapsed_time
,	eqs.total_worker_time 
,	eqs.min_worker_time
,	eqs.max_worker_time
,	eqs.total_logical_writes
,	eqs.min_logical_writes
,	eqs.max_logical_writes
,	eqs.total_logical_reads
,	eqs.min_logical_reads
,	eqs.max_logical_reads
,	eqs.total_physical_reads
,	eqs.min_physical_reads
,	eqs.max_physical_reads
INTO [tempdb].[dbo].[sys.dm_exec_query_stats]
FROM
	sys.dm_exec_query_stats AS eqs
OUTER APPLY
	(	SELECT	TOP 1
			[db_id] = [dbid], [object_id] = objectid 
		FROM	sys.dm_exec_sql_text(eqs.sql_handle) _q
	) AS qa	
-- WHERE
-- 	eqs.last_execution_time >= ?
--OR	CAST(1 AS BIT) = ?
;

SELECT	TOP 1 *
INTO	#sys_dm_exec_query_stats_now
FROM	[tempdb].[dbo].[sys.dm_exec_query_stats]

CREATE CLUSTERED INDEX [sys_dm_exec_query_stats_pk] ON [tempdb].[dbo].[sys.dm_exec_query_stats]
(	[last_execution_time] DESC
,	[sql_handle] ASC
,	[creation_time] ASC 
,	[statement_start_offset] ASC
,	[statement_end_offset] ASC
,	[at] DESC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
-------------------------------------------------
GO

WAITFOR DELAY '00:00:20';

DECLARE @PeriodBeg DATETIME2(0) = (SELECT TOP 1 at FROM #sys_dm_exec_query_stats_now);

DELETE FROM #sys_dm_exec_query_stats_now;

DECLARE @PeriodEnd DATETIME2(0) = SYSDATETIME();

INSERT INTO #sys_dm_exec_query_stats_now
(	[at]
,	creation_time
,	last_execution_time
,	sql_handle
,	statement_start_offset
,	statement_end_offset
,	plan_handle
,	statement_db_id 
,	statement_object_id 
,	execution_count
,	total_elapsed_time
,	min_elapsed_time
,	max_elapsed_time
,	total_worker_time 
,	min_worker_time
,	max_worker_time
,	total_logical_writes
,	min_logical_writes
,	max_logical_writes
,	total_logical_reads
,	min_logical_reads
,	max_logical_reads
,	total_physical_reads
,	min_physical_reads
,	max_physical_reads)
SELECT
	[at] = @PeriodEnd
,	eqs.creation_time
,	eqs.last_execution_time
,	eqs.sql_handle
,	eqs.statement_start_offset
,	eqs.statement_end_offset
,	eqs.plan_handle
,	sql_db_id = qa.[db_id]
,	sql_object_id = qa.[object_id]
,	eqs.execution_count
,	eqs.total_elapsed_time
,	eqs.min_elapsed_time
,	eqs.max_elapsed_time
,	eqs.total_worker_time 
,	eqs.min_worker_time
,	eqs.max_worker_time
,	eqs.total_logical_writes
,	eqs.min_logical_writes
,	eqs.max_logical_writes
,	eqs.total_logical_reads
,	eqs.min_logical_reads
,	eqs.max_logical_reads
,	eqs.total_physical_reads
,	eqs.min_physical_reads
,	eqs.max_physical_reads
FROM
	sys.dm_exec_query_stats AS eqs
OUTER APPLY
	(	SELECT	TOP 1
			[db_id] = [dbid], [object_id] = objectid 
		FROM	sys.dm_exec_sql_text(eqs.sql_handle) _q
	) AS qa	
WHERE
	eqs.last_execution_time >= @PeriodBeg
;

INSERT INTO [tempdb].[dbo].[MonSrvQueryStats_tb]
(	PeriodBeg
,	PeriodEnd
,	CreationTime
,	ExecutionTimeLast
,	HSQL
,	StmtStartOffset
,	StmtEndOffset
,	HPlan
,   [SQLDBId] 
,   [SQLObjId]
,	ExecutionCnt
,	ElapsedTimeTot
,	ElapsedTimeMin
,	ElapsedTimeMax
,	CPUTimeTot
,	CPUTimeMin
,	CPUTimeMax
,	LogicalWrTot
,	LogicalWrMin
,	LogicalWrMax
,	LogicalRdTot
,	LogicalRdMin
,	LogicalRdMax
,	PhysicalRdTot
,	PhysicalRdMin
,	PhysicalRdMax)
SELECT
	[PeriodBeg] = @PeriodBeg
,	[PeriodEnd] = @PeriodEnd
,	[CreationTime] = f.creation_time
,	[ExecutionTimeLast] = f.last_execution_time
,	[HSQL] = f.[sql_handle]
,	[StmtStartOffset]  = f.statement_start_offset
,	[StmtEndOffset] = f.statement_end_offset
,	[HPlan] = f.plan_handle
,   f.statement_db_id 
,	f.statement_object_id 
,	[ExecutionCnt] = CASE WHEN f.execution_count IS NULL THEN p.execution_count WHEN p.execution_count IS NULL THEN f.execution_count WHEN f.execution_count IS NOT NULL AND p.execution_count IS NOT NULL THEN f.execution_count - p.execution_count END
,	[ElapsedTimeTot] = CASE WHEN f.total_elapsed_time IS NULL THEN p.total_elapsed_time WHEN p.total_elapsed_time IS NULL THEN f.total_elapsed_time WHEN f.total_elapsed_time IS NOT NULL AND p.total_elapsed_time IS NOT NULL THEN f.total_elapsed_time - p.total_elapsed_time END
,	[ElapsedTimeMin] = f.min_elapsed_time
,	[ElapsedTimeMax] = f.max_elapsed_time
,	[CPUTimeTot] = CASE WHEN f.total_worker_time IS NULL THEN p.total_worker_time WHEN p.total_worker_time IS NULL THEN f.total_worker_time WHEN f.total_worker_time IS NOT NULL AND p.total_worker_time IS NOT NULL THEN f.total_worker_time - p.total_worker_time END
,	[CPUTimeMin] = f.min_worker_time
,	[CPUTimeMax] = f.max_worker_time
,	[LogicalWrTot] = CASE WHEN f.total_logical_writes IS NULL THEN p.total_logical_writes WHEN p.total_logical_writes IS NULL THEN f.total_logical_writes WHEN f.total_logical_writes IS NOT NULL AND p.total_logical_writes IS NOT NULL THEN f.total_logical_writes - p.total_logical_writes END
,	[LogicalWrMin] = f.min_logical_writes
,	[LogicalWrMax] = f.max_logical_writes
,	[LogicalRdTot] = CASE WHEN f.total_logical_reads IS NULL THEN p.total_logical_reads WHEN p.total_logical_reads IS NULL THEN f.total_logical_reads WHEN f.total_logical_reads IS NOT NULL AND p.total_logical_reads IS NOT NULL THEN f.total_logical_reads - p.total_logical_reads END
,	[LogicalRdMin] = f.min_logical_reads
,	[LogicalRdMax] = f.max_logical_reads
,	[PhysicalRdTot] = CASE WHEN f.total_physical_reads IS NULL THEN p.total_physical_reads WHEN p.total_physical_reads IS NULL THEN f.total_physical_reads WHEN f.total_physical_reads IS NOT NULL AND p.total_physical_reads IS NOT NULL THEN f.total_physical_reads - p.total_physical_reads END
,	[PhysicalRdMin] = f.min_physical_reads
,	[PhysicalRdMax] = f.max_physical_reads
FROM
	#sys_dm_exec_query_stats_now f
OUTER APPLY
(	SELECT	TOP 1 
		*
 	FROM	[tempdb].[dbo].[sys.dm_exec_query_stats] _p
	WHERE 
 		_p.[sql_handle] = f.[sql_handle]
	AND	_p.statement_start_offset = f.statement_start_offset
	AND	_p.statement_end_offset = f.statement_end_offset
	AND	_p.plan_handle = f.plan_handle
	AND	_p.creation_time = f.creation_time
 	ORDER BY
 		_p.[last_execution_time] DESC
) AS p;


--SET NOCOUNT OFF;

INSERT INTO [tempdb].[dbo].[sys.dm_exec_query_stats]
SELECT * FROM #sys_dm_exec_query_stats_now;

-- SET NOCOUNT ON;

GO 100
