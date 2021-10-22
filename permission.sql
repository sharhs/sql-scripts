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
