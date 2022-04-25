SELECT	* FROM sys.dm_xe_map_values	
SELECT	* FROM sys.dm_xe_object_columns	
SELECT	* FROM sys.dm_xe_objects	
SELECT	* FROM sys.dm_xe_packages	
SELECT	* FROM sys.dm_xe_session_event_actions	
SELECT	* FROM sys.dm_xe_session_events	
SELECT	* FROM sys.dm_xe_session_object_columns	
SELECT	* FROM sys.dm_xe_session_targets	
SELECT	* FROM sys.dm_xe_sessions	





SELECT	* FROM sys.dm_xe_map_values
WHERE NAME = 'wait_types'
AND map_value LIKE '%LATCH%'



для sp_completed

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='php_procs')
    DROP EVENT SESSION [php_procs] ON SERVER;
CREATE EVENT SESSION [php_procs]
ON SERVER
ADD EVENT sqlserver.module_end(
     ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.sql_text, sqlserver.username)
     WHERE sqlserver.username = 'пользак' and duration > 1 )
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'ПУТЬ\имя.xel', 
        METADATAFILE = N'ПУТЬ\имя.xem')
WITH (MAX_MEMORY = 4096KB, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS, 
MAX_DISPATCH_LATENCY = 3 SECONDS, MAX_EVENT_SIZE = 0KB, MEMORY_PARTITION_MODE = NONE, 
TRACK_CAUSALITY = OFF, STARTUP_STATE = OFF)




для sp_statement_completed, sql_statement_completed, rpc_completed

CREATE EVENT SESSION ExpensiveQueries2 ON SERVER
ADD EVENT sqlserver.sql_statement_completed
   (ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'пользак' AND cpu > 5 ),
ADD EVENT sqlserver.sp_statement_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'пользак' AND cpu > 5 ),
ADD EVENT sqlserver.rpc_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'пользак' AND cpu > 5 )      
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'ПУТЬ\имя.xel', 
        METADATAFILE = N'ПУТЬ\имя.xem')
WITH (max_dispatch_latency = 3 seconds);
GO



для waits


IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='wait_info_all')
    DROP EVENT SESSION [wait_info_all] ON SERVER;
CREATE EVENT SESSION [wait_info_all]
ON SERVER

ADD EVENT sqlos.wait_info(
     ACTION (sqlserver.database_id, sqlserver.is_system, sqlserver.session_nt_username, sqlos.task_time, sqlserver.tsql_stack, sqlserver.username)
     WHERE (duration > 10)),

ADD EVENT sqlos.wait_info_external(
     ACTION (sqlserver.database_id, sqlserver.is_system, sqlserver.session_nt_username, sqlos.task_time, sqlserver.tsql_stack, sqlserver.username)
     WHERE ( duration > 10))

ADD TARGET package0.ring_buffer,
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'H:\traces\wait_info_all.xel', 
        METADATAFILE = N'H:\traces\wait_info_all.xem')

WITH (MAX_MEMORY = 4096KB, 
	  EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS, 
	  MAX_DISPATCH_LATENCY = 300 SECONDS, 
	  MAX_EVENT_SIZE = 0KB, 
	  MEMORY_PARTITION_MODE = NONE, 
	  TRACK_CAUSALITY = OFF, 
	  STARTUP_STATE = OFF)


или 



CREATE EVENT SESSION [marketstat_xe_waits]
ON SERVER

ADD EVENT sqlos.wait_info(
     ACTION (sqlserver.database_id, 
             sqlserver.is_system, 
             sqlos.task_time, 
             sqlserver.tsql_stack, 
             sqlserver.username, 
             sqlserver.client_app_name, 
             sqlserver.client_hostname, 
             sqlserver.database_id, 
             sqlserver.sql_text
             )
     WHERE duration > 100 and sqlserver.database_id = 19),

ADD EVENT sqlos.wait_info_external(
     ACTION (sqlserver.database_id, 
             sqlserver.is_system, 
             sqlos.task_time, 
             sqlserver.tsql_stack, 
             sqlserver.username, 
             sqlserver.client_app_name, 
             sqlserver.client_hostname, 
             sqlserver.database_id, 
             sqlserver.sql_text
             )
     WHERE duration > 100 and sqlserver.database_id = 19)

ADD TARGET package0.ring_buffer,
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'H:\traces\marketstat_xe_waits.xel', 
        METADATAFILE = N'H:\traces\marketstat_xe_waits.xem')

