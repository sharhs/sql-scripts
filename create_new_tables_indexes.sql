create or alter procedure [dbo].[ASW_create_new_tables_indexes]
		 @table sysname 
		,@ps_name sysname 
		,@ps_colname sysname 
as

BEGIN TRY
set NOCOUNT ON

        
DECLARE @tableid int
DECLARE @schemaName sysname
DECLARE @sql nvarchar(max),@tblcr NVARCHAR(MAX) = ''
DECLARE @table_tmp sysname
DECLARE @msg NVARCHAR(max);

SELECT
	@table_tmp = @table + '_ASW'


SELECT
	@tableid = OBJECT_ID(@table)
SELECT
	@schemaName = OBJECT_SCHEMA_NAME(@tableid)


select @ps_name = 'ASW_' + @ps_name


/*
drop table #create_ind
*/


SET @sql = ';WITH index_column AS 
(SELECT ic.[object_id], ic.index_id, ic.is_descending_key, ic.is_included_column, c.name
FROM sys.index_columns ic 
JOIN sys.columns c ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
WHERE ic.[object_id] = ' + CAST(@tableid AS VARCHAR) + '
),
fk_columns AS (SELECT k.constraint_object_id, cname = c.name, rcname = rc.name
FROM sys.foreign_key_columns k  
JOIN sys.columns rc   ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id 
JOIN sys.columns c   ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
WHERE k.parent_object_id = ' + CAST(@tableid AS VARCHAR) + ')
SELECT @tblcr_tmp= ''CREATE TABLE '' + ''' + @table_tmp + ''' + ''('' + STUFF((SELECT CHAR(9) + '', ['' + c.name + ''] '' + CASE WHEN c.is_computed = 1 THEN ''AS '' + cc.[definition] + CASE WHEN cc.is_persisted = 1 THEN''PERSISTED'' ELSE '''' END ELSE UPPER(tp.name) +  CASE WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
THEN ''('' + CASE WHEN c.max_length = -1 THEN ''MAX'' ELSE CAST(c.max_length AS VARCHAR(5)) END + '')'' WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'') THEN ''('' + CASE WHEN c.max_length = -1 THEN ''MAX'' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + '')'' WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'') 
THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')'' WHEN tp.name IN( ''decimal'',''numeric'') THEN ''('' + CAST(c.[precision] AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')'' ELSE '''' END +
CASE WHEN c.collation_name IS NOT NULL THEN '' COLLATE '' + c.collation_name ELSE '''' END + CASE WHEN c.is_nullable = 1 THEN '' NULL'' ELSE '' NOT NULL'' END + CASE WHEN dc.[definition] IS NOT NULL THEN '' DEFAULT'' + dc.[definition] ELSE '''' END + 
CASE WHEN ic.is_identity = 1 THEN '' IDENTITY('' + CAST(ISNULL(ic.seed_value, ''0'') AS CHAR(1)) + '','' + CAST(ISNULL(ic.increment_value, ''1'') AS CHAR(1)) + '')'' ELSE '''' END END  FROM sys.columns c JOIN sys.types tp   ON c.user_type_id = tp.user_type_id  LEFT JOIN sys.computed_columns cc   ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
LEFT JOIN sys.default_constraints dc   ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
LEFT JOIN sys.identity_columns ic   ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
WHERE c.[object_id] = ' + CAST(@tableid AS VARCHAR) + ' 
ORDER BY c.column_id FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, CHAR(9) + '' '')  + ISNULL((SELECT CHAR(9) + '', CONSTRAINT ['' + k.name + ''_n1] PRIMARY KEY '' 
+ CASE WHEN  i.type = 1 THEN +'' CLUSTERED ('' ELSE +'' NONCLUSTERED ('' END + (SELECT STUFF((  SELECT '', ['' + c.name + ''] '' + CASE WHEN ic.is_descending_key = 1 THEN ''DESC'' ELSE ''ASC'' END
FROM sys.index_columns ic JOIN sys.columns c  ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id left join sys.indexes i on ic.object_id=i.object_id and ic.index_id= i.index_id
WHERE ic.is_included_column = 0 AND ic.[object_id] = k.parent_object_id AND ic.index_id = k.unique_index_id
FOR XML PATH(N''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, ''''))
+ '')'' FROM sys.key_constraints k  left join sys.indexes i on i.object_id=k.parent_object_id and i.is_primary_key=1
WHERE k.parent_object_id = ' + CAST(@tableid AS VARCHAR) + ' AND k.[type] = ''PK''), '''') + '')   on ' + CAST(@ps_name AS VARCHAR) + '('+ @ps_colname +')'+ ''''

set @sql = REPLACE(@sql,'_n1','ASW_n1')

EXEC sp_executesql @sql
				  ,N'@tblcr_tmp varchar(max) out'
				  ,@tblcr OUT


PRINT @tblcr

--EXEC (@tblcr)






SELECT
	 
    CASE si.index_id WHEN 0 THEN N'/* No create statement (Heap) */'
    ELSE 
        CASE is_primary_key WHEN 1 THEN
            N'ALTER TABLE ' + @table_tmp + N' ADD CONSTRAINT ' + QUOTENAME(si.name) + N' PRIMARY KEY ' +
                CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED '
            ELSE N'CREATE ' + 
                CASE WHEN si.is_unique = 1 then N'UNIQUE ' ELSE N'' END +
                CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED ' +
                N'INDEX ' + QUOTENAME(si.name) + N' ON ' + @table_tmp + N' '
        END +
        /* key def */ N'(' + key_definition + N')' +
        /* includes */ CASE WHEN include_definition IS NOT NULL THEN 
            N' INCLUDE (' + include_definition + N')'
            ELSE N''
        END +
        /* filters */ CASE WHEN filter_definition IS NOT NULL THEN 
            N' WHERE ' + filter_definition ELSE N''
        END +
        /* with clause - compression goes here */
        CASE WHEN row_compression_partition_list IS NOT NULL OR page_compression_partition_list IS NOT NULL 
            THEN N' WITH (' +
                CASE WHEN row_compression_partition_list IS NOT NULL THEN
                    N'DATA_COMPRESSION = ROW ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ' END	 --ON PARTITIONS (' + row_compression_partition_list + N')
                ELSE N'' END +
                CASE WHEN row_compression_partition_list IS NOT NULL AND page_compression_partition_list IS NOT NULL THEN N', ' ELSE N'' END +
                CASE WHEN page_compression_partition_list IS NOT NULL THEN
                    N'DATA_COMPRESSION = PAGE ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ' END --ON PARTITIONS (' + page_compression_partition_list + N')
                ELSE N'' END


				+
				 CASE
					WHEN si.fill_factor = 0 THEN ' '
					ELSE +
						',FILLFACTOR = ' + CAST(si.fill_factor AS NVARCHAR(5))
				END +


',ALLOW_ROW_LOCKS = ' + CASE
							WHEN si.allow_row_locks = 1 THEN ' ON'
							ELSE +' OFF'
						END + ', ALLOW_PAGE_LOCKS = ' + CASE
							WHEN si.allow_page_locks = 1 THEN ' ON'
							ELSE +' OFF'
						END 
			


            + N')'
            ELSE N''
        END +
        /* ON where? filegroup? partition scheme? */
        ' ON [' + @ps_name  + N']('+ @ps_colname+');'
    END AS index_create_statement
		
	,0 AS worked

INTO #create_ind

FROM sys.indexes AS si
JOIN sys.tables AS t ON si.object_id=t.object_id
JOIN sys.schemas AS sc ON t.schema_id=sc.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS stat ON 
    stat.database_id = DB_ID() 
    and si.object_id=stat.object_id 
    and si.index_id=stat.index_id
LEFT JOIN sys.partition_schemes AS psc ON si.data_space_id=psc.data_space_id
LEFT JOIN sys.partition_functions AS pf ON psc.function_id=pf.function_id
LEFT JOIN sys.filegroups AS fg ON si.data_space_id=fg.data_space_id
/* Key list */ OUTER APPLY ( SELECT STUFF (
    (SELECT N', ' + QUOTENAME(c.name) +
        CASE ic.is_descending_key WHEN 1 then N' DESC' ELSE N'' END
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.key_ordinal > 0
    ORDER BY ic.key_ordinal FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS keys ( key_definition )
/* Partitioning Ordinal */ OUTER APPLY (
    SELECT MAX(QUOTENAME(c.name)) AS column_name
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.partition_ordinal = 1) AS partitioning_column
/* Include list */ OUTER APPLY ( SELECT STUFF (
    (SELECT N', ' + QUOTENAME(c.name)
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.is_included_column = 1
    ORDER BY c.name FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS includes ( include_definition )
/* Partitions */ OUTER APPLY ( 
    SELECT 
        COUNT(*) AS partition_count,
        CAST(SUM(ps.in_row_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_in_row_GB,
        CAST(SUM(ps.lob_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_LOB_GB,
        SUM(ps.row_count) AS row_count
    FROM sys.partitions AS p
    JOIN sys.dm_db_partition_stats AS ps ON
        p.partition_id=ps.partition_id
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
    ) AS partition_sums
/* row compression list by partition */ OUTER APPLY ( SELECT STUFF (
    (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
    FROM sys.partitions AS p
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
        and p.data_compression = 1
    ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS row_compression_clause ( row_compression_partition_list )
/* data compression list by partition */ OUTER APPLY ( SELECT STUFF (
    (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
    FROM sys.partitions AS p
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
        and p.data_compression = 2
    ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS page_compression_clause ( page_compression_partition_list )
WHERE 
    si.type IN (1,2) /* heap, clustered, nonclustered */
	and sc.name + '.' + t.name = @table
	and is_primary_key <>1
	order by si.index_id



WHILE EXISTS
(
	SELECT
		*
	FROM #create_ind
	WHERE worked = 0
)
BEGIN

		SELECT TOP 1
			@sql = index_create_statement
		FROM #create_ind
		WHERE worked = 0

		print @sql

		--EXEC (@sql)





		UPDATE #create_ind
			SET worked = 1
		WHERE index_create_statement = @sql
END




END TRY
BEGIN CATCH

SELECT
	@msg = ERROR_MESSAGE()



RAISERROR (@msg, 20, 1) WITH LOG
END CATCH
GO
