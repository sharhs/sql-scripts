SELECT SUM(
           pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb + awe_allocated_kb
       ) / 1024 AS outside_bufferpool_mb
FROM   sys.dm_os_memory_clerks
WHERE  TYPE <> 'MEMORYCLERK_SQLBUFFERPOOL'

SELECT SUM(
           pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb + awe_allocated_kb
       ) / 1024 AS bufferpool_mb
FROM   sys.dm_os_memory_clerks
WHERE  TYPE = 'MEMORYCLERK_SQLBUFFERPOOL'




SELECT objtype AS 'Cached Object Type', 
COUNT(*) AS 'Numberof Plans', 
SUM(CAST(size_in_bytes AS BIGINT))/1048576 AS 'Plan Cache SIze (MB)', 
AVG(cast(usecounts AS BIGINT)) AS 'Avg Use Counts' 
FROM sys.dm_exec_cached_plans 
GROUP BY objtype  
ORDER BY objtype


SELECT NAME
      ,[type]
      ,memory_node_id
      ,SUM(pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb + awe_allocated_kb ) / 1024  AS outside_bufferpool_mb
FROM   sys.dm_os_memory_clerks
GROUP BY
       NAME
      ,[type]
      ,memory_node_id
ORDER BY
       4            DESC




--   DBCC FREEPROCCACHE



SELECT *
FROM   sys.dm_os_memory_clerks
ORDER BY  pages_kb DESC

SELECT *
FROM   sys.dm_os_memory_allocations

SELECT *
FROM   sys.dm_os_sys_info

SELECT *
FROM   sys.dm_os_performance_counters
WHERE  count_name

-------------------------------------------------------------------------
SELECT TYPE
      ,SUM(
           single_pages_kb + multi_pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb + 
           awe_allocated_kb
       ) / 1024                          AS summ_Mb
      ,SUM(virtual_memory_reserved_kb)   AS [vm reserved]
      ,SUM(virtual_memory_committed_kb)  AS [vm committed]
      ,SUM(awe_allocated_kb)             AS [awe allocated]
      ,SUM(shared_memory_reserved_kb)    AS [sm reserved]
      ,SUM(shared_memory_committed_kb)   AS [sm committed]
      ,SUM(multi_pages_kb)               AS [multipage allocator]
      ,SUM(single_pages_kb)              AS [sinlgepage allocator]
      ,CONVERT(VARCHAR ,GETDATE() ,120)  AS eventtime
FROM   sys.dm_os_memory_clerks
GROUP BY
       TYPE
ORDER BY
       summ_Mb DESC

-------------------------------------------------------------------------

SELECT DISTINCT cc.cache_address
      ,cc.name
      ,cc.type
      ,cc.single_pages_kb + cc.multi_pages_kb AS total_kb
      ,cc.single_pages_in_use_kb + cc.multi_pages_in_use_kb AS total_in_use_kb
      ,cc.entries_count
      ,cc.entries_in_use_count
      ,ch.removed_all_rounds_count
      ,ch.removed_last_round_count
FROM   sys.dm_os_memory_cache_counters cc
       JOIN sys.dm_os_memory_cache_clock_hands ch
            ON  (cc.cache_address = ch.cache_address)
                
                --uncomment this block to have the information only for moving hands caches
WHERE  ch.rounds_count > 0
       AND ch.removed_all_rounds_count > 0
ORDER BY
       total_kb DESC



SELECT (physical_memory_in_use_kb / 1024) / 1024 AS [PhysicalMemInUseGB]
FROM   sys.dm_os_process_memory;
GO