WITH (MAX_MEMORY = 4096KB, 
	  EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS, 
	  MAX_DISPATCH_LATENCY = 100 SECONDS, 
	  MAX_EVENT_SIZE = 0KB, 
	  MEMORY_PARTITION_MODE = NONE, 
	  TRACK_CAUSALITY = OFF, 
	  STARTUP_STATE = OFF)




ALTER EVENT SESSION ExpensiveQueries2  ON SERVER STATE = start
GO

ALTER EVENT SESSION ExpensiveQueries2  ON SERVER STATE = stop
GO



SELECT COUNT (*) FROM sys.fn_xe_file_target_read_file
   ('ПУТЬ\имя*.xel', 'ПУТЬ\имя*.xem', NULL, NULL);
GO




SELECT top 10 data FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
('ПУТЬ\имя*.xel', 'ПУТЬ\имя*.xem', NULL, NULL)
 ) entries;
GO



распарсить xml

SELECT 
data,
   isnull(data.value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]', 'DATETIME') ,isnull(data.value ('(/event[@name=''rpc_completed'']/@timestamp)[1]', 'DATETIME'),
data.value ('(/event[@name=''sp_statement_completed'']/@timestamp)[1]', 'DATETIME')   ) )  as date_time,
   data.value (
      '(/event/data[@name=''cpu'']/value)[1]', 'INT') AS [CPU (ms)],
      CONVERT (FLOAT, data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')) / 1000
      AS Duration_ms,
	    data.value (
      '(/event/data[@name=''reads'']/value)[1]', 'INT') AS reads,
   data.value (
      '(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS Statement,
      SUBSTRING (data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(100)'), 15, 50)
      AS Plan_Handle
--into #xe_phpuser
FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
      ('ПУТЬ\имя*.xel', 'ПУТЬ\имя*.xem', NULL, NULL)
) entries
ORDER BY date_time
GO



SELECT 
isnull(data.value ('(/event[@name=''module_end'']/@timestamp)[1]', 'DATETIME') ,
isnull(data.value ('(/event[@name=''rpc_completed'']/@timestamp)[1]', 'DATETIME'),
	   data.value ('(/event[@name=''sp_statement_completed'']/@timestamp)[1]', 'DATETIME')   ) )	AS Date_time
,data.value ('(/event/data[@name=''cpu'']/value)[1]', 'INT')									    AS CPU_ms
,CONVERT (FLOAT, data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')) / 1000		AS Duration_ms
,data.value ('(/event/data[@name=''reads'']/value)[1]', 'INT')										AS reads
,data.value ('(/event/data[@name=''object_name'']/value)[1]', 'VARCHAR(MAX)')						AS objectname
	into #xe_phpuser
FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
      ('h:\traces\phpmodules*.xel', 'h:\traces\phpmodules*.xem', NULL, NULL)
) entries
ORDER BY date_time
GO





SELECT 
	data   ,
	data.value('(/event[@name=''sp_statement_completed'']/@timestamp)[1]', 'DATETIME') AS time_stamp,
	data.value('(data[@name=''wait_type'']/text)[1]', 'varchar(25)') AS wait_type,
	data.value('(data[@name=''duration'']/value)[1]', 'BIGINT') as duration,
	data.value('(data[@name=''max_duration'']/value)[1]', 'BIGINT') as max_duration,
	data.value('(data[@name=''total_duration'']/value)[1]', 'BIGINT') as total_duration,
	data.value ('(action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS SQL_Statement,
	data.value ('(action[@name=''client_app_name'']/value)[1]', 'VARCHAR(MAX)') AS client_app_name,
	data.value ('(action[@name=''client_hostname'']/value)[1]', 'VARCHAR(MAX)') AS client_hostname,
	data.value ('(action[@name=''database_id'']/value)[1]', 'INT') AS database_id,
	data.value ('(action[@name=''plan_handle'']/value)[1]', 'VARCHAR(MAX)') AS plan_handle,
	data.value ('(action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS sql_text,
	data.value ('(action[@name=''tsql_stack'']/value)[1]', 'VARCHAR(MAX)') AS tsql_stack,
	data.value ('(action[@name=''username'']/value)[1]', 'VARCHAR(MAX)') AS username
--into #xe_phpuser
FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
      ('h:\traces\Waits_of_Particular_Session_0_130725212984570000.xel', 'h:\traces\Waits_of_Particular_Session_0_130725207078190000.xem', NULL, NULL)
) entries
ORDER BY time_stamp
GO





SELECT  CONVERT (XML, event_data) AS data 
into ##jsa_w
FROM sys.fn_xe_file_target_read_file
      ('h:\traces\Waits_of_Particular_Session_0_130725212984570000.xel', 'h:\traces\Waits_of_Particular_Session_0_130725207078190000.xem', NULL, NULL)


SELECT  
	data   ,
	data.value('(/event[@name=''wait_info'']/@timestamp)[1]', 'DATETIME') AS time_stamp,
	data.value('(/event/data[@name=''wait_type'']/text)[1]', 'varchar(25)') AS wait_type,
	data.value('(/event/data[@name=''duration'']/value)[1]', 'BIGINT') as duration,
	data.value('(/event/data[@name=''max_duration'']/value)[1]', 'BIGINT') as max_duration,
	data.value('(/event/data[@name=''total_duration'']/value)[1]', 'BIGINT') as total_duration,
	data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS SQL_Statement,
	data.value ('(/event/action[@name=''client_app_name'']/value)[1]', 'VARCHAR(MAX)') AS client_app_name,
	data.value ('(/event/action[@name=''client_hostname'']/value)[1]', 'VARCHAR(MAX)') AS client_hostname,
	data.value ('(/event/action[@name=''database_id'']/value)[1]', 'INT') AS database_id,
	data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(MAX)') AS plan_handle,
	data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS sql_text,
	data.value ('(/event/action[@name=''tsql_stack'']/value)[1]', 'VARCHAR(MAX)') AS tsql_stack,
	data.value ('(/event/action[@name=''username'']/value)[1]', 'VARCHAR(MAX)') AS username
into ##jsa_waits
FROM 
   (SELECT CONVERT (XML, data) AS data FROM ##jsa_w) entries
ORDER BY time_stamp
GO


SELECT CONVERT (XML, data) AS xdata FROM ##jsa_w



распарсить module_end


SELECT 
   data,
   data.value ('(/event[@name=''module_end'']/@timestamp)[1]', 'DATETIME')                  as date_time,
   data.value ('(/event/data[@name=''object_type'']/value)[1]', 'VARCHAR(MAX)')             as object_type,
   data.value ('(/event/data[@name=''object_name'']/value)[1]', 'VARCHAR(MAX)')             as object_name,
CONVERT (FLOAT, 
   data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT'))/1000                as Duration_ms,
   data.value ('(/event/data[@name=''reads'']/value)[1]', 'INT')                            as reads,
   data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)')              as Statement,
SUBSTRING (
   data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(100)'), 15, 50)  as Plan_Handle

FROM 
   (SELECT  CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
     ('h:\traces\php_procs_0_130735727231900000.xel', 'h:\traces\php_procs_0_130735727231900000.xem', NULL, NULL) 
) entries
ORDER BY date_time
GO








SELECT  CONVERT (XML, event_data) AS data 
into ##jsa_w
FROM sys.fn_xe_file_target_read_file
      ('h:\traces\Waits_of_Particular_Session_0_130725212984570000.xel', 'h:\traces\Waits_of_Particular_Session_0_130725207078190000.xem', NULL, NULL)


SELECT  
	data   ,
	data.value('(/event[@name=''wait_info'']/@timestamp)[1]', 'DATETIME') AS time_stamp,
	data.value('(/event/data[@name=''wait_type'']/text)[1]', 'varchar(25)') AS wait_type,
	data.value('(/event/data[@name=''duration'']/value)[1]', 'BIGINT') as duration,
	data.value('(/event/data[@name=''max_duration'']/value)[1]', 'BIGINT') as max_duration,
	data.value('(/event/data[@name=''total_duration'']/value)[1]', 'BIGINT') as total_duration,
	data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS SQL_Statement,
	data.value ('(/event/action[@name=''client_app_name'']/value)[1]', 'VARCHAR(MAX)') AS client_app_name,
	data.value ('(/event/action[@name=''client_hostname'']/value)[1]', 'VARCHAR(MAX)') AS client_hostname,
	data.value ('(/event/action[@name=''database_id'']/value)[1]', 'INT') AS database_id,
	data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(MAX)') AS plan_handle,
	data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS sql_text,
	data.value ('(/event/action[@name=''tsql_stack'']/value)[1]', 'VARCHAR(MAX)') AS tsql_stack,
	data.value ('(/event/action[@name=''username'']/value)[1]', 'VARCHAR(MAX)') AS username
into ##jsa_waits
FROM 
   (SELECT CONVERT (XML, data) AS data FROM ##jsa_w) entries
ORDER BY time_stamp
GO

SELECT CONVERT (XML, data) AS xdata FROM ##jsa_w
go
select 
SQL_Statement,wait_type , count(SQL_Statement), sum(duration)	sduration,sum(max_duration)	smax_duration,sum(total_duration) stotal_duration from ##jsa_waits
group by SQL_Statement,wait_type 
order by stotal_duration desc

--time_stamp	,wait_type	
--,duration	,max_duration	
--,total_duration	,SQL_Statement	
--,client_app_name	,client_hostname	
--,database_id	,plan_handle	
--,sql_text	,tsql_stack	,username
--where time_stamp is not NULL




--page_split

with cte as(
SELECT  
                   data  
,time_stamp      = data.value('(/event[@name=''page_split'']/@timestamp)[1]', 'DATETIME')

,'dbcc page (31,' + 
cast(data.value('(/event/data[@name=''file_id'']/value)[1]', 'int') as varchar) + ',' + 
cast(data.value('(/event/data[@name=''page_id'']/value)[1]', 'int') as varchar)+ ')' as DBCCPAGE

,[file_id]       = data.value('(/event/data[@name=''file_id'']/value)[1]', 'int')
,page_id         = data.value('(/event/data[@name=''page_id'']/value)[1]', 'int')
,client_app_name = data.value ('(/event/action[@name=''client_app_name'']/value)[1]', 'VARCHAR(MAX)') 
,username        = data.value ('(/event/action[@name=''username'']/value)[1]', 'VARCHAR(MAX)') 
--  ,data.value('(/event/data[@name=''duration'']/value)[1]', 'BIGINT') as duration
--  ,data.value('(/event/data[@name=''max_duration'']/value)[1]', 'BIGINT') as max_duration
--  ,data.value('(/event/data[@name=''total_duration'']/value)[1]', 'BIGINT') as total_duration
--  ,
--  ,db_name(data.value ('(/event/action[@name=''database_id'']/value)[1]', 'INT')) AS database_name
--  
--  ,data.value ('(/event/action[@name=''tsql_stack'']/value)[1]', 'VARCHAR(MAX)') AS tsql_stack
--  ,data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS sql_text
--  ,data.value ('(/event/action[@name=''username'']/value)[1]', 'VARCHAR(MAX)') AS username 
FROM 
    (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
      ('F:\traces\page_split_0_130783963997160000*.xel', 'F:\traces\page_split_0_130783963997160000*.xem', NULL, NULL)
) entries
where data.value('(/event/data[@name=''page_id'']/value)[1]', 'int') <> 0 
)
select page_id,[file_id],count(*)  from cte
group by page_id,[file_id]
order by 3 desc







IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='jsa_compl')
    DROP EVENT SESSION [wait_info_all] ON SERVER;
	 
	 CREATE EVENT SESSION jsa_compl ON SERVER
ADD EVENT sqlserver.sql_statement_completed
   (ACTION (
	         sqlserver.database_id
	        , sqlserver.is_system
			  , sqlserver.client_hostname
			  , sqlserver.session_nt_username
			  , sqlos.task_time
			  , sqlserver.tsql_stack
			  , sqlserver.sql_text
			  , sqlserver.username
			 )
      WHERE sqlserver.username = 'jsa' AND cpu > 150 ),
ADD EVENT sqlserver.sp_statement_completed
	(ACTION (
	sqlserver.database_id
	        , sqlserver.is_system
			  , sqlserver.client_hostname
			  , sqlserver.session_nt_username
			  , sqlos.task_time
			  , sqlserver.tsql_stack
			  , sqlserver.sql_text
			  , sqlserver.username
			  )
      WHERE sqlserver.username = 'jsa' AND cpu > 150 ),
ADD EVENT sqlserver.rpc_completed
	(ACTION (
	sqlserver.database_id
	        , sqlserver.is_system
			  , sqlserver.client_hostname
			  , sqlserver.session_nt_username
			  , sqlos.task_time
			  , sqlserver.tsql_stack
			  , sqlserver.sql_text
			  , sqlserver.username
			  )
      WHERE sqlserver.username = 'jsa' AND cpu > 150 )      
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'H:\traces\jsa_compl.xel', 
        METADATAFILE = N'H:\traces\jsa_compl.xem')
WITH (max_dispatch_latency = 3 seconds);
GO




IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='wait_info_jsa')
    DROP EVENT SESSION [wait_info_jsa] ON SERVER;
CREATE EVENT SESSION [wait_info_jsa]
ON SERVER

ADD EVENT sqlos.wait_info(
     ACTION (sqlserver.database_id
	        , sqlserver.is_system
			  , sqlserver.client_hostname
			  , sqlserver.session_nt_username
			  , sqlos.task_time
			  , sqlserver.tsql_stack
			  , sqlserver.sql_text
			  , sqlserver.username)
     WHERE ( duration > 150)),

ADD EVENT sqlos.wait_info_external(
     ACTION (sqlserver.database_id
	        , sqlserver.is_system
			  , sqlserver.client_hostname
			  , sqlserver.session_nt_username
			  , sqlos.task_time
			  , sqlserver.tsql_stack
			  , sqlserver.sql_text
			  , sqlserver.username)
     WHERE ( duration > 150))

ADD TARGET package0.ring_buffer,
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'H:\traces\wait_info_jsa.xel', 
        METADATAFILE = N'H:\traces\wait_info_jsa.xem')

WITH (MAX_MEMORY = 4096KB, 
	  EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS, 
	  MAX_DISPATCH_LATENCY = 300 SECONDS, 
	  MAX_EVENT_SIZE = 0KB, 
	  MEMORY_PARTITION_MODE = NONE, 
	  TRACK_CAUSALITY = OFF, 
	  STARTUP_STATE = OFF)





IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='php_procs')
    DROP EVENT SESSION [php_procs] ON SERVER;
CREATE EVENT SESSION [php_procs]
ON SERVER
ADD EVENT sqlserver.module_end(
     ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.sql_text, sqlserver.username)
     WHERE sqlserver.username = 'phpuser'  )
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'h:\traces\php_procs.xel', 
        METADATAFILE = N'h:\traces\php_procs.xem')
