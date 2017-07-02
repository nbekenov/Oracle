show parameter db_recovery_file_dest;

shutdown immediate;
startup mount;
alter database archivelog;
alter database flashback on;

select flashback_on from v$database;
select log_mode from v$database;
alter database open;

show recyclebin;

select * from tab2;
FLASHBACK table tab2 to before drop;


flashback table to timestamp to_date('26-JUN-14','dd-MON-YY hh24:mi:ss');

