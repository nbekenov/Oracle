CREATE OR REPLACE FUNCTION ma_temp.CHECKTYPES--процедура синхронизирует типы атрибутовцелевой и архивируемой таблицы
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
    a.column_name column_name
  FROM
    (SELECT column_name,
      data_type,
      data_length
    FROM all_tab_columns
    WHERE table_name LIKE upper(currentTable)
    AND owner LIKE upper(schemaName)
    ) a
  INNER JOIN
    (SELECT column_name,
      data_type,
      data_length
    FROM all_tab_columns
    WHERE table_name LIKE upper(archivetable)
    AND owner LIKE upper(archiveSchemaName)
    ) b
  ON a.column_name   = b.column_name
  WHERE a.data_type <> b.data_type
  OR a.data_length  <> b.data_length
  )
  LOOP
    IF (rec.atype          = rec.ctype)THEN--если типы полей совпадают, но отличается длина
      IF (rec.cdata_length > rec.adata_length)THEN
        ex_query           := ' ALTER TABLE ' || archiveSchemaName || '.' ||upper(archiveTable) || ' MODIFY("' || rec.column_name || '" ' || rec.ctype || '(' || rec.cdata_length || '))';
        EXECUTE IMMEDIATE ex_query;
      END IF;
    ELSE--если типы полей не совпадают
      --добавляем новый столбец, в который переносим значения
      add_column    := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' ADD( "' || rec.column_name || '_TMP" ' || rec.ctype || '(' || rec.cdata_length || '))';
      drop_column   := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' DROP COLUMN ' || rec.column_name || '';
      rename_column := ' ALTER TABLE ' || archiveSchemaName || '.' || archiveTable || ' RENAME COLUMN ' || rec.column_name || '_TMP TO ' || rec.column_name || '';
    
    CASE 
      WHEN upper(rec.ctype) in ( 'VARCHAR2','VARCHAR' ,'CHAR', 'NCHAR') THEN
        update_column := ' UPDATE ' || archiveSchemaName || '.' || archiveTable || ' SET "' || rec.column_name || '_TMP" = TO_CHAR("' || rec.column_name || '")';
        execute immediate add_column;   
        execute immediate update_column;
        commit;
        execute immediate  drop_column;
        execute immediate  rename_column;
         r_query := 'yes'; 
	  WHEN upper(rec.ctype) = 'NUMBER' THEN
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