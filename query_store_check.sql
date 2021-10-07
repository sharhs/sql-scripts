/*
 
 ALTER DATABASE [opendb] SET QUERY_STORE = ON 
 
 ALTER DATABASE opendb SET QUERY_STORE ( OPERATION_MODE = READ_WRITE )
 
 ALTER DATABASE [opendb] SET QUERY_STORE CLEAR
 
*/


DECLARE @Statement nvarchar(MAX);

DROP TABLE IF EXISTS #query_store_info; 

CREATE TABLE #query_store_info 
(
[database_name] nvarchar(128) NOT NULL
, [desired_state] nvarchar(60) NULL 
, actual_state nvarchar(60) NULL
, readonly_reason int NULL
, current_storage_size_mb bigint NULL
, [flush_interval_seconds] bigint NULL
, [interval_length_minutes] bigint NULL
, [max_storage_size_mb] bigint NULL
, stale_query_threshold_days bigint NULL
, [max_plans_per_query] bigint NULL
, [query_capture_mode] nvarchar(60) NULL
, [size_based_cleanup_mode] nvarchar(60) NULL
, [wait_stats_capture_mode] nvarchar(60) NULL
);

SELECT @Statement = N'USE [?];

INSERT INTO #query_store_info 
(
[database_name]
, [desired_state] 
, actual_state
, readonly_reason
, current_storage_size_mb
, [flush_interval_seconds]
, [interval_length_minutes]
, [max_storage_size_mb]
, stale_query_threshold_days
, [max_plans_per_query]
, [query_capture_mode]
, [size_based_cleanup_mode]
, [wait_stats_capture_mode]
)
SELECT
DB_NAME() AS [database_name]
, qso.desired_state_desc AS [desired_state]
, qso.actual_state_desc AS actual_state 
, qso.readonly_reason
, current_storage_size_mb
, [flush_interval_seconds]
, [interval_length_minutes]
, [max_storage_size_mb]
, stale_query_threshold_days
, [max_plans_per_query]
, query_capture_mode_desc AS [query_capture_mode]
, size_based_cleanup_mode_desc AS [size_based_cleanup_mode]
, null
FROM 
sys.database_query_store_options AS qso;';

EXEC sp_MSforeachdb @Statement;

SELECT 
[database_name]
, [desired_state] 
, actual_state
, readonly_reason
, current_storage_size_mb
, [flush_interval_seconds]
, [interval_length_minutes]
, [max_storage_size_mb]
, stale_query_threshold_days
, [max_plans_per_query]
, [query_capture_mode]
, [size_based_cleanup_mode]
, [wait_stats_capture_mode]
FROM
#query_store_info
ORDER BY
[database_name];
GO
