/*desplay all tabel's columns in line */
SET SERVEROUTPUT ON
declare
cursor get_col is
select COLUMN_NAME from all_TAB_COLS
where TABLE_NAME='&tabel_name';
col_name varchar2(36);
begin

open get_col;
loop 
  exit when get_col%NOTFOUND;
  DBMS_OUTPUT.enable;
  fetch get_col into col_name;
  DBMS_OUTPUT.put(col_name || ',');
end loop;
dbms_output.put_line('.');
close get_col;
end;
/
