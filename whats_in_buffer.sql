-- Get total buffer usage by database for current instance  (Query 26) (Total Buffer Usage by Database)
WITH AggregateBufferPoolUsage AS 
(
SELECT db_name(Database_id) AS [Database Name]
	,cast(count(*) * 8/1024.0 AS dECIMAL (10,2)) AS [CachedSize]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE Database_id <> 32767 -- ResourceDB
GROUP BY db_name(Database_id)
) 
SELECT row_number() OVER(ORDER BY CachedSize DESC) AS [Buffer Pool Rank]
	,[Database Name]
	,CachedSize AS [Cached Size (MB)]
	,cast(CachedSize / sum(CachedSize) OVER() * 100.0 AS dECIMAL(5,2)) AS [Buffer Pool Percent]
FROM AggregateBufferPoolUsage 
ORDER BY [Buffer Pool Rank]
OPTION (RECOMPILE);


-- Breaks down buffers used by current database by object (table, index) in the buffer cache  (Query 55) (Buffer Usage)
SELECT OBJECT_NAME(P.[Object_id])  AS [Object Name]
      ,P.Index_id
      ,CAST(COUNT(*)/128.0 AS DECIMAL(10 ,2)) AS [Buffer size(MB)]
      ,COUNT(*)                    AS [BufferCount]
      ,P.Rows                      AS [Row Count]
      ,P.Data_compression_desc     AS [Compression Type]
FROM   sys.allocation_units        AS A WITH (NOLOCK)
       INNER JOIN sys.dm_os_buffer_descriptors AS B WITH (NOLOCK)
            ON  A.Allocation_unit_id = B.Allocation_unit_id
       INNER JOIN sys.partitions   AS P WITH (NOLOCK)
            ON  A.Container_id = P.Hobt_id
WHERE  B.Database_id = CONVERT(INT ,DB_ID())
AND    P.[Object_id]>100
GROUP BY
       P.[Object_id]
      ,P.Index_id
      ,P.Data_compression_desc
      ,P.[Rows]
ORDER BY
       [BufferCount] DESC
       OPTION(RECOMPILE);
