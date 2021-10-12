select deqp.session_id
      ,deqp.node_id
	  ,deqp.physical_operator_name
      ,deqp.row_count
      ,deqp.estimate_row_count
      ,deqp.database_id
      ,deqp.[object_id]
      ,deqp.index_id
      ,deqp.scan_count
      ,deqp.logical_read_count
      ,deqp.physical_read_count
      ,deqp.read_ahead_count
      ,deqp.write_page_count
      ,deqp.estimated_read_row_count
      ,deqp.actual_read_row_count
from   sys.dm_exec_query_profiles as deqp
where  deqp.session_id = 
