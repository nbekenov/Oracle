create or replace FUNCTION CHECKTYPES--процедура синхронизирует типы атрибуто в целевой и архивируемой таблицы
  (
    schemaName        VARCHAR,--схема, в которой находится архивируемая таблица
    currentTable      VARCHAR,--название архивируемой таблицы
    archiveSchemaName VARCHAR,--схема, в которой лежит архивная таблица
    archiveTable      VARCHAR --название архивной таблицу
  )
  RETURN VARCHAR2
AS
  drop_column   VARCHAR(3000);
  rename_column VARCHAR(3000);
  add_column    VARCHAR(3000);
  update_column VARCHAR(3000);
  r_query       VARCHAR(3000) := 'yes';
  ex_query      VARCHAR(3000);

BEGIN
  --находим поля с одинаковым именем, но разными типами или разной длиной
  FOR rec IN
  (SELECT a.data_type ctype,
    b.data_type atype,
    a.data_length cdata_length,
    b.data_length adata_length,
    a.column_name column_name,
	  nvl(a.DATA_PRECISION,0) cDATA_PRECISION,
    nvl(b.DATA_PRECISION,0) aDATA_PRECISION,
    nvl(a.DATA_SCALE,0) cDATA_SCALE,
    nvl(b.DATA_SCALE,0) aDATA_SCALE
  FROM
    (SELECT column_name,
      data_type,
      data_length,
      DATA_SCALE,
      DATA_PRECISION
    FROM all_tab_columns
    WHERE table_name LIKE upper(currentTable)
    AND owner LIKE upper(schemaName)
    ) a
  INNER JOIN
    (SELECT column_name,
      data_type,
      data_length,
      DATA_SCALE,
      DATA_PRECISION
    FROM all_tab_columns
    WHERE table_name LIKE upper(archivetable)
    AND owner LIKE upper(archiveSchemaName)
    ) b
  ON a.column_name   = b.column_name
  WHERE a.data_type <> b.data_type
  OR a.data_length  <> b.data_length
  or nvl(a.DATA_PRECISION,0)  <> nvl(b.DATA_PRECISION,0)
  or nvl(a.DATA_SCALE,0)  <> nvl(b.DATA_SCALE,0)
  )
  LOOP
    IF (rec.atype = rec.ctype)THEN--если типы полей совпадают, но отличается длина
		case 
			when rec.ctype in ('NUMBER') and (rec.cDATA_PRECISION > 0 )  then  
				ex_query:=' ALTER TABLE ' || archiveSchemaName || '.' ||upper(archiveTable) || ' MODIFY("' || rec.column_name || '" ' || rec.ctype ||'(' || rec.cDATA_PRECISION ||','|| rec.cDATA_SCALE || '))';
				EXECUTE IMMEDIATE ex_query;		
		when rec.ctype in ('DATE','DATETIME','TIMESTAMP','NUMBER') and (rec.cDATA_PRECISION = 0 )  then
				ex_query:= ' ALTER TABLE ' || archiveSchemaName || '.' ||upper(archiveTable) || ' MODIFY("' || rec.column_name || '" ' || rec.ctype ||  '))';
				EXECUTE IMMEDIATE ex_query;
		when rec.ctype in ('VARCHAR2','CHAR','NCHAR','VARCHAR')	then
				ex_query:= ' ALTER TABLE ' || archiveSchemaName || '.' ||upper(archiveTable) || ' MODIFY("' || rec.column_name || '" ' || rec.ctype || '(' || rec.cdata_length || '))';
				EXECUTE IMMEDIATE ex_query;
		else 
		 	r_query := 'no';
			DBMS_OUTPUT.PUT_LINE('not supported type ');
    end case;
    ELSE--если типы полей не совпадают
      --добавляем новый столбец, в который переносим значения
    
      drop_column   := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' DROP COLUMN ' || rec.column_name || '';
      rename_column := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' RENAME COLUMN ' || rec.column_name || '_TMP TO ' || rec.column_name || '';
    
    CASE 
      WHEN upper(rec.ctype) in ( 'VARCHAR2','VARCHAR' ,'CHAR', 'NCHAR') THEN
	    add_column    := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' ADD( "' || rec.column_name || '_TMP" ' || rec.ctype || '(' || rec.cdata_length || '))';
        update_column := ' UPDATE ' || archiveSchemaName || '.' || archiveTable || ' SET "' || rec.column_name || '_TMP" = TO_CHAR("' || rec.column_name || '")';
        execute immediate add_column;   
        execute immediate update_column;
        commit;
        execute immediate  drop_column;
        execute immediate  rename_column;
         r_query := 'yes'; 
	  WHEN upper(rec.ctype) = 'NUMBER' and (rec.cDATA_PRECISION = 0 ) THEN
	    add_column    := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' ADD( "' || rec.column_name || '_TMP" ' || rec.ctype || ')';
        update_column := ' UPDATE ' || archiveSchemaName || '.' || archiveTable || ' SET "' || rec.column_name || '_TMP" = TO_NUMBER("' || rec.column_name || '")';
        execute immediate add_column;
        execute immediate update_column;
        commit;
        execute immediate  drop_column;
        execute immediate  rename_column;
         r_query := 'yes'; 
	  WHEN upper(rec.ctype) = 'NUMBER' and (rec.cDATA_PRECISION > 0 ) THEN
	    add_column    := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' ADD( "' || rec.column_name || '_TMP" ' || rec.ctype || '(' || rec.cDATA_PRECISION ||','|| rec.cDATA_SCALE || '))';
        update_column := ' UPDATE ' || archiveSchemaName || '.' || archiveTable || ' SET "' || rec.column_name || '_TMP" = TO_NUMBER("' || rec.column_name || '")';
        execute immediate add_column;
        execute immediate update_column;
        commit;
        execute immediate  drop_column;
        execute immediate  rename_column;
         r_query := 'yes'; 	 
      WHEN upper(rec.ctype) like '%DATE%' THEN
        update_column := ' UPDATE ' || archiveSchemaName || '.' || archiveTable || ' SET "' || rec.column_name || '_TMP" = TO_DATE("' || rec.column_name || '")';
        execute immediate add_column;
        execute immediate update_column;
        commit;
        execute immediate  drop_column;
        execute immediate  rename_column;    
        r_query := 'yes'; 
      ELSE
         r_query := 'no'; 
      END CASE;         
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('attribute types in table '||currenttable||' is OK');
  return r_query;  
exception 
  when others then
  r_query := 'no';
  DBMS_OUTPUT.PUT_LINE('proble with types in table '||currentTable);
RETURN r_query;
END;
/

exit;
