SELECT 'KILL '+CAST(des1.session_id AS VARCHAR(8))
      ,*
FROM   sys.dm_exec_sessions AS des1
WHERE des1.login_name LIKE '%%'
