DECLARE @ObjectID NVARCHAR(MAX)=OBJECT_ID(N'');

WITH [tables]
     AS
     (
         SELECT 
                t.[object_id]
               ,QUOTENAME(SCHEMA_NAME(t.[schema_id]))+N'.'+QUOTENAME(t.[name]) AS [object_name]
               ,t.[type_desc]
               ,NULL        AS internal_type_desc
         FROM   sys.tables  AS t WITH (NOLOCK)
         
         UNION ALL
         
         SELECT 
                t.[object_id]
               ,QUOTENAME(OBJECT_SCHEMA_NAME(t.parent_object_id))+N'.'+QUOTENAME(OBJECT_NAME(t.parent_object_id)) AS 
                [object_name]
               ,t.[type_desc]
               ,t.internal_type_desc
         FROM   sys.internal_tables AS t WITH (NOLOCK)
         WHERE  t.internal_type_desc = N'XML_INDEX_NODES'
     )

SELECT 
       t.[object_name]
      ,QUOTENAME(i.[name])              AS index_name
      ,t.internal_type_desc
      ,i.[type_desc]                    AS index_type_desc
      ,STUFF(
           (
               SELECT 
                      N', '+QUOTENAME(c.name)
               FROM   sys.index_columns AS ic
                      INNER JOIN sys.columns AS c
                           ON  ic.[object_id] = c.[object_id]
               AND             ic.column_id = c.column_id
               WHERE  ic.[object_id] = i.[object_id]
               AND    ic.index_id = i.index_id
               AND    ic.is_included_column = 0
               AND    ic.key_ordinal<>0
               ORDER BY
                      ic.key_ordinal 
                      FOR XML PATH('')
                     ,TYPE
           ).value('.' ,'nvarchar(MAX)')
          ,1
          ,2
          ,''
       )                                AS [columns]
      ,STUFF(
           (
               SELECT 
                      N', '+QUOTENAME(c.name)
               FROM   sys.index_columns AS ic
                      INNER JOIN sys.columns AS c
                           ON  ic.[object_id] = c.[object_id]
               AND             ic.column_id = c.column_id
               WHERE  ic.[object_id] = i.[object_id]
               AND    ic.index_id = i.index_id
               AND    ic.is_included_column = 1
               ORDER BY
                      ic.key_ordinal
                      FOR XML PATH('')
                     ,TYPE
           ).value('.' ,'nvarchar(MAX)')
          ,1
          ,2
          ,''
       )                                AS included_columns
      ,COALESCE(fg.[name] ,ps.[name])   AS file_group_name
      ,(
           SELECT 
                  QUOTENAME(c.name)
           FROM   sys.index_columns       AS ic
                  INNER JOIN sys.columns  AS c
                       ON  ic.[object_id] = c.[object_id]
           AND             ic.column_id = c.column_id
           WHERE  ic.[object_id] = i.[object_id]
           AND    ic.index_id = i.index_id
           AND    ic.partition_ordinal = 1
       )                                AS partition_column
      ,p.[rows]
      ,p.size_mb
      ,dius.user_seeks
      ,dius.user_scans
      ,dius.user_lookups
      ,dius.user_updates
      ,dius.last_user_seek
      ,dius.last_user_scan
      ,dius.last_user_lookup
      ,dius.last_user_update
      ,i.is_primary_key
      ,i.is_unique_constraint
      ,i.is_unique
      ,i.[ignore_dup_key]
      ,i.fill_factor
      ,i.is_disabled
      ,i.is_hypothetical
      ,i.[allow_row_locks]
      ,i.[allow_page_locks]
      ,i.has_filter
      ,i.filter_definition
FROM   [tables]                         AS t
       INNER JOIN sys.indexes           AS i WITH (NOLOCK)
            ON  t.[object_id] = i.[object_id]
AND             i.[type_desc]<>N'XML'
       LEFT JOIN sys.filegroups         AS fg WITH (NOLOCK)
            ON  i.data_space_id = fg.data_space_id
       LEFT JOIN sys.partition_schemes  AS ps WITH (NOLOCK)
            ON  i.data_space_id = ps.data_space_id
       LEFT JOIN sys.dm_db_index_usage_stats AS dius WITH (NOLOCK)
            ON  dius.database_id = DB_ID()
AND             i.[object_id] = dius.[object_id]
AND             i.index_id = dius.index_id
       OUTER APPLY (
    SELECT 
           SUM(au.total_pages)*1./128  AS size_mb
          ,SUM(p.[rows])               AS [rows]
    FROM   sys.partitions              AS p
           OUTER APPLY (
        SELECT 
               SUM(au.total_pages)   AS total_pages
        FROM   sys.allocation_units  AS au
        WHERE  au.container_id = p.[partition_id]
    )                                  AS au
    WHERE  p.[object_id] = i.[object_id]
    AND    p.index_id = i.index_id
)                                       AS p
WHERE  t.[object_id] = @ObjectID
OR     @ObjectID IS NULL
ORDER BY
       [object_name]
      ,index_name
	  -- p.size_mb desc
       OPTION(RECOMPILE);
GO
