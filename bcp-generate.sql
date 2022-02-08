SET NOCOUNT ON
declare @table sysname     =''
        ,@path varchar(35) = 'H:\BCP_DATA\'


DECLARE @sql nvarchar(max), @sql2 nvarchar(max)

SET @sql = 'bcp ' + @table + ' out "' + @path + '' + @table + '.dt" -S ' + @@SERVERNAME + ' -T -d ' + DB_NAME() + ' -r [*\] -t[@\] -c'
SET @sql2 = 'exec sys.xp_cmdshell ''' + @sql + ''',no_output'
PRINT @sql2

SET @sql = 'bcp ' + @table + ' in "' + @path + '' + @table + '.dt" -S ' + @@SERVERNAME + ' -T -d ' + DB_NAME() + ' -r [*\] -t[@\] -c -b 500000 -E'
SET @sql2 = 'exec sys.xp_cmdshell ''' + @sql + ''',no_output'
PRINT @sql2
GO
