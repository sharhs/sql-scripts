DECLARE
	@ObjectID nvarchar(MAX) = OBJECT_ID(N'');
	
;WITH column_store_row_groups
AS
(
    SELECT 
        QUOTENAME(OBJECT_SCHEMA_NAME(csrg.[object_id])) + N'.' + QUOTENAME(OBJECT_NAME(csrg.[object_id])) AS [object_name]
    ,   QUOTENAME(i.[name]) AS index_name
    ,   csrg.created_time
    ,   csrg.closed_time
    ,   csrg.partition_number
    ,   csrg.row_group_id
    ,   csrg.state_desc AS [state]
    ,   csrg.total_rows
    ,   csrg.size_in_bytes
    ,   csrg.deleted_rows
    ,   csrg.trim_reason_desc AS trim_reason
    ,   csrg.transition_to_compressed_state_desc AS transition_to_compressed_state
    ,   csrg.has_vertipaq_optimization
    ,   csrg.generation
    ,   csrg.delta_store_hobt_id
    FROM 
        sys.dm_db_column_store_row_group_physical_stats AS csrg
        INNER JOIN sys.indexes AS i
            ON csrg.[object_id] = i.[object_id]
            AND csrg.index_id = i.index_id
    WHERE
        csrg.[object_id] =  @ObjectID
        OR @ObjectID IS NULL
)

SELECT 
    [object_name]
,   index_name
,   created_time
,   closed_time
,   partition_number
,   row_group_id
,   [state]
,   total_rows
,   size_in_bytes
,   deleted_rows
,   trim_reason
,   transition_to_compressed_state
,   has_vertipaq_optimization
,   generation
,   delta_store_hobt_id
FROM
    column_store_row_groups
WHERE
    1 = 1    
ORDER BY
    [object_name]
,   index_name
,   partition_number
,   row_group_id;
GO
