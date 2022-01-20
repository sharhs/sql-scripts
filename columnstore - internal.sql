DECLARE
	@ObjectID nvarchar(MAX) = OBJECT_ID(N'');

WITH internal_partitions
AS
(
    SELECT 
        QUOTENAME(OBJECT_SCHEMA_NAME(i.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(i.[object_id])) AS [object_name]
    ,   QUOTENAME(i.[name]) AS index_name
    ,   [ip].partition_number
    ,   [ip].internal_object_type_desc AS internal_object_type
    ,   [ip].[rows]
    ,   [ip].data_compression_desc AS [data_compression]
    ,   [ip].row_group_id
    ,   [ip].hobt_id
    FROM 
        sys.internal_partitions AS [ip]
        INNER JOIN sys.indexes AS i
            ON [ip].[object_id] = i.[object_id] 
            AND [ip].index_id = i.index_id
    WHERE
        i.[object_id] =  @ObjectID
        OR @ObjectID IS NULL
)

SELECT
    [object_name]
,   index_name
,   partition_number
,   internal_object_type
,   [rows]
,   [data_compression]
,   row_group_id
,   hobt_id
FROM
    internal_partitions
ORDER BY
    [object_name]
,   index_name
,   partition_number;
GO
