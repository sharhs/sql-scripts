
select
	X.XData,
	t.DatabaseID,
	Seconds			= t.duration / 1000000,
	t.objectID,
	object_name(t.objectID),
	waittype		= XVals.waittype,
	XVals.waittime/1000 waittime_in_sec,
	EndTime
	,XVals.waittype      
	,XVals.waitresource  
	,XVals.waittime      
	,XVals.waiting_spid  
	,XVals.block_spid    
	,XVals.app_blocked   
	,XVals.app_blocking  
	,XVals.who_blocked   
	,XVals.who_blocking  
	,XVals.block_input   
	,XVals.wait_input    
	,XVals.block_tsql    
	,XVals.wait_tsql     
from 
(select * from fn_trace_gettable ('c:\trc\blocked_proc_rep_BD-SRV-TITAN_20150609.trc', default)  where EventClass=137) t
cross apply
(
	select
		XData	=	CAST(t.TextData as xml)
) X
cross apply
(
	select
		waittype      = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waitresource', 'NVarChar(1024)'),
		waitresource  = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waitresource', 'NVarChar(1024)'),
		waittime      = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waittime', 'NVarChar(1024)'),
		waiting_spid  = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@spid', 'NVarChar(1024)'),
		block_spid    = X.XData.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@spid', 'NVarChar(1024)'),
	   app_blocked   = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@clientapp', 'NVarChar(1024)'),
      app_blocking  = X.XData.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@clientapp', 'NVarChar(1024)'),
		who_blocked   = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@loginname', 'NVarChar(1024)'),
		who_blocking  = X.XData.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@loginname', 'NVarChar(1024)'),
		block_input   = X.XData.query('/blocked-process-report[1]/blocking-process[1]/process/inputbuf[1]'),
		wait_input    = X.XData.query('/blocked-process-report[1]/blocked-process[1]/process/inputbuf[1]'),
      block_tsql    = X.XData.value('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle', 'NVarChar(1024)'),
      wait_tsql     = X.XData.value('/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle', 'NVarChar(1024)')
) XVals
where t.EventClass = 137
  and XVals.waittype not like 'APPLICATION%'
  and t.objectID > 90
--  and t.TextData like '%rts%'
order by endtime 
