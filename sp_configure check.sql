/* Отчёт по настройкам сервера.
* Developer: TEH3OP <gmail.com>
* Description: Скрипт собирает текущие настройки сервера 
*      sys.sp_configure и их значения по умолчанию в 
*      таблицу #sys_sp_configure. #sys_sp_configure можно 
*      использовать для анализа текущих настроек сервера. 
*      Работает с MS SQL 2005..2012.
*
* 2016-06-01; TEH3OP;      Модуль создан.
* * * * * * * * * * * * * * * * * * * * * * * * * * * */
SET NOCOUNT ON;

BEGIN TRY
       CREATE TABLE #sys_sp_configure 
       (      [name]             [nvarchar](35) NOT NULL
       ,      [minimum]          [int] NULL
       ,      [maximum]          [int] NULL
       ,      [config_value]     [int] NULL
       ,      [run_value]        [int] NULL
       ,      [default_value]    [int] NULL)    
END TRY
BEGIN CATCH
       TRUNCATE TABLE #sys_sp_configure;
END CATCH;


INSERT INTO #sys_sp_configure
(      name
,      minimum
,      maximum
,      config_value
,      run_value)
EXEC sys.sp_configure;

UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'access check cache bucket count';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'access check cache quota';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'Ad Hoc Distributed Queries';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'affinity I/O mask';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'affinity mask';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'affinity64 I/O mask';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'affinity64 mask';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'Agent XPs';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'allow updates';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'backup compression default';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'blocked process threshold (s)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'c2 audit mode';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'clr enabled';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'common criteria compliance enabled';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'contained database authentication';
UPDATE #sys_sp_configure SET default_value = 5 WHERE [name] = N'cost threshold for parallelism';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'cross db ownership chaining';
UPDATE #sys_sp_configure SET default_value = -1 WHERE [name] = N'cursor threshold';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'Database Mail XPs';
UPDATE #sys_sp_configure SET default_value = 1033 WHERE [name] = N'default full-text language';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'default language';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'default trace enabled';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'disallow results from triggers';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'EKM provider enabled';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'filestream access level';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'fill factor (%)';
UPDATE #sys_sp_configure SET default_value = 100 WHERE [name] = N'ft crawl bandwidth (max)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'ft crawl bandwidth (min)';
UPDATE #sys_sp_configure SET default_value = 100 WHERE [name] = N'ft notify bandwidth (max)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'ft notify bandwidth (min)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'index create memory (KB)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'in-doubt xact resolution';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'lightweight pooling';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'locks';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'max degree of parallelism';
UPDATE #sys_sp_configure SET default_value = 4 WHERE [name] = N'max full-text crawl range';
UPDATE #sys_sp_configure SET default_value = 2147483647 WHERE [name] = N'max server memory (MB)';
UPDATE #sys_sp_configure SET default_value = 65536 WHERE [name] = N'max text repl size (B)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'max worker threads';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'media retention';
UPDATE #sys_sp_configure SET default_value = 1024 WHERE [name] = N'min memory per query (KB)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'min server memory (MB)';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'nested triggers';
UPDATE #sys_sp_configure SET default_value = 4096 WHERE [name] = N'network packet size (B)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'Ole Automation Procedures';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'open objects';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'optimize for ad hoc workloads';
UPDATE #sys_sp_configure SET default_value = 60 WHERE [name] = N'PH timeout (s)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'precompute rank';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'priority boost';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'query governor cost limit';
UPDATE #sys_sp_configure SET default_value = -1 WHERE [name] = N'query wait (s)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'recovery interval (min)';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'remote access';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'remote admin connections';
UPDATE #sys_sp_configure SET default_value = 10 WHERE [name] = N'remote login timeout (s)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'remote proc trans';
UPDATE #sys_sp_configure SET default_value = 600 WHERE [name] = N'remote query timeout (s)';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'Replication XPs';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'scan for startup procs';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'server trigger recursion';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'set working set size';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'show advanced options';
UPDATE #sys_sp_configure SET default_value = 1 WHERE [name] = N'SMO and DMO XPs';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'transform noise words';
UPDATE #sys_sp_configure SET default_value = 2049 WHERE [name] = N'two digit year cutoff';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'user connections';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'user options';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'xp_cmdshell';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'blocked process threshold';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'awe enabled';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'SQL Mail XPs';
UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'Web Assistant Procedures';
--UPDATE #sys_sp_configure SET default_value = 0 WHERE [name] = N'';

SELECT 
       *
       , [sql] = REPLACE(REPLACE(
                    N'EXEC sys.sp_configure ?(opt), ?(val); RECONFIGURE;'
                    ,      N'?(opt)',   QUOTENAME([name], ''''))
                    ,      N'?(val)', QUOTENAME(config_value, ''''))
FROM   #sys_sp_configure
WHERE  config_value <> default_value;
