USE [master]
GO

CREATE SERVER AUDIT [AuditDB]
TO FILE 
(	FILEPATH = N'G:\TRC\'
	,MAXSIZE = 256 MB
	,MAX_FILES = 64
	,RESERVE_DISK_SPACE = OFF
) WITH (QUEUE_DELAY = 3000, ON_FAILURE = CONTINUE, AUDIT_GUID = 'afe3d284-86ad-4eab-ab48-90dbea171b4e') -- guid, можно без него?
ALTER SERVER AUDIT [AuditDB] WITH (STATE = ON)
GO



USE DB
GO

CREATE DATABASE AUDIT SPECIFICATION [AuditSpecification_objects]
FOR SERVER AUDIT [AuditDB]
ADD (DELETE ON OBJECT::[schema].[table] BY [public]),
ADD (INSERT ON OBJECT::[schema].[table] BY [public]),
ADD (UPDATE ON OBJECT::[schema].[table] BY [public]),
ADD (SELECT ON OBJECT::[schema].[table] BY [public]))


WITH (STATE = OFF) --включить
GO

SELECT TOP 256
	event_time,
	action_id,
	statement,
	database_name,
	server_principal_name
FROM fn_get_audit_file('G:\TRC\AuditDB*.sqlaudit', DEFAULT, DEFAULT)
WHERE server_principal_name <> 'login';


