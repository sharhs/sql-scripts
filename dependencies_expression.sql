-- кто ссылается на объект

DECLARE @objname     SYSNAME = 'fnNextWorkingDay_Get',
        @dbname      SYSNAME = 'Motor'

BEGIN TRY
	DROP TABLE #res
END TRY
BEGIN CATCH
END CATCH


SELECT TOP 0 DB_NAME()                       dbname,
       OBJECT_NAME(sed.[referencing_id])     referencing_name,
       OBJECT_NAME(sed.[referenced_id])      referenced_name,
       *
INTO   #res
FROM   sys.[sql_expression_dependencies] AS sed


DECLARE @sql NVARCHAR(MAX) = 
        'use [?];
insert into #res
SELECT db_name(),
       OBJECT_SCHEMA_NAME(sed.[referencing_id]) + ''.'' +  OBJECT_NAME(sed.[referencing_id]),
       OBJECT_SCHEMA_NAME(sed.[referenced_id]) + ''.'' + OBJECT_NAME(sed.[referenced_id]),
       *
FROM   sys.[sql_expression_dependencies] AS sed
WHERE  sed.[referenced_entity_name]= ''' + @objname + '''
AND sed.[referenced_database_name] =  ''' + @dbname + 
        '''

union 

SELECT db_name(),
	   OBJECT_SCHEMA_NAME(sed.[referencing_id]) + ''.'' +  OBJECT_NAME(sed.[referencing_id]),
       OBJECT_SCHEMA_NAME(sed.[referenced_id]) + ''.'' + OBJECT_NAME(sed.[referenced_id]),
       *
FROM   sys.[sql_expression_dependencies] AS sed
WHERE  sed.[referenced_entity_name]= ''' + @objname + '''

ORDER BY 2'

EXEC sys.[sp_MSforeachdb] @sql

SELECT dbname,
       [who]      =  referencing_name ,
       [whom]     = referenced_name
FROM   #res
WHERE  dbname <> 'opendb_day'





/*
---- на кого ссылается объект

DECLARE @PARAM_OBJECT_NAME VARCHAR(500) = 'sync_p_portfolio_info';

WITH CTE_DependentObjects AS
     (
         SELECT DISTINCT 
                b.object_id  AS UsedByObjectId,
                b.name       AS UsedByObjectName,
                b.type       AS UsedByObjectType,
                c.object_id  AS DependentObjectId,
                c.name       AS DependentObjectName,
                c.[type_desc]       AS DependenObjectType
         FROM   sys.sysdepends a
                INNER JOIN sys.objects b
                     ON  a.id = b.object_id
                INNER JOIN sys.objects c
                     ON  a.depid = c.object_id
         WHERE  b.type IN ('P', 'V', 'FN')
                AND c.type IN ('U', 'P', 'V', 'FN')
     ),
     CTE_DependentObjects2 AS
     (
         SELECT UsedByObjectId,
                UsedByObjectName,
                UsedByObjectType,
                DependentObjectId,
                DependentObjectName,
                DependenObjectType,
                1                     AS LEVEL
         FROM   CTE_DependentObjects     a
         WHERE  a.UsedByObjectName = @PARAM_OBJECT_NAME
         UNION
         ALL 
         
         SELECT a.UsedByObjectId,
                a.UsedByObjectName,
                a.UsedByObjectType,
                a.DependentObjectId,
                a.DependentObjectName,
                a.DependenObjectType,
                (b.Level + 1) AS LEVEL
         FROM   CTE_DependentObjects a
                INNER JOIN CTE_DependentObjects2 b
                     ON  a.UsedByObjectName = b.DependentObjectName
     )

SELECT DISTINCT * 
FROM   CTE_DependentObjects2
ORDER BY
       LEVEL,
       DependentObjectName    


*/