select to_char(last_analyzed,'YYYY-MM-DD hh24:mm')
 from all_tables
 where owner='CDM'
 and TABLE_NAME='TETS';