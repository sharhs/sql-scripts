SET NOCOUNT ON

BEGIN TRY
    DROP TABLE #orphaned_report
END TRY
BEGIN CATCH
END CATCH


DECLARE @user VARCHAR(255)

CREATE TABLE #orphaned_report
(
	UserName     VARCHAR(255)
   ,UserSID      VARBINARY(MAX)
)

INSERT INTO #orphaned_report
EXEC sp_change_users_login 'Report'


ALTER TABLE #orphaned_report ADD Worked BIT DEFAULT(0)

UPDATE #orphaned_report
SET    Worked = 0


WHILE EXISTS(
          SELECT *
          FROM   #orphaned_report
          WHERE  Worked = 0
      )
BEGIN
	
    SELECT TOP 1 @user = UserName
    FROM   #orphaned_report
    WHERE worked = 0
    
    PRINT @user
    
    BEGIN TRY
    
        EXEC sp_change_users_login 'Auto_Fix'
            ,@user
        
        UPDATE #orphaned_report
        SET    worked       = 1
        WHERE  UserName     = @user
        
    END TRY
    BEGIN CATCH
    
        UPDATE #orphaned_report
        SET    worked       = 1
        WHERE  UserName     = @user
        
    END CATCH
   
END
