USE [opendb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[sp_shrink]
	@step_mb INT = 512
	 ,
	@dbname NVARCHAR(25) = 'opendb'
AS
BEGIN
	-----------------------------------------------------------------------------------------
	-- v.1.0.	Created by	OPEN.RU\sharshatov-adm	02.08.2017
	-----------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET LOCK_TIMEOUT 60000
	SET DEADLOCK_PRIORITY LOW
	-----------------------------------------------------------------------------------------
	--		exec [sp_shrink]
	BEGIN TRY
		DECLARE @log_session_id     INT -- для логирования
		       ,@message            VARCHAR(MAX)
		       ,@proc_name          VARCHAR(255) = OBJECT_NAME(@@procid)
		
		----------------------------------------------------
		SELECT @message = @proc_name
		       -- логируем параметры, с которыми вызвана процедура
		       +' @step_mb =' + ISNULL('''' + CAST(@step_mb AS VARCHAR(MAX)) + '''' ,'null')
		       + ' @dbname,=' + ISNULL('''' + CAST(@dbname AS VARCHAR(MAX)) + '''' ,'null')
		
		EXEC dbo.log_data_save
		     @log_session_id OUTPUT
		    ,@@procid
		    ,NULL
		    ,@message
		----------------------------------------------------		
		
		
		DECLARE @filename      SYSNAME
		       ,@cursize       BIGINT
		       ,@avialsize     BIGINT
		       ,@excape_mb     BIGINT
		       ,@sql           VARCHAR(300)
		
		SELECT @filename = f.name
		      ,@cursize       = CAST((f.size / 128.0) AS DECIMAL(15 ,2))
		      ,@avialsize     = CAST(
		           f.size / 128.0 - CAST(FILEPROPERTY(f.name ,'SpaceUsed') AS INT) / 128.0 AS DECIMAL(15 ,2)
		       )
		      ,@excape_mb     = CAST((f.size / 128.0) AS DECIMAL(15 ,2)) - CAST(
		           f.size / 128.0 - CAST(FILEPROPERTY(f.name ,'SpaceUsed') AS INT) / 128.0 AS DECIMAL(15 ,2)
		       )
		FROM   sys.databases sd
		       JOIN sys.master_files sm
		            ON  sd.database_id = sm.database_id
		       JOIN sys.database_files AS f(NOLOCK)
		            ON  sm.physical_name COLLATE DATABASE_DEFAULT = f.physical_name
		WHERE  sm.database_id = DB_ID(@dbname)
		       AND sm.[file_id] = 1
		
		
		
		WHILE @cursize > @excape_mb
		BEGIN
		    SET @cursize = @cursize - @step_mb
		    
		    
		    ----------------------------------------------------
		    SELECT @message = 'shrink to @cursize = ' + ISNULL('''' + CAST(@cursize AS VARCHAR(MAX)) + '''' ,'null')
		    
		    EXEC dbo.log_data_save
		         @log_session_id OUTPUT
		        ,@@procid
		        ,NULL
		        ,@message
		    ----------------------------------------------------		
		    
		    
		    SET @sql = 'dbcc shrinkfile  (''' + @filename + ''',' + cast(@cursize AS VARCHAR(10)) + ')'
            EXEC (@sql)
            --PRINT @sql
		END 
		
		----------------------------------------------------
		EXEC dbo.log_data_save
		     @log_session_id
		    ,@@procid
		    ,@@rowcount
		    ,'Конец'
		     ----------------------------------------------------
	END TRY
	BEGIN CATCH
		--<STD_ERROR_PROCESSING>
		EXEC dbo.std_error_processing 
		     @procedure_desc = @proc_name
		    ,@details_email = 'dbadmin@open.ru'
		    ,@log_session_id = @log_session_id
		    ,@reraise = 1
		     --</STD_ERROR_PROCESSING>
	END CATCH
END






GO
