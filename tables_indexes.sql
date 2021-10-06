DECLARE 
@ObjectID int = OBJECT_ID('')
, @IndexID int = NULL
, @Like NVARCHAR(255) = '%%';

SELECT 
QUOTENAME(s.[name]) + N'.' + QUOTENAME( t.[name]) AS [object_name]
, QUOTENAME(i.[name]) AS index_name
, i.[type_desc]
, au.[type_desc]
, p.[rows]
, au.total_pages * 1. / 128 AS size_mb
, au.used_pages * 1. / 128 AS used_size_mb
, au.data_pages * 1. / 128 AS data_size_mb
, p.partition_number
, data_comperss = CASE WHEN p.data_compression_desc = 'NONE' THEN '-'
    ELSE p.data_compression_desc  END
, mf.state_desc AS file_state_desc
, fg.[name] AS file_group_name
, ps.[name] AS scheme_name
, pf.[name] AS function_name
,(
SELECT 
QUOTENAME(c.name)
FROM 
sys.index_columns AS ic
INNER JOIN sys.columns AS c
ON ic.[object_id] = c.[object_id]
AND ic.column_id = c.column_id
WHERE 
ic.[object_id] = i.[object_id]
AND ic.index_id = i.index_id
AND ic.partition_ordinal = 1
) AS partitin_column
, CASE pf.boundary_value_on_right
WHEN 0 then 'Left'
WHEN 1 then 'Right'
END AS boundary_value
, prv.[value] AS range_value
FROM
sys.tables AS t WITH (NOLOCK)
INNER JOIN sys.schemas AS s WITH (NOLOCK)
ON t.[schema_id] = s.[schema_id] 
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON t.[object_id] = i.[object_id]
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON i.[object_id] = p.[object_id]
AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS au WITH (NOLOCK)
ON p.hobt_id = au.container_id
INNER JOIN sys.filegroups AS fg WITH (NOLOCK)
ON au.data_space_id = fg.data_space_id
INNER JOIN sys.master_files AS mf
ON fg.data_space_id = mf.data_space_id
AND mf.database_id = DB_ID()
LEFT JOIN sys.partition_schemes AS ps WITH (NOLOCK)
ON i.data_space_id = ps.data_space_id 
LEFT JOIN sys.partition_functions AS pf WITH (NOLOCK) 
ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values AS prv WITH (NOLOCK)
ON pf.function_id = prv.function_id
AND p.partition_number = CASE
WHEN pf.boundary_value_on_right = 1 THEN prv.boundary_id + 1
ELSE prv.boundary_id
END
WHERE
    (i.[object_id] = @ObjectID OR @ObjectID IS NULL)
AND (i.index_id = @IndexID OR @IndexID IS NULL)
AND (QUOTENAME(s.[name]) + N'.' + QUOTENAME( t.[name]) like @Like OR @Like IS NULL)

ORDER BY  
--   i.[type_desc], i.[name], p.[partition_number]  
 size_mb DESC

OPTION (RECOMPILE);
GO
