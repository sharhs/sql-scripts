SELECT	spri.name
			,OBJECT_NAME(spr.major_id)
			,spr.*
	FROM sys.database_permissions spr
	JOIN sys.database_principals spri
		ON	spr.grantee_principal_id = spri.principal_id
WHERE spri.name like '%%'
ORDER BY OBJECT_NAME(spr.major_id)




SELECT	spri.name
			,OBJECT_NAME(spr.major_id)
			,spr.*
	FROM sys.server_permissions spr
	JOIN sys.server_principals spri
		ON	spr.grantee_principal_id = spri.principal_id
WHERE spri.name like '%%'
ORDER BY OBJECT_NAME(spr.major_id)


SELECT spr.state_desc collate SQL_Latin1_General_CP1251_CI_AS + '' + spr.permission_name +
isnull( ' on ' + OBJECT_NAME(spr.major_id) ,''
)+ ' to ' + 	spri.name,spri.name
			,OBJECT_NAME(spr.major_id)
			,spr.*
	FROM sys.database_permissions spr 
	JOIN sys.database_principals spri
		ON	spr.grantee_principal_id = spri.principal_id
WHERE spri.name like '%%'
and permission_name <> 'CONNECT'
ORDER BY OBJECT_NAME(spr.major_id)



