DECLARE
	@ObjectID int = OBJECT_ID(N'');
	
;WITH column_store_segments
AS
(
    SELECT 
        QUOTENAME(OBJECT_SCHEMA_NAME(i.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(i.[object_id])) AS [object_name]
    ,   QUOTENAME(i.[name]) AS index_name
    ,   p.partition_number
    ,   css.segment_id
    ,   css.column_id
    ,   c.[name] AS column_name
    ,   css.row_count
    ,   css.on_disk_size
    ,   css.has_nulls
    ,   css.null_value
    ,   css.encoding_type
    ,   css.min_data_id
    ,   css.max_data_id
    FROM   
        sys.column_store_segments AS css
        INNER JOIN sys.partitions AS p 
            ON css.[partition_id] = p.[partition_id]
        INNER JOIN sys.indexes AS i
            ON p.[object_id] = i.[object_id] 
            AND p.index_id = i.index_id
        LEFT JOIN sys.index_columns AS ic 
            ON i.index_id = ic.index_id 
            AND i.[object_id] = ic.[object_id] 
            AND css.column_id = ic.index_column_id
        LEFT JOIN sys.columns AS c
            ON ic.column_id = c.column_id
            AND ic.[object_id] = c.[object_id]
    WHERE
        i.[object_id] =  @ObjectID
        OR @ObjectID IS NULL
)

SELECT 
    [object_name]
,   index_name
,   partition_number
,   segment_id
,   column_id
,   column_name
,   row_count
,   on_disk_size
,   has_nulls
,   encoding_type
,   min_data_id
,   max_data_id
FROM
    column_store_segments
ORDER BY 
    [object_name]
,   index_name
,   partition_number
,   segment_id
,   column_id;
GO
