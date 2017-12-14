
-- размер temp файлов для табличного пространства TEMP
select * from dba_temp_files;

-- использование памяти в temp при выполнении запроса  
delete from plan_table; 
  explain plan for 
  select ch.* from idb.cm_contact_add_char_exp ch
    						join idb.communication_contact_exp_tmp cont
       						on cont.customer_rk=ch.customer_rk and ch.RESPONSE_TRACK_CD=cont.RESPONSE_TRACK_CD;
select * from table( dbms_xplan.display );      


-- кто юзал temp
select sql_id,sample_time,PGA_ALLOCATED,TEMP_SPACE_ALLOCATED 
from DBA_HIST_ACTIVE_SESS_HISTORY
where  SAMPLE_TIME between to_date('09-12-17 18:25:05','DD-MM-YY HH24:MI:SS') and to_date('09-12-17 19:15:05','DD-MM-YY HH24:MI:SS')
order by TEMP_SPACE_ALLOCATED desc;


select sql_id,sample_time,PGA_ALLOCATED,TEMP_SPACE_ALLOCATED 
from DBA_HIST_ACTIVE_SESS_HISTORY
where sql_id='6t2svv7mkma0j'
and
SAMPLE_TIME between to_date('09-12-17 18:15:05','DD-MM-YY HH24:MI:SS') and to_date('09-12-17 19:15:05','DD-MM-YY HH24:MI:SS')
order by sample_time;
