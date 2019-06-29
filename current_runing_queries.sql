select s.sid, s.serial#, s.sql_id, s.sql_child_number, to_char(s.sql_exec_start, 'yyyy-mm-dd hh24:mi:ss'), substr(v$sql.sql_text,1,100), s.username, s.status, s.module, s.machine, s.event,s.wait_class, s.wait_time, s.seconds_in_wait, s.wait_time_micro 
  from v$session s left join v$sql on s.sql_id = v$sql.sql_id 
    where s.sql_id is not null and sid <> sys_context('userenv','sid');
