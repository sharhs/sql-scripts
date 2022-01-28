BEGIN TRY
	DROP TABLE ##trc
END TRY
BEGIN CATCH
END CATCH;
SELECT TOP 0 * INTO   ##trc FROM   fn_trace_gettable('D:\trc\reads_trace.trc',1) ;CREATE CLUSTERED INDEX ixc ON ##trc(StartTime ,spid)
 INSERT INTO ##trc SELECT * FROM   fn_trace_gettable('D:\trc\reads_trace.trc',1)



--INSERT INTO ##trc_res
SELECT TOP 64
       [ObjectName]
       ,[DatabaseName]
      ,[SQL]             = left(CAST(TextData AS VARCHAR(MAX)),44)
      ,[avg]             = 'avg'
      ,[AvgReads]        = AVG(Reads)
      ,[AvgWrites]       = AVG(Writes)
      ,[AvgdurMlsec]     = AVG(Duration) / 1000
      ,[max]             = 'max'
      ,[MaxReads]        = MAX(Reads)
      ,[MaxWrites]       = MAX(Writes)
      ,[MaxDurMlsec]     = MAX(Duration) / 1000
      ,[sum]             = 'sum'
      ,[SumReads]        = SUM(Reads)
      ,[SumWrites]       = SUM(Writes)
      ,[SumDurMlsec]     = SUM(Duration) / 1000
      ,[min]             = 'min'
      ,[MinReads]        = MIN(Reads)
      ,[MinWrites]       = MIN(Writes)
      ,[MinDurMlsec]     = MIN(Duration) / 1000
      ,[ExecCnt]         = COUNT(left(CAST(TextData AS VARCHAR(MAX)),44))
      ,[From]            = MIN(StartTime)
      ,[To]              = MAX(StartTime)
      ,[ApplicationName]
FROM   tempdb.dbo.directum_q AS tc
WHERE  (EventClass = 45 OR EventClass = 41)
       AND CAST(TextData AS VARCHAR(MAX)) NOT LIKE 'exec%'
       AND CAST(TextData AS VARCHAR(MAX)) NOT LIKE 'waitfor%'

GROUP BY
       left(CAST(TextData AS VARCHAR(MAX)),44)
      ,[ObjectName]
      ,[ApplicationName]
      ,[DatabaseName]
ORDER BY
       [SumDurMlsec] DESC
	
	
	
	
	
SELECT TOP 100
       LoginName
      ,SPID
      ,Objectname
      ,TextData
      ,Duration / 1000     Duration_millisec
      ,Reads
      ,Writes
      ,CPU
      ,RowCounts
      ,HostName
      ,StartTime
      ,endtime
      ,DatabaseName
FROM   ##trc
WHERE [TextData] LIKE '%D.dogovor_type = 4 or D.dogovor_type = 137%'

       AND StartTime BETWEEN '20180201 17:45:00' AND '20180201  17:55:00'


SELECT Objectname
      ,SUM(Reads)         AS sum_reads
      ,AVG(Reads)         AS avg_reads
      ,SUM(Writes)        AS sum_Writes
      ,ROUND(CONVERT(FLOAT ,AVG(Duration) ,1) / 1000000 ,1) AS avg_sec
      ,COUNT(Objectname)  AS exec_cnt
      ,ROUND(CONVERT(FLOAT ,SUM(Duration)) / 1000000 ,1) AS sum_sec
FROM   ##trc
WHERE  EventClass = 45
       AND CAST(TextData AS VARCHAR(4000)) NOT LIKE 'exec%'
GROUP BY
       Objectname
ORDER BY
       sum_reads DESC
       
       
