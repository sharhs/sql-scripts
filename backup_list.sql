USE msdb
GO
SELECT TOP 256 bs.database_name
     , DATENAME(dw, bs.backup_start_date)                            week_day
     , bs.backup_start_date
     , bs.backup_finish_date
     , DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS time_in_min
     , bmf.physical_device_name
     , physical_name
     , bs.[type]
     , (bs.backup_size / 1024) / 1024                                backup_size_mb
     , bs.backup_set_id
     , bs.media_set_id
     , case WHEN bs.type = 'D' THEN 'копирование базы данных'
            WHEN bs.type = 'I' then 'разностное копирование базы данных'
            WHEN bs.type = 'L' then 'копирование журнала'
            WHEN bs.type = 'F' then 'копирование файла или файловой группы'
            WHEN bs.type = 'G' then 'разностное копирование файла'
            WHEN bs.type = 'P' then 'частичное копирование'
            WHEN bs.type = 'Q' then 'частичное разностное копирование'
            WHEN bs.type is NULL then NULL
            END 
FROM backupset bs
INNER JOIN backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
INNER JOIN backupfile bf
    ON bs.backup_set_id = bf.backup_set_id
--WHERE bs.type = 'D'
--    AND bf.physical_name NOT LIKE '%ldf'
    --AND bs.database_name IN ('')
ORDER BY backup_finish_date DESC
