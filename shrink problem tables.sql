/*
Author: Eitan Blumin | https://www.eitanblumin.com
Create Date: 2020-03-18
Description:
  This script will detect tables in your database that may cause DBCC SHRINK operations
  to run really slow:
    – Tables with LOB_DATA or ROW_OVERFLOW_DATA
    – Heap tables with non-clustered indexes
    – Heap tables with partitions
  
  You may adjust the @TableSizeThresholdMB parameter to filter the tables based on their size.
*/
DECLARE
	@TableSizeThresholdMB INT = 500


;WITH TabsCTE
AS
(
SELECT  DISTINCT
	'Table with LOB or ROW-OVERFLOW data' AS Issue,
	p.object_id
FROM    sys.system_internals_allocation_units au
JOIN    sys.partitions p ON au.container_id = p.partition_id
WHERE type_desc <> 'IN_ROW_DATA' AND total_pages > 8
AND p.rows > 0

UNION ALL

SELECT
	'Heap with Non-clustered indexes',
	p.object_id
FROM	sys.partitions AS p
WHERE	p.index_id = 0
AND p.rows > 0
AND EXISTS (SELECT NULL FROM sys.indexes AS ncix WHERE ncix.object_id = p.object_id AND ncix.index_id > 1)

UNION ALL

SELECT DISTINCT
	'Partitioned Heap',
	p.object_id
FROM	sys.partitions AS p
WHERE	p.index_id = 0
AND p.rows > 0
AND p.partition_number > 1
)
SELECT t.*,
fg.name fgname,
OBJECT_SCHEMA_NAME(t.object_id) table_schema,
OBJECT_NAME(t.object_id) table_name,
SUM(p.rows) AS RowCounts,
CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB,
CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB,
CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Total_MB
FROM TabsCTE AS t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.filegroups AS fg ON a.data_space_id = fg.data_space_id
--where fg.name = 'MDWH_RAW_202208'
GROUP BY t.Issue, t.object_id, fg.name
HAVING SUM(a.used_pages) / 128.00 >= @TableSizeThresholdMB
ORDER BY Used_MB DESC