WITH (MAX_MEMORY = 4096KB, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS, 
MAX_DISPATCH_LATENCY = 3 SECONDS, MAX_EVENT_SIZE = 0KB, MEMORY_PARTITION_MODE = NONE, 
TRACK_CAUSALITY = OFF, STARTUP_STATE = OFF)





CREATE EVENT SESSION ExpensiveQueries2 ON SERVER
ADD EVENT sqlserver.sql_statement_completed
   (ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'phpuser' AND cpu > 15 ),
ADD EVENT sqlserver.sp_statement_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'phpuser' AND cpu > 15 ),
ADD EVENT sqlserver.rpc_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.username = 'phpuser' AND cpu > 15 )      
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'F:\traces\ExpensiveQueries.xel', 
        METADATAFILE = N'F:\traces\ExpensiveQueries.xem')
WITH (max_dispatch_latency = 3 seconds);
GO


ALTER EVENT SESSION ExpensiveQueries2  ON SERVER STATE = start
GO

ALTER EVENT SESSION ExpensiveQueries2  ON SERVER STATE = stop
GO


SELECT COUNT (*) FROM sys.fn_xe_file_target_read_file
   ('F:\traces\ExpensiveQueries*.xel', 'F:\traces\ExpensiveQueries*.xem', NULL, NULL);
