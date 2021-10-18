SELECT 
      'EXEC sys.[sp_addsrvrolemember]' +  '[' + m.name + '],'+   r.name
FROM   sys.server_role_members srm
       JOIN sys.server_principals  AS r
            ON  srm.role_principal_id = r.principal_id
       JOIN sys.server_principals  AS m
            ON  srm.member_principal_id = m.principal_id
WHERE  r.name = 'sysadmin'
ORDER BY
       m.name
