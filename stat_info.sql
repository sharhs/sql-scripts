DECLARE @ObjectID int = OBJECT_ID('');

SELECT
QUOTENAME(OBJECT_SCHEMA_NAME(s.[object_id])) + N'.' + QUOTENAME(OBJECT_NAME(s.[object_id])) AS [object_name]
, QUOTENAME(s.[name]) AS stats_name
, N'UPDATE STATISTICS ' + QUOTENAME(OBJECT_SCHEMA_NAME(s.[object_id])) + N'.' + QUOTENAME(OBJECT_NAME(s.[object_id])) + N' (' + QUOTENAME(s.[name]) + N');' AS [statement]
, sp.last_updated
, p.[rows]
, sp.[rows] AS stat_rows
, sp.[rows_sampled] AS stat_rows_sampled
, sp.steps
, sp.unfiltered_rows
, sp.modification_counter
, sp.persisted_sample_percent 
, CONVERT(numeric(32, 2), sp.[rows_sampled] * 100. / sp.[rows]) AS sample_percent
, s.auto_created
, s.user_created
, s.no_recompute
, s.has_filter
, s.filter_definition
, s.is_temporary
, s.is_incremental
, N'SELECT
*
FROM
sys.dm_db_stats_histogram(' + CONVERT(nvarchar(10), s.[object_id]) + N', ' + CONVERT(nvarchar(10), s.stats_id) + N')
ORDER BY
stats_id;' AS stats_histogram
, N'DBCC SHOW_STATISTICS(''' + QUOTENAME(OBJECT_SCHEMA_NAME(s.[object_id])) + N'.' + QUOTENAME(OBJECT_NAME(s.[object_id])) + N''', ''' + s.[name] + ''');' AS [show_statistics]
FROM
sys.[stats] AS s
INNER JOIN sys.objects AS o
ON s.[object_id] = o.[object_id]
INNER JOIN (
SELECT
p.[object_id]
, SUM([rows]) AS [rows] 
FROM
sys.partitions AS p
WHERE 
p.index_id IN (0, 1)
GROUP BY 
p.[object_id]
) AS p
ON o.[object_id] = p.[object_id]
CROSS APPLY sys.dm_db_stats_properties(s.[object_id], s.stats_id) AS sp
WHERE
(s.[object_id] = @ObjectID
OR @ObjectID IS NULL)
AND o.[type] IN (N'U', N'V')
--AND s.auto_created = 0
ORDER BY sp.last_updated DESC
OPTION (RECOMPILE);
GO
