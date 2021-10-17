USE master
GO
ALTER DATABASE <dbname,,dbname> SET OFFLINE WITH ROLLBACK IMMEDIATE


RESTORE DATABASE [<dbname,,dbname>]
	FROM  DISK = N'<path,,\\path>\<bk_name,,bk_name>.bak'
WITH  
move N'<dbname,,dbname>' to N'<db_path,,disk:\db_path\><dbname,,dbname>.mdf',
move N'<dbname,,dbname>_log' to N'<log_path,,disk:\log_path\><dbname,,dbname>_log.ldf',
	FILE = 1,  
	NOUNLOAD,  
	REPLACE,
	STATS = 1
GO
