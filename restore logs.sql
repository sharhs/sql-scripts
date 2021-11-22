begin
set nocount on;

declare	  @cmd_exec		varchar(500),
	      @db_name varchar(100),
	      @tlog varchar(5000)
	
create table #dirtree
(
filename varchar(45),
depth int,
file_worked int
)

insert into 
#dirtree (filename ,depth , file_worked)
EXEC master..xp_dirtree 'C:\backup\' , 1, 1



select  'test_rec' as database_name,
	   [filename] as physical_device_name,
	   0 as processed
into	#transaction_logs
from 	#dirtree 
where 	[filename] like '%.bak'
and [filename] not like '%full%'
order by [filename]

begin try

while exists (select 1 from #transaction_logs where processed = 0)
begin 

select top 1 
@db_name =  database_name , 
@tlog = physical_device_name
from #transaction_logs
where processed= 0
order by physical_device_name asc

set @cmd_exec = 'RESTORE LOG ' + @db_name + ' FROM DISK = ' + '''C:\backup\'+ @tlog + ''
	+ ''' WITH  FILE = 1,  '
	+ 'NORECOVERY;'
	--select @cmd_exec
	print 'Restoring: ' + @tlog
	print @cmd_exec
	--exec (@cmd_exec)
update #transaction_logs set 
processed = 1
where physical_device_name = @tlog

end 


/*
drop table #dirtree
drop table #transaction_logs
select * from #transaction_logs
select * from #dirtree
restore database test_rec with recovery
 */
 
 end try
 
 begin catch
 print 'error cod ' + convert (varchar, error_number())
 print 'messaga ' + error_message()
 end catch
 
end
