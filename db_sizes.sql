DECLARE @mode NVARCHAR(1)='E' -- E or C


IF (
       SELECT OBJECT_ID('tempdb.dbo.#dbsizes')
   ) IS NOT NULL
    DROP TABLE #dbsizes

CREATE TABLE #dbsizes
(
	id                        INT IDENTITY(1 ,1)
   ,dbname                    NVARCHAR(50)
   ,FILE_NAME                 NVARCHAR(50)
   ,Physical_Name             NVARCHAR(MAX)
   ,Total_Size_in_MB          INT
   ,Available_Space_In_MB     INT
   ,FILE_ID                   INT
   ,FILEGROUP_NAME            NVARCHAR(50)
)

INSERT INTO #dbsizes
EXEC sp_MSforeachdb 
     'use [?]; SELECT sd.name as dbname ,f.name AS File_Name , f.physical_name AS Physical_Name, 
CAST((f.size/128.0) AS DECIMAL(15,2)) AS Total_Size_in_MB,
CAST(f.size/128.0 - CAST(FILEPROPERTY(f.name, ''SpaceUsed'') AS int)/128.0 AS DECIMAL(15,2)) 
AS Available_Space_In_MB, f.file_id, fg.name AS Filegroup_Name
FROM sys.databases sd
join sys.master_files sm 
on sd.database_id= sm.database_id
join sys.database_files AS f WITH (NOLOCK) 
on sm.physical_name COLLATE DATABASE_DEFAULT = f.physical_name 
LEFT OUTER JOIN sys.data_spaces AS fg WITH (NOLOCK) 
ON f.data_space_id = fg.data_space_id 
OPTION(RECOMPILE)'

/*
dbcc shrinkfile  (,) 
exec xp_fixeddrives
*/

IF @mode='E'
BEGIN
    SELECT id
          ,dbname
          ,[FILE_NAME]
          ,Physical_Name
          ,Total_Size_in_MB
          ,Available_Space_In_MB
          ,Total_Size_in_MB- Available_Space_In_MB alloc_spaces_mb
          ,FILE_ID
          ,FILEGROUP_NAME
          ,[sql_shrink] = 'use '+QUOTENAME([dbname])+'; 
dbcc shrinkfile  ('+QUOTENAME([FILE_NAME])+','+CAST(Total_Size_in_MB- Available_Space_In_MB AS VARCHAR(99))+')'
    FROM   #dbsizes
           --    WHERE [Physical_Name] LIKE 'd%'
           --  WHERE [dbname] like 'opendb'
    ORDER BY
           Total_Size_in_MB DESC
END
ELSE
    SELECT dbname
          ,SUM(Total_Size_in_MB)
    FROM   #dbsizes
    GROUP BY
           dbname
    ORDER BY
           1
