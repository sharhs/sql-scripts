DECLARE @c_body    Nvarchar(max),
        @c_subject Nvarchar(MAX), 
        @c_profile Nvarchar(MAX)

SELECT TOP 1 @c_profile = name
FROM msdb.dbo.sysmail_profile

SET @c_subject = @@servername + ': <subject,,some subject> ' + ISNULL(OBJECT_NAME(@@procid),'')

SELECT @c_body = '<body,,some text>'

EXEC msdb.dbo.sp_send_dbmail @profile_name = @c_profile
                        , @recipients   = '<komu,,sharshatov@mail.ru>'
                        , @subject      = @c_subject
                        , @body         = @c_body
