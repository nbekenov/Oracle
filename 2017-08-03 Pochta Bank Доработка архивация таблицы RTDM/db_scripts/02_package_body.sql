whenever sqlerror exit;
ALTER SESSION SET CURRENT_SCHEMA = CDM;

create or replace PACKAGE BODY ARCHIVE_PARTITION AS

  PROCEDURE ARCH_PARTITION (
    TABLE_NAME IN VARCHAR2 
    , NUM_MONTHS IN NUMBER DEFAULT 3 
    , ARCH_SUFFIX IN varchar2 DEFAULT '_HIST' 
    , DER_TABLE IN varchar2 DEFAULT '' 
    , DER_TABLE_KEY IN varchar2 DEFAULT ''
    ) as
      V_SCHEMA varchar2(32);
      V_TABLE_NAME varchar2(200);
      V_ARCH_TABLE varchar2(200);
      V_PART_LIST varchar2(200);
      v_sql varchar2(10000);
  BEGIN
    DBMS_OUTPUT.enable;
    DBMS_OUTPUT.put_line('>>> ARCH_PARTITION: TABLE_NAME = ' || TABLE_NAME || ' NUM_MONTHS = ' || NUM_MONTHS);
    
    IF (INSTR(TABLE_NAME, '.', 1) = 0) THEN 
      RAISE_APPLICATION_ERROR(-20001,'Table must be declarated with schema name!');
    END IF;
    
    V_TABLE_NAME := upper(SUBSTR(TABLE_NAME, INSTR(TABLE_NAME, '.', 1) + 1));
    V_SCHEMA := upper(SUBSTR(TABLE_NAME, 1, INSTR(TABLE_NAME, '.', 1) -1));
    
    V_ARCH_TABLE := upper(V_TABLE_NAME || ARCH_SUFFIX );
    V_PART_LIST  := upper(V_TABLE_NAME || '_PL');
    
    ARCHIVE_PARTITION.DROP_IF_EXIST (  TABLE_NAME => V_SCHEMA || '.' || V_PART_LIST);
    
    -- Табличка с партициями
    v_sql := 
      'create table ' || V_SCHEMA || '.' || V_PART_LIST || ' as 
          select table_name, partition_name, to_lob(high_value) hv 
          from ALL_TAB_PARTITIONS 
          where 
            TABLE_OWNER = ''' || V_SCHEMA || ''' 
            and TABLE_NAME in (''' || V_TABLE_NAME || ''', ''' || V_ARCH_TABLE || ''')
            and PARTITION_POSITION <> 1';
    EXECUTE IMMEDIATE v_sql;
          
    declare 
      TYPE PartCurTyp  IS REF CURSOR;
      v_part_cursor    PartCurTyp;
      TYPE part_record_t is record (	PARTITION_NAME VARCHAR2(128 BYTE), B_PARTITION_NAME VARCHAR2(128 BYTE),	hv VARCHAR2(1000 BYTE), 	IS_CONFLICT NUMBER   );
      part_record part_record_t;
      v_date_end date;
      V_PART_COLUMN varchar2(100);
    BEGIN
        v_sql := 
          'select 
              a.partition_name, 
              b.partition_name B_PARTITION_NAME, 
              cast(a.hv as varchar2(1000)) hv, 
              case when b.table_name IS NULL then 0 else 1 end as is_conflict
            from 
              ' || V_SCHEMA || '.' || V_PART_LIST || ' a
              left join ' || V_SCHEMA || '.' || V_PART_LIST || ' b on 
                cast(a.hv as varchar2(1000)) = cast(b.hv as varchar2(1000))
                and b.table_name = ''' || V_ARCH_TABLE || '''
            where a.table_name = ''' || V_TABLE_NAME || ''''
            ;
        OPEN v_part_cursor FOR v_sql;
        LOOP
          FETCH v_part_cursor INTO part_record;
          EXIT WHEN v_part_cursor%NOTFOUND;
          
          v_sql := 'select ' || part_record.hv || ' from dual';
          execute immediate v_sql into v_date_end;
          
          IF (v_date_end < add_months(CURRENT_DATE, -NUM_MONTHS) ) THEN 
            DBMS_OUTPUT.put_line('Moving data:' || v_date_end);
            DBMS_OUTPUT.put_line('PARTITION_NAME = ' || part_record.PARTITION_NAME || ' hv = ' || part_record.hv || ' IS_CONFLICT = ' || part_record.IS_CONFLICT );
            
            -- Ищем колонку партицирования
                v_sql := 
                    'select column_name from ALL_PART_KEY_COLUMNS 
                      where 
                        owner = ''' || V_SCHEMA || ''' 
                        and name = ''' || V_TABLE_NAME || ''' 
                        and column_position = 1 
                        and object_type = ''TABLE''';
                execute immediate v_sql into V_PART_COLUMN;
                
            -- Такая партиция уже есть в целевой таблице 
            IF (part_record.IS_CONFLICT = 1) THEN 
                DBMS_OUTPUT.put_line('WARNING: Conflict patritions!');
            END IF;     
             
            IF (V_TABLE_NAME='RTDM_CLIENT_APPLICATION') THEN
              -- Копируем данные
              v_sql := 'insert /*+ append*/ into ' || V_SCHEMA || '.' || V_ARCH_TABLE || ' 
                        (APPLICATION_ID
                        ,CLIENT_CD
                        ,INTERACTION_ID
                        ,DECISION_DTTM
                        ,DECISION_ID
                        ,REQUEST_DTTM
                        ,INT_STATUS
                        ,SEGMENT_CD
                        ,RTDM_QUERY_XML_PRODUCT2CODE
                        ,RTDM_QUERY_XML_CHANNEL
                        ,REQUESTED_LIMIT
                        ,REQUESTED_TERM
                        ,RTDM_RESPONSE_XML
                        ,CAMPAIGN_CD
                        ,REQUEST_ID )
                        select 
                            APPLICATION_ID
                            ,CLIENT_CD
                            ,INTERACTION_ID
                            ,DECISION_DTTM
                            ,DECISION_ID
                            ,REQUEST_DTTM
                            ,INT_STATUS
                            ,SEGMENT_CD
                            ,SUBSTR(RTDM_QUERY_XML
                                    ,INSTR(RTDM_QUERY_XML,''<atc:Product2Code>'')+length(''<atc:Product2Code>'')
                                    ,INSTR(RTDM_QUERY_XML,''</atc:Product2Code>'')-INSTR(RTDM_QUERY_XML,''<atc:Product2Code>'') - length(''<atc:Product2Code>'')) as RTDM_QUERY_XML_Product2Code
                            ,SUBSTR(RTDM_QUERY_XML
                                    ,INSTR(RTDM_QUERY_XML,''<atc:Channel>'')+length(''<atc:Channel>'')
                                    ,INSTR(RTDM_QUERY_XML,''</atc:Channel>'')-INSTR(RTDM_QUERY_XML,''<atc:Channel>'') - length(''<atc:Channel>'')) as RTDM_QUERY_XML_CHANNEL  
                            ,REQUESTED_LIMIT
                            ,REQUESTED_TERM
                            ,SUBSTR(RTDM_RESPONSE_XML
                            ,INSTR(RTDM_RESPONSE_XML,''<NS1:PRODUCT_C>'')+length(''<NS1:PRODUCT_C>'')
                            ,INSTR(RTDM_RESPONSE_XML,''</NS1:PRODUCT_C>'')-INSTR(RTDM_RESPONSE_XML,''<NS1:PRODUCT_C>'') - length(''<NS1:PRODUCT_C>'')) as RTDM_RESPONSE_XML 
                            ,CAMPAIGN_CD
                            ,REQUEST_ID
                        from ' || V_SCHEMA || '.' || V_TABLE_NAME || '
                        where ' || V_PART_COLUMN || ' < to_date('''|| to_char(v_date_end, 'YYYYMMDD') || ''', ''YYYYMMDD'' ) 
                          and ' || V_PART_COLUMN || ' >= to_date('''|| to_char(ADD_MONTHS(v_date_end, -1), 'YYYYMMDD') || ''', ''YYYYMMDD'' )' 
                ;
              execute immediate v_sql;
              commit;
            else
              -- Копируем данные
              v_sql := 'insert /*+ append*/ into ' || V_SCHEMA || '.' || V_ARCH_TABLE || ' 
                        select * from ' || V_SCHEMA || '.' || V_TABLE_NAME || '
                        where ' || V_PART_COLUMN || ' < to_date('''|| to_char(v_date_end, 'YYYYMMDD') || ''', ''YYYYMMDD'' ) 
                          and ' || V_PART_COLUMN || ' >= to_date('''|| to_char(ADD_MONTHS(v_date_end, -1), 'YYYYMMDD') || ''', ''YYYYMMDD'' )' 
              ;
              execute immediate v_sql;
              commit;
            end if; 
            -- Копируем данные зависимой таблицы
            IF (DER_TABLE IS NOT NULL and DER_TABLE_KEY IS NOT NULL) THEN 
              DBMS_OUTPUT.put_line('Moving derived data...');
              v_sql := 'insert /*+ append*/ into ' || DER_TABLE || ARCH_SUFFIX || ' 
                        select a.* 
                          from ' || DER_TABLE || ' a
                            INNER JOIN ' || V_SCHEMA || '.' || V_TABLE_NAME || ' b
                              on a.' || DER_TABLE_KEY || ' = b.' || DER_TABLE_KEY || '
                        where b.' || V_PART_COLUMN || ' < to_date('''|| to_char(v_date_end, 'YYYYMMDD') || ''', ''YYYYMMDD'' ) 
                          and b.' || V_PART_COLUMN || ' >= to_date('''|| to_char(ADD_MONTHS(v_date_end, -1), 'YYYYMMDD') || ''', ''YYYYMMDD'' )' 
                ;
              execute immediate v_sql;
              
              v_sql := 'DELETE FROM ' || DER_TABLE || ' where ROWID in (
                        select a.ROWID 
                          from ' || DER_TABLE || ' a
                            INNER JOIN ' || V_SCHEMA || '.' || V_TABLE_NAME || ' b
                              on a.' || DER_TABLE_KEY || ' = b.' || DER_TABLE_KEY || '
                        where b.' || V_PART_COLUMN || ' < to_date('''|| to_char(v_date_end, 'YYYYMMDD') || ''', ''YYYYMMDD'' ) 
                          and b.' || V_PART_COLUMN || ' >= to_date('''|| to_char(ADD_MONTHS(v_date_end, -1), 'YYYYMMDD') || ''', ''YYYYMMDD'' ))' 
                ;
              execute immediate v_sql;
              commit;
            END IF;
            
            -- Удаляем партицию из исходной таблицы        
            v_sql := 'alter table ' || V_SCHEMA || '.' || V_TABLE_NAME || ' drop partition ' || part_record.PARTITION_NAME;
            execute immediate v_sql;
            
          END IF; 
        END LOOP;

        -- Close cursor
        CLOSE v_part_cursor;
        
    END;
    
    --ARCHIVE_PARTITION.DROP_IF_EXIST (  TABLE_NAME => V_SCHEMA || '.' || V_PART_LIST);
    
    DBMS_OUTPUT.put_line('>>> ARCH_PARTITION: END');
  END ARCH_PARTITION;
  
  PROCEDURE DROP_IF_EXIST (
    TABLE_NAME IN VARCHAR2
    ) as 
  BEGIN
    DBMS_OUTPUT.put_line('>>> DROP_IF_EXIST: TABLE_NAME = ' || TABLE_NAME );
    EXECUTE IMMEDIATE 'DROP TABLE ' || TABLE_NAME || ' purge' ;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END DROP_IF_EXIST;

END ARCHIVE_PARTITION;