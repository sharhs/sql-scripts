






CREATE procedure [dbo].[set_Jlogging_on_table]
	 @p_schema_name	    varchar(2000)
	,@p_table_name	    varchar(2000)		-- Имя целевой таблицы, на которую вешаем триггер
	,@p_stop_list	    varchar(2000) = ''	-- Стоп-лист. Содержит логины пользователей через запятую.
											-- Если изменение внесено в целевую таблицу одним из этих 
											-- пользователей, изменение не логируется. 
	,@p_context_list	varchar(2000) = ''	-- Содержит список контекстов через запятую. 
											-- Не логируем изменения если установлено одно из перечисленных контекстных значений
    ,@p_debug           int = 0				
with execute as owner						
as
begin


	--<SET>	
	-----------------------------------------------------------------------------------------
	set nocount on
	set xact_abort on
	-----------------------------------------------------------------------------------------
	--</SET>	
	

	begin try

		declare
			 @log_session_id	int				-- для логирования
			,@message			varchar(max)
			,@proc_name			varchar(255) = object_name(@@procid)
			
	    declare 
		    @error_message		varchar(2000)
		    ,@trigger_name		varchar(2000)
		    ,@command			varchar(max)
		    ,@stop_list		    varchar(8000)
		    ,@database_name	    varchar(255)    = db_name()
		    ,@column_list		varchar(max)
		    ,@context_list		varchar(8000)
		    ,@object_id         int             = object_id(quotename(@p_schema_name) + N'.' + quotename(@p_table_name));
			
		----------------------------------------------------
		select
			@message =
				@proc_name
