SELECT 
       [SET OFFLINE]      = 'ALTER DATABASE ['+DB_NAME(database_id)+'] SET OFFLINE WITH ROLLBACK IMMEDIATE'
      ,[MODIFY FILE ]     = 'ALTER DATABASE ['+DB_NAME(database_id)+'] '+CHAR(10)+'MODIFY FILE '+CHAR(10)+'('+CHAR(10)+CHAR(9)+'NAME = ['+NAME+'], '+CHAR(10)+CHAR(9)+'FILENAME = '''+physical_name+''''+CHAR(10)+')'+CHAR(10)+'GO'
      ,[SET ONLINE]       = 'ALTER DATABASE ['+DB_NAME(database_id)+'] SET ONLINE'
      ,[MODIFY NAME]      = 'ALTER DATABASE ['+DB_NAME(database_id)+'] MODIFY NAME = ['+DB_NAME(database_id)+']'
      ,[physical_name] 
      ,[name]
      ,[size]
FROM   sys.master_files
WHERE  DB_NAME(database_id) IN ('')
ORDER BY
       NAME
