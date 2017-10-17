create or replace FUNCTION         CHECKATTRIBUTES--процедура синхронизирует атрибутный состав целевой и архивируемой таблицы
  (
    schemaName        VARCHAR,--схема, в которой находится архивируемая таблица
    currentTable      VARCHAR,--название архивируемой таблицы
    archiveSchemaName VARCHAR,--схема, в которой лежит архивная таблица
    archiveTable      VARCHAR --название архивной таблицу
  )
  RETURN VARCHAR2
AS
  r_query VARCHAR(3000);
  sql_txt VARCHAR(3000);
 
BEGIN
  r_query := 'yes';

  FOR rec IN
  
  (SELECT column_name,
    data_type, data_length,nvl(DATA_PRECISION,0) as DATA_PRECISION , nvl(DATA_SCALE,0) as DATA_SCALE
  FROM all_tab_columns
  WHERE table_name = upper(currenttable)
  AND owner =upper (schemaName)
  MINUS
  SELECT column_name,
    data_type, data_length,nvl(DATA_PRECISION,0) as DATA_PRECISION , nvl(DATA_SCALE,0) as DATA_SCALE
  FROM all_tab_columns
  WHERE table_name = upper(archivetable)
  AND owner = upper(archiveSchemaName)
  )
  LOOP
	case 
		when rec.data_type in ('DATE','DATETIME','TIMESTAMP','NUMBER') and (rec.DATA_PRECISION = 0 )  then 
			sql_txt := ' ALTER TABLE ' || archiveSchemaName || '.' ||archiveTable || ' ADD( "' || rec.column_name || '" ' || rec.data_type || ')';
			DBMS_OUTPUT.PUT_LINE(sql_txt);
			execute immediate sql_txt;
		when rec.data_type in ('NUMBER') and (rec.DATA_PRECISION > 0 ) then
			sql_txt := ' ALTER TABLE ' || archiveSchemaName || '.' ||archiveTable || ' ADD( "' || rec.column_name || '" ' || rec.data_type || '(' || rec.DATA_PRECISION ||','|| rec.DATA_SCALE || '))';
			DBMS_OUTPUT.PUT_LINE(sql_txt);
			execute immediate sql_txt;
		else 
			sql_txt := ' ALTER TABLE ' || archiveSchemaName || '.' ||archiveTable || ' ADD( "' || rec.column_name || '" ' || rec.data_type || '(' || rec.data_length || '))';
			DBMS_OUTPUT.PUT_LINE(sql_txt);
			execute immediate sql_txt;
	end case;
  END LOOP;
  r_query := 'yes'; 
  DBMS_OUTPUT.PUT_LINE('attributes in table '||currenttable||' is OK');
  return r_query;  
exception 
        when others then 
        r_query := 'no';  
        DBMS_OUTPUT.PUT_LINE('proble with attributes in table '||currenttable);
        return r_query;     
END;
/
exit;