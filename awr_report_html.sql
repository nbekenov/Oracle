   SELECT dbid FROM v$database;
   
   
   select * from DBA_HIST_SNAPSHOT;
   
   select snap_id,
  snap_level,
  to_char(begin_interval_time, 'dd/mm/yy hh24:mi:ss') begin
from 
   dba_hist_snapshot 
order by 1 desc;



SELECT
   output 
FROM   
   TABLE
   (dbms_workload_repository.awr_report_html
      (DB_ID ,1,107388,107395 )
   );
