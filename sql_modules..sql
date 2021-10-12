SET NOCOUNT ON

DECLARE @mod SYSNAME=''

DROP TABLE IF EXISTS #res
CREATE TABLE #res
(
	dbname       SYSNAME
   ,obj_name     SYSNAME
   ,obj_type     SYSNAME
)

DECLARE @sqlt NVARCHAR(4000)=
        'USE ?(dbq);
insert into  #res
(
		dbname  
	   ,obj_name
	   ,obj_type
	)
SELECT 
       DB_name()
      ,DB_name() + ''.'' + object_schema_name(sm.[object_id]) + ''.'' + OBJECT_NAME(sm.[object_id])
      ,ao.type_desc
FROM   sys.sql_modules AS sm
JOIN sys.all_objects  AS ao
            ON  ao.[object_id] = sm.[object_id]
WHERE  sm.definition LIKE ''%'+@mod+'%''
';


DECLARE @db_id       SMALLINT=4
       ,@db_name     NVARCHAR(128)=NULL
       ,@sql         NVARCHAR(4000); 

WHILE 1=1
BEGIN
    SET @db_name = NULL;
    
    SELECT 
           TOP 1 @db_id = [database_id]
          ,@db_name = [name]
    FROM   sys.[databases]
    WHERE  [database_id]>@db_id
    AND    [state] = 0
    ORDER BY
           [database_id];
    
    IF @db_name IS NULL
        BREAK;
    
    SET @sql = REPLACE(@sqlt ,'?(dbq)' ,QUOTENAME(@db_name));
    
    EXEC (@sql);
END;

SELECT *
FROM #res
ORDER BY obj_name
