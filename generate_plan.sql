SELECT DBMS_SQLTUNE.report_sql_detail(
sql_id => 'gua1s8bsr0jyx',
type => 'ACTIVE',
report_level => 'ALL') AS report
FROM dual;

select dbid from v$database;
select snap_id,
  snap_level,
  to_char(begin_interval_time, 'dd/mm/yy hh24:mi:ss') begin
from 
   dba_hist_snapshot 
order by 1 desc;


select dbid from v$database;
select snap_id,
  snap_level,
  to_char(begin_interval_time, 'dd/mm/yy hh24:mi:ss') begin
from 
   dba_hist_snapshot 
order by 1 desc;

select plan_table_output from
    table(dbms_xplan.display_cursor('gua1s8bsr0jyx',null,'basic'));