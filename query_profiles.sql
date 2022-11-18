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



select deqp.session_id
      ,deqp.node_id
	  ,deqp.physical_operator_name
      ,sum(deqp.row_count)  row_count
      ,sum(deqp.estimate_row_count) estimate_row_count
      ,sum(deqp.scan_count) scan_count
      ,sum(deqp.logical_read_count ) logical_read_count
      ,sum(deqp.physical_read_count) physical_read_count
      ,sum(deqp.read_ahead_count) read_ahead_count
      ,sum(deqp.write_page_count) write_page_count
      ,sum(deqp.estimated_read_row_count) estimated_read_row_count
      ,sum(deqp.actual_read_row_count) actual_read_row_count
from   sys.dm_exec_query_profiles as deqp
where  deqp.session_id = 870
GROUP BY deqp.session_id, deqp.node_id, deqp.physical_operator_name
ORDER BY deqp.node_id ASC
