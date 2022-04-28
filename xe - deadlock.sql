

SELECT * into ##trc
 FROM sys.fn_xe_file_target_read_file
   ('F:\XEs\A!Deadlocks_0_132450089505650000.xel', NULL, NULL, NULL);
GO

select
	X.XData,
	t.DatabaseID,
	Seconds			= t.duration / 1000000,
	t.objectID,
	object_name(t.objectID),
	waittype		= XVals.waittype,
	XVals.waittime/1000 waittime_in_sec,
	EndTime
from ##trc t
cross apply
(
	select
		XData	=	CAST(t.TextData as xml)
) X
cross apply
(
	select
		waittype = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waitresource', 'NVarChar(1024)'),
		waittime = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waittime', 'NVarChar(1024)')
) XVals
where t.EventClass = 137
  and XVals.waittype not like 'APPLICATION%'
  and t.objectID > 90
--  and t.TextData like '%rts%'
order by endtime desc

