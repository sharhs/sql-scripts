declare @size int = 
       ,@dif int = 4096
       ,@i int  = 0
       ,@file varchar(max) = ''
       ,@sql varchar(max)
		 
print 'set NOCOUNT ON

'
while @i < 512

begin 

set @size = @size - @dif

set @sql = 'dbcc shrinkfile  ([' + @file + '],' + cast(@size as varchar) + ')
go'
print @sql

set @i = @i + 1
end