SELECT TOP 35
       [ObjectName]
      ,[SQL]             = CAST(TextData AS VARCHAR(MAX))
      ,[avg]             = 'avg'
      ,[AvgReads]        = AVG(Reads)
      ,[AvgWrites]       = AVG(Writes)
      ,[AvgdurMlsec]     = AVG(Duration) / 1000
      ,[max]             = 'max'
      ,[MaxReads]        = MAX(Reads)
      ,[MaxWrites]       = MAX(Writes)
      ,[MaxDurMlsec]     = MAX(Duration) / 1000
      ,[sum]             = 'sum'
      ,[SumReads]        = SUM(Reads)
      ,[SumWrites]       = SUM(Writes)
      ,[SumDurMlsec]     = SUM(Duration) / 1000
      ,[min]             = 'min'
      ,[MinReads]        = MIN(Reads)
      ,[MinWrites]       = MIN(Writes)
      ,[MinDurMlsec]     = MIN(Duration) / 1000
      ,[ExecCnt]         = COUNT(CAST(TextData AS VARCHAR(MAX)))
      ,[From]            = MIN(StartTime)
      ,[To]              = MAX(StartTime)
      ,[ApplicationName]
FROM   ##trc
WHERE  (EventClass = 45 OR EventClass = 41)
       AND CAST(TextData AS VARCHAR(MAX)) NOT LIKE 'exec%'
       AND [ObjectName] = 'close_day_overnight_newtarif'
GROUP BY
       CAST(TextData AS VARCHAR(MAX))
      ,[ObjectName]
      ,[ApplicationName]
ORDER BY
       [SumReads] DESC
		
	
	
	
	
	
	
	
	
		
	
SELECT TOP 10 * 
FROM   ##trc AS t	


SELECT LoginName
      ,SPID
      ,Objectname
      ,TextData
      ,Duration / 1000       Duration_millisec
      ,Reads
      ,Writes
      ,CPU
      ,RowCounts
      ,HostName
      ,StartTime
      ,endtime
      ,DatabaseName
FROM   ##trc
WHERE [ObjectName] = 'haven_accounts_tree'
ORDER BY
       starttime 
	
			
	
	




SELECT Objectname
      ,DatabaseName
      ,CAST(TextData AS NVARCHAR(MAX))  AS [text]
      ,SUM(Reads)                       AS [sum_Reads]
      ,CAST(SUM(Reads) / 1000000.0 AS NUMERIC(9 ,5)) AS [sum_Reads_mln]
      ,MAX(Reads)                       AS [max_Reads]
      ,SUM(Reads) / COUNT(CAST(TextData AS NVARCHAR(MAX))) AS [avg_Reads]
      ,SUM(CPU)                         AS [sum_CPU]
      ,CAST(
           SUM(Reads) / COUNT(CAST(TextData AS NVARCHAR(MAX))) / 1000000.0 AS NUMERIC(9 ,2)
       )                                AS [avg_Reads_mln]
      ,SUM(Writes)                      AS [sum_Writes] 
       --CAST(ROUND(CONVERT(Float, AVG(Duration), 1) / 1000, 1) / COUNT(CAST(TextData AS Varchar(Max))) AS Numeric(9, 5))                             AS [avg_dur_msec],	--CAST(ROUND(CONVERT(Float, AVG(Duration), 1) / 1000000, 1) / COUNT(CAST(TextData AS Varchar(Max))) AS Numeric(9, 5))                             AS [avg_dur_sec],
      ,ROUND(CONVERT(FLOAT ,MIN(Duration) ,1) / 1000 ,1) AS [min_dur_msec]
      ,ROUND(CONVERT(FLOAT ,MAX(Duration) ,1) / 1000 ,1) AS [max_dur_msec]
      ,ROUND(CONVERT(FLOAT ,AVG(Duration) ,1) / 1000 ,1) AS [ang_dur_msec]
      ,ROUND(CONVERT(FLOAT ,SUM(Duration)) / 1000 ,1) AS [sum_mseconds]
      ,ROUND(CONVERT(FLOAT ,SUM(Duration)) / 1000000 ,1) AS [sum_seconds]
      ,COUNT(CAST(TextData AS NVARCHAR(MAX))) AS [exec_cnt]
      ,MIN(EndTime)                     AS [from]
      ,MAX(EndTime)                     AS [to]