-- логируем параметры, с которыми вызвана процедура
				+' @p_schema_name='+isnull(''''+cast(@p_schema_name as varchar(max))+'''','null')
				+' @p_table_name='+isnull(''''+cast(@p_table_name as varchar(max))+'''','null')
				+',@p_stop_list='+isnull(''''+cast(@p_stop_list as varchar(max))+'''','null')
				+',@p_context_list='+isnull(''''+cast(@p_context_list as varchar(max))+'''','null')
				+',@p_debug='+isnull(''''+cast(@p_debug as varchar(max))+'''','null')
		exec dbo.log_data_save
				@log_session_id output,
				@@procid,
				null,
				@message
		----------------------------------------------------		

	    --
	    -- Проверки
	    --
	    if @object_id is null
	    begin
		    select @error_message = 'Таблица ' + cast(@p_table_name as varchar(2000)) + ' не найдена'
		    return -1
	    end

	    if charindex('''', @p_stop_list) > 0
	    begin
		    select @error_message = 'Неверный формат строки @p_stop_list: содержит одинарную кавычку'
		    return -1
	    end
        
        --
	    -- 1. Удаляем логирование если уже есть
	    --

	    exec remove_logging_on_table @p_schema_name, @p_table_name;

	    --
	    -- 2. Сборка строк
	    --

	    -- Имя триггера
	    select 
		    @trigger_name = quotename(object_schema_name(@object_id)) + '.' + 'tr_auto_generated_json_log_' + REPLACE(object_schema_name(@object_id) + N'.' + object_name(@object_id), '.','_')

    					
	    -- Собираем стоп-лист для динамического SQL: добавляем кавычки
	    select 
		    @stop_list = '''' + replace(cast(@p_stop_list as varchar(8000)), ',', ''',''') + ''''
    	
	    select
		    @context_list = '''' + replace(cast(@p_context_list as varchar(8000)), ',', ''',''') + ''''
    	
	    --select 
		   -- @column_list = (
			  --  select
			  --      case
			  --          when type_name(system_type_id) in ('binary', 'varbinary')
     --                   then ',convert(nvarchar(max),[' + name + '],1) as [' + name + ']'
				 --       else ',['+name+']'
				 --   end             as [data]
			  --  from
				 --   sys.columns
			  --  where
				 --   object_id = object_id(@p_table_name)
				 --   and type_name(system_type_id) not in ('text', 'ntext')
			  --  for json auto
		   -- )
		   
	    select 
		    @column_list = (
			    select
			        case
			            when type_name(system_type_id) in ('binary', 'varbinary') 
                        then ',convert(nvarchar(max),[' + name + '],1) as [' + name + ']'
				        else ',['+name+']' 
				    end             as [data()]
			    from
				    sys.columns
			    where
				    object_id = @object_id
				    and type_name(system_type_id) not in ('text', 'ntext')
			    for xml path('')
		    )		   
	    select 
		    @column_list = substring(@column_list, 2, len(@column_list))

	    --
	    -- 3. Внести в список логируемых таблиц
	    --

	    insert into
		    logdb.dbo.log_tables(
			    table_name		
			    ,trigger_name
			    ,stop_list
			    ,database_name
			    ,[schema_name]
		    )
	    select
		    @p_table_name
		    ,@trigger_name
		    ,@p_stop_list	
		    ,@database_name
		    ,@p_schema_name

	    --
	    -- 4. Сборка и выполнение динамического SQL
	    --

	    select
		    @command = 
			    'create trigger ' + @trigger_name + '
			    on ' + quotename(object_schema_name(@object_id)) + '.' + quotename(object_name(@object_id)) + '
			    for update, delete , insert
			    as begin
				exec as login =''logdb_operator''
				    -- Триггер создан автоматически процедурой '+object_name(@@procid)+'
				    -- менять код триггера вручную не рекомендуется, так как триггер может быть пересоздан.
    		
				     -----------------------------------------------------------------------------------------
				     set nocount on
				     set transaction isolation level read uncommitted
				     set xact_abort off 	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Выключено, иначе приводит к ошибкам
				     --	 в try ... catch
				     -----------------------------------------------------------------------------------------
				    declare 
					       @xml     nvarchar(max)
					      ,@table   sysname
					      ,@t_id    int
					      ,@act     char(1)

				    if system_user in (' + @stop_list + ')
					    return
    				
				    if dbo.fn_context_info_get() in (' + @context_list + ')
					    return
    									
				    begin try

					    select
						       @table = object_name(parent_id)
						      ,@t_id     = parent_id
					     from
						      sys.triggers 
					     where 
						      [object_id] = @@procid
						      
						      
						      

                        if exists(select * from deleted) and exists (select * from inserted)
                        begin
                            select @act = ''U''
                            select @xml = (
                                       select '+@column_list+'
                                       from   deleted 
                                              for json auto
                                   )
                        end
                        if not exists(select * from deleted) and exists (select * from inserted)
                        begin
                            select @act = ''I''
                            select @xml = (
                                       select '+@column_list+'
                                       from   inserted 
                                              for json auto
                                   )
                        end
                        if exists(select * from deleted) and not exists (select * from inserted)
                        begin
                            select @act = ''D''
                            select @xml = (
                                       select '+@column_list+'
                                       from   deleted
                                              for json auto
                                   )
                        end


                        if isnull(@xml, '''') = ''''
                            return

					    declare 
						    @obj_id		int
					       ,@action		char(1)
					       ,@who		nvarchar(100)
					       ,@host		nvarchar(100)
					       ,@time		datetime
					       ,@data		nvarchar(max)
					       ,@obj_name	sysname

					    select
						    @obj_id		=@t_id
					       ,@action		=@act
					       ,@who		=original_login()
					       ,@host		=host_name()
					       ,@time		=getdate()
					       ,@data		=@xml
					       ,@obj_name	=@table
    		
					    exec dbo.Jlog_action
						    @obj_id		
					       ,@action		
					       ,@who		
					       ,@host		
					       ,@time		
					       ,@data		
					       ,@obj_name

				    end try
				    begin catch

					    declare 
						    @message		varchar(2000)
						    ,@object_name	varchar(2000)
						    ,@severity		varchar(2000)
						    ,@email			varchar(2000)
						    ,@body			varchar(2000)
						    ,@subject		varchar(2000)
					    select 
						    @message = error_message()
						    ,@object_name = object_name(@@procid)
						    ,@severity = error_severity()
						    ,@email = ''db_errors@open.ru''


					    select
						    @subject		= '''+@@servername+': ошибка логирования''
					    select
						    @body			= @subject 
											    + char(13) + char(10) + ''Объект '' + isnull(@object_name, ''NULL'')
											    + char(13) + char(10) + ''Сообщение '' + isnull(@message, ''NULL'')
											    + char(13) + char(10) + ''Тяжесть ошибки '' + isnull(cast(@severity as varchar(2000)), ''NULL'')

					    exec msdb.dbo.sp_send_dbmail
						     @recipients	= @email
						    ,@subject		= @subject
						    ,@body			= @body

				    end catch
					revert
			    end'

        if @p_debug > 0
  print @command
        if @p_debug < 2
		    exec (@command)
		    
		----------------------------------------------------
		exec dbo.log_data_save
				@log_session_id,
				@@procid,
				@@rowcount,
				'Конец'
		----------------------------------------------------

	end try
	begin catch

		--<STD_ERROR_PROCESSING>
		exec dbo.std_error_processing 
			 @procedure_desc			= @proc_name
			,@details_email				= 'db_errors@open.ru'
			,@log_session_id			= @log_session_id
			,@reraise					= 1
		--</STD_ERROR_PROCESSING>

	end catch 
	
/*	
-- сохранение временных таблиц/табличных переменных в глобальные временные таблицы
	if @p_debug	> 0
	begin
		if object_id('tempdb..#') is not null drop table #
		select * into # from 
	end
*/		    

end









