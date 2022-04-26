-- запущенные сессии

SELECT  [EES].[name] AS [Session Name - all sessions] , 
         CASE WHEN [MXS].[name] IS NULL THEN ISNULL([MXS].[name], 'Stopped') 
              ELSE 'Running' 
         END AS SessionState , 
         CASE WHEN [MXS].[name] IS NULL 
              THEN ISNULL([MXS].[name], 
                          'ALTER EVENT SESSION [' + [EES].[name] 
                          + '] ON SERVER STATE = START;') 
              ELSE 'ALTER EVENT SESSION [' + [EES].[name] 
                   + '] ON SERVER STATE = STOP;' 
         END AS ALTER_SessionState , 
         CASE WHEN [MXS].[name] IS NULL 
              THEN ISNULL([MXS].[name], 
                          'DROP EVENT SESSION [' + [EES].[name] 
                          + '] ON SERVER; -- This WILL drop the session. It will no longer exist. Dont do it unless you are certain you can recreate it if you need it.') 
              ELSE 'ALTER EVENT SESSION [' + [EES].[name] 
                   + '] ON SERVER STATE = STOP; ' + CHAR(10) 
                   + '-- DROP EVENT SESSION [' + [EES].[name] 
                   + '] ON SERVER; -- This WILL stop and drop the session. It will no longer exist. Dont do it unless you are certain you can recreate it if you need it.' 
         END AS DROP_Session 
 FROM    [sys].[server_event_sessions] AS EES 
         LEFT JOIN [sys].[dm_xe_sessions] AS MXS ON [EES].[name] = [MXS].[name] 
 WHERE   [EES].[name] NOT IN ( 'system_health', 'AlwaysOn_health' ) 
 ORDER BY SessionState
GO



SELECT  [EES].[name] AS [Session Name - running sessions] , 
         [EESE].[name] AS [Event Name] , 
         COALESCE([EESE].[predicate], 'unfiltered') AS [Event Predicate Filter(s)] , 
         [EESA].[Action] AS [Event Action(s)] , 
         [EEST].[Target] AS [Session Target(s)] , 
         ISNULL([EESF].[value], 'No file target in use') AS [File_Target_UNC] -- select * 
 FROM    [sys].[server_event_sessions] AS EES 
         INNER JOIN [sys].[server_event_session_events] AS [EESE] ON [EES].[event_session_id] = [EESE].[event_session_id] 
         LEFT JOIN [sys].[server_event_session_fields] AS EESF ON ( [EES].[event_session_id] = [EESF].[event_session_id] 
                                                               AND [EESF].[name] = 'filename' 
                                                               ) 
         CROSS APPLY ( SELECT    STUFF(( SELECT  ', ' + sest.name 
                                         FROM    [sys].[server_event_session_targets] 
                                                 AS SEST 
                                         WHERE   [EES].[event_session_id] = [SEST].[event_session_id] 
                                       FOR 
                                         XML PATH('') 
                                       ), 1, 2, '') AS [Target] 
                     ) AS EEST 
         CROSS APPLY ( SELECT    STUFF(( SELECT  ', ' + [sesa].NAME 
                                         FROM    [sys].[server_event_session_actions] 
                                                 AS sesa 
                                         WHERE   [sesa].[event_session_id] = [EES].[event_session_id] 
                                       FOR 
                                         XML PATH('') 
                                       ), 1, 2, '') AS [Action] 
                     ) AS EESA 
 WHERE   [EES].[name] NOT IN ( 'system_health', 'AlwaysOn_health' ) /*Optional to exclude 'out-of-the-box' traces*/