GO

xp_cmdshell 'dir f:\traces'








CREATE EVENT SESSION select * from logdb.dbo.opendb_log_tablesExpensiveQueries 
ON SERVER
ADD EVENT sqlserver.sql_statement_completed
   (ACTION (sqlserver.sql_text, sqlserver.plan_handle)
      WHERE sqlserver.username = 'phpuser' AND cpu > 5 /*total ms of CPU time*/)
ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'F:\traces\ExpensiveQueries.xel', METADATAFILE = N'F:\traces\ExpensiveQueries.xem')
WITH (max_dispatch_latency = 1 seconds);
GO


ALTER EVENT SESSION ExpensiveQueries ON SERVER STATE = START;
GO




SELECT COUNT (*) FROM sys.fn_xe_file_target_read_file
   ('F:\traces\EExpensiveQueries*.xel', 'F:\traces\ExpensiveQueries*.xem', NULL, NULL);
GO



SELECT top 10 data FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
('F:\traces\ExpensiveQueries*.xel', 'F:\traces\ExpensiveQueries*.xem', NULL, NULL)
 ) entries;
GO



SELECT 
data,
   isnull(data.value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]', 'DATETIME') ,isnull(data.value ('(/event[@name=''rpc_completed'']/@timestamp)[1]', 'DATETIME'),
