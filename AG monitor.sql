SELECT
    ar.replica_server_name as [Replica]
    ,DB_NAME(drs.database_id) AS DB
    ,drs.synchronization_state_desc as [Sync State]
    ,ars.synchronization_health_desc as [Health]
    ,ar.availability_mode as [Syncronous]
    ,drs.log_send_queue_size
    ,drs.redo_queue_size
    ,ISNULL(
        GhostReplicaState.max_low_water_mark_for_ghosts -
            drs.low_water_mark_for_ghosts,0
    ) AS [water_mark_diff]
    ,drs.log_send_rate
    ,drs.redo_rate
    ,pri.last_commit_time AS primary_last_commit_time
    ,IIF(drs.is_primary_replica = 1
        ,pri.last_commit_time
        ,drs.last_commit_time
    ) AS node_last_commit_time
    ,IIF(drs.is_primary_replica = 1
        ,0
        ,DATEDIFF(ms,drs.last_commit_time,pri.last_commit_time)
    ) AS commit_latency
FROM 
    sys.availability_groups ag WITH (NOLOCK) 
        JOIN sys.availability_replicas ar WITH (NOLOCK) ON 
            ag.group_id = ar.group_id
        JOIN sys.dm_hadr_availability_replica_states ars WITH (NOLOCK) ON 
            ar.replica_id = ars.replica_id
        JOIN sys.dm_hadr_database_replica_states drs WITH (NOLOCK) ON 
            ag.group_id = drs.group_id AND 
            drs.replica_id = ars.replica_id
        LEFT JOIN sys.dm_hadr_database_replica_states pri WITH (NOLOCK) ON 
            pri.is_primary_replica = 1 AND 
            drs.database_id = pri.database_id
        OUTER APPLY
         (
            SELECT MAX(drs2.low_water_mark_for_ghosts) AS 
                    max_low_water_mark_for_ghosts
            FROM sys.dm_hadr_database_replica_states drs2 WITH (NOLOCK)
            WHERE drs.database_id = drs2.database_id
        ) GhostReplicaState
WHERE	
    ars.is_local = 0
ORDER BY 
    replica_server_name, DB;