FROM   ##trc
WHERE  (EventClass = 45 OR EventClass = 41)
       AND CAST(TextData AS VARCHAR(4000)) NOT LIKE 'exec%'
GROUP BY
       Objectname
      ,DatabaseName
      ,CAST(TextData AS NVARCHAR(MAX))
      ,Objectname
      ,[applicationname]
ORDER BY
       [sum_Reads] DESC
       
       
       
       
       
       
       
       
       TextData 
       BinaryData 
       DatabaseID 
       TransactionID 
       LineNumber 
       NTUserName NTDomainName HostName ClientProcessID ApplicationName LoginName SPID Duration StartTime EndTime Reads 
       Writes CPU PERMISSIONS Severity EventSubClass ObjectID Success IndexID IntegerData ServerName EventClass 
       ObjectType NestLevel STATE ERROR Mode Handle ObjectName DatabaseName FILENAME OwnerName RoleName TargetUserName 
       DBUserName LoginSid TargetLoginName TargetLoginSid ColumnPermissions LinkedServerName ProviderName MethodName 
       RowCounts RequestID XactSequence EventSequence BigintData1 BigintData2 GUID IntegerData2 ObjectID2 TYPE OwnerID 
       ParentName IsSystem Offset SourceDatabaseID SqlHandle SessionLoginName PlanHandle GroupID



INSERT INTO ##trc_res
SELECT TOP 35 [Objectname]
      ,SUM(Reads)                       AS [sum_Reads]
      ,SUM(Writes)                      AS [sum_Writes]
      ,ROUND(CONVERT(FLOAT ,AVG(Duration) ,1) / 1000 ,1) AS [avg_dur_msec]
      ,SUM(Reads) / COUNT(CAST(TextData AS VARCHAR(4000))) AS [avg_Reads]
      ,COUNT(CAST(TextData AS VARCHAR(4000))) AS [exec_cnt]
      ,CAST(
           ROUND(CONVERT(FLOAT ,AVG(Duration) ,1) / 1000 ,1)
           / COUNT(CAST(TextData AS VARCHAR(4000))) AS NUMERIC(9 ,2)
       )                                AS [avg_dur_msec]
      ,ROUND(CONVERT(FLOAT ,MIN(Duration) ,1) / 1000 ,1) AS [min_dur_msec]
      ,ROUND(CONVERT(FLOAT ,MAX(Duration) ,1) / 1000 ,1) AS [max_dur_msec]
      ,ROUND(CONVERT(FLOAT ,SUM(Duration)) / 1000 ,1) AS [sum_mseconds]
      ,CAST(TextData AS VARCHAR(4000))  AS [text]
      ,MIN(EndTime)                     AS [from]
      ,MAX(EndTime)                     AS [to]
FROM   ##trc
WHERE  (EventClass = 45 OR EventClass = 41)
       AND CAST(TextData AS VARCHAR(4000)) NOT LIKE 'exec%'
       AND CAST(TextData AS VARCHAR(4000)) NOT LIKE 'waitfor%'
       AND Objectname IS NOT               NULL
GROUP BY
       CAST(TextData AS VARCHAR(4000))
      ,Objectname
      ,[applicationname]
ORDER BY
       [sum_mseconds] DESC
       
       
       /*
       exec xp_cmdshell 'dir F:\traces\ /B'
       select * from sys.traces
       exec sp_trace_setstatus 
       h:\traces\BD-SRV-ТITAN_Filter_by_Duration_regular_20160623.trc
       BD-SRV-ТITAN_Filter_by_Duration_regular_20160705.trc
       */
	
	
	
	
SELECT DISTINCT 
       LoginName = REPLACE(LoginName, 'OPEN.RU','open.ru')
      ,ApplicationName
      ,HostName
FROM   ##trc	
ORDER BY LoginName 
      ,ApplicationName
      ,HostName