data.value ('(/event[@name=''sp_statement_completed'']/@timestamp)[1]', 'DATETIME')   ) )  as date_time,
   data.value (
      '(/event/data[@name=''cpu'']/value)[1]', 'INT') AS [CPU (ms)],
      CONVERT (FLOAT, data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')) / 1000000
      AS [Duration (s)],
	    data.value (
      '(/event/data[@name=''reads'']/value)[1]', 'INT') AS [reads],
   data.value (
      '(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS [SQL Statement],
      SUBSTRING (data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(100)'), 15, 50)
      AS [Plan Handle]
--into #xe_phpuser
FROM 
   (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file
      ('F:\traces\ExpensiveQueries*.xel', 'F:\traces\ExpensiveQueries*.xem', NULL, NULL)
) entries
ORDER BY date_time
GO



-- для всех стэйтментов

CREATE EVENT SESSION [sql_completed]
ON SERVER

ADD EVENT sqlserver.sql_statement_completed
   (ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.tsql_stack, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.database_id = 31 AND cpu > 5 ),

ADD EVENT sqlserver.sp_statement_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.tsql_stack, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.database_id = 31 AND cpu > 5 ),

ADD EVENT sqlserver.rpc_completed
	(ACTION (sqlserver.sql_text, sqlserver.plan_handle, sqlserver.tsql_stack, sqlserver.client_app_name, sqlserver.client_hostname)
      WHERE sqlserver.database_id = 31 AND cpu > 5 )      

ADD TARGET package0.asynchronous_file_target
   (SET FILENAME = N'H:\traces\rts_sql_completed.xel', 
        METADATAFILE = N'H:\traces\rts_sql_completed.xem')
WITH (max_dispatch_latency = 30 seconds)
GO

-- стоп - запуск - дроп
ALTER EVENT SESSION [sql_completed] ON SERVER STATE = STOP;

ALTER EVENT SESSION [sql_completed] ON SERVER STATE = START;

DROP EVENT SESSION [sql_completed] ON SERVER; 


-- загрузка во времянку

SELECT Data
	,isnull(Data.value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]','DATETIME'),
	  isnull(Data.value ('(/event[@name=''rpc_completed'']/@timestamp)[1]','DATETIME'),
	   Data.value ('(/event[@name=''sp_statement_completed'']/@timestamp)[1]','DATETIME')))              AS Date_time
	,Data.value ('(/event/data[@name=''cpu'']/value)[1]','INT')                                          AS CPU_ms
	,Data.value ('(/event/data[@name=''object_id'']/value)[1]','INT')                                    AS ObjectId
	,convert (fLOAT,Data.value ('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1000             AS Duration_ms
	,Data.value ('(/event/data[@name=''reads'']/value)[1]','INT')                                        AS Reads
	,Data.value ('(/event/action[@name=''sql_text'']/value)[1]','VARCHAR(MAX)')                          AS Statement
	,substring (Data.value ('(/event/action[@name=''plan_handle'']/value)[1]','VARCHAR(100)'),15,50)     AS Plan_Handle
	,Data.value ('(/event/action[@name=''tsql_stack'']/value)[1]','VARCHAR(100)')                        AS Tsql_stack
INTO 
#xe_phpuser 
FROM (SELECT convert (xML,Event_data) AS Data
	FROM Sys.Fn_xe_file_target_read_file ('H:\traces\rts_sql_completed*.xel','H:\traces\rts_sql_completed*.xem',NULL,NULL)
	) Entries
ORDER BY Date_time
GO


-- аггрегация


SELECT object_name(ObjectId) as proca
	,Plan_Handle
	,Tsql_stack
	,sum(CPU_ms)	  as sum_CPU
	,sum(Duration_ms)	  as sum_Duration_ms
	,sum(Duration_ms)/count(Duration_ms)	  as avg_Duration_ms
	,sum(Reads)         as sum_Reads
	,sum(Reads)/count(Reads)	  as avg_Reads
	,count(*) as  cnt
FROM #xe_phpuser 
GROUP BY object_name(ObjectId),Plan_Handle,Tsql_stack
ORDER BY sum(Duration_ms) DESC
