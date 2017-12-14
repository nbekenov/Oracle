create or replace procedure  cdm.rtdm_tab_archivation(
v_table_name in varchar2,
v_der_table in  varchar2,
v_key_field in varchar2,
Compress_period number
)
is
v_sql varchar2(3000);
current_run_id number;
table_name varchar2(30);
der_table varchar2(30);
key_field varchar2(30);
current_records2 number;
archived_records2 number;
LAST_ACTUAL_RECORD_DATE2 timestamp;
sql_text varchar2(3000);  
  
  procedure DROP_TMP_IF_EXIST (table_name2 IN varchar2) 
    as 
    begin
      DBMS_OUTPUT.put_line('>>> DROP_IF_EXIST: TABLE_NAME = ' || table_name2||'_TMP' );
      EXECUTE IMMEDIATE 'DROP TABLE ' || table_name2 || '_TMP purge' ;
    EXCEPTION
      WHEN OTHERS THEN NULL;
  END DROP_TMP_IF_EXIST; 
  
  procedure LOGING (sql_text IN varchar2) 
    as 
    begin
      DBMS_OUTPUT.put_line('>>> LOG:  ' || sql_text);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END LOGING;
    
  procedure  arch_rtdm_tables (table_name2 IN varchar2,der_table2 IN varchar2,key_field2 IN varchar2 ) 
    is
    begin
    -- логируем сколько записей будет добавлено в архив
      execute immediate 'select count(*) from cdm.' ||table_name2|| '_tmp' into archived_records2;
        update monitoring.rtdm_arch_history 
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = table_name2;
            commit;     
      execute immediate 'select count(*) from cdm.' ||der_table2|| '_tmp' into archived_records2;
        update monitoring.rtdm_arch_history 
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = der_table2;
            commit;   
      -- переносим данные из временной таблицы в архивную
       begin
          sql_text:='insert /*+ append */ into cdm.'|| table_name2 ||'_ARCH
                    select * from cdm.'|| table_name2 ||'_tmp';
          execute immediate sql_text; 
        -- архивируем зависиимую таблицу
          sql_text :='insert /*+ append*/ into cdm.'||der_table2||'_ARCH
                    select * from cdm.'||der_table2||'_tmp';    
          execute immediate sql_text;            
        commit;
        update monitoring.rtdm_arch_history 
            set archive_status = 'OK'
            where run_id = current_run_id and (table_name = table_name2 or table_name=der_table2);
            commit;
        -- если словили ошибку, то делаем откат и логируем ошибку, что архивировать записи не удалось    
        exception
            when others then
            LOGING('>>>error: '||SQLERRM); 
            rollback;
            update monitoring.rtdm_arch_history 
              set archive_status = 'ERROR'
              where run_id = current_run_id and (table_name = table_name2 or table_name=der_table2);
            commit;    
            return;
       end;
      -- удаление заархивированных записей
       begin
        --удалям старые записи из зависимой таблицы
        execute immediate 'delete from cdm.'||der_table2||' where  ( '||key_field2|| ') in (select ' || key_field2 ||' from cdm.'||table_name2 ||'_tmp )';
        --удаляем старые записи из основной таблицы
		if ( table_name2='RTDM_CLIENT_APPLICATION' ) then
				execute immediate 'delete from cdm.'||table_name2||' where REQUEST_DTTM in ( select REQUEST_DTTM from cdm.'|| table_name2 ||'_tmp )';   
			else 
				execute immediate 'delete from cdm.'||table_name2||' where RTM_REQUEST_ID in ( select RTM_REQUEST_ID from cdm.'|| table_name2 ||'_tmp )';  
			end if;	
        commit;        
         execute immediate 'drop table cdm.' || table_name2 ||'_tmp'; 
         execute immediate 'drop table cdm.' || der_table2 ||'_tmp';          
         update monitoring.rtdm_arch_history 
                set delete_status = 'OK'
                where run_id = current_run_id and (table_name = table_name2 or table_name=der_table2);
                commit;
         exception
            when others then
            LOGING('>>>error: '||SQLERRM); 
            rollback;
            update monitoring.rtdm_arch_history 
              set delete_status = 'ERROR'
              where run_id = current_run_id and (table_name = table_name2 or table_name=der_table2);
            commit;    
            return;     
       end;
       -- логируем сколько записей осталось после архивации
       execute immediate 'select count(*) from cdm.' ||table_name2|| '' into current_records2;
            update monitoring.rtdm_arch_history
            set current_records = current_records2
            where run_id = current_run_id and table_name = table_name2;
            commit;
       execute immediate 'select count(*) from cdm.' ||der_table2|| '' into current_records2;
            update monitoring.rtdm_arch_history
            set current_records = current_records2
            where run_id = current_run_id and table_name = der_table2;
            commit;
       -- логируем Дату самой старой актуальной записи в архивируемой таблице
       execute immediate 'select min(request_dttm) from cdm.' ||table_name2|| '' into LAST_ACTUAL_RECORD_DATE2;
            update monitoring.rtdm_arch_history
            set LAST_ACTUAL_RECORD_DATE = LAST_ACTUAL_RECORD_DATE2
            where run_id = current_run_id and table_name = table_name2;
            commit;
            update monitoring.rtdm_arch_history
            set LAST_ACTUAL_RECORD_DATE = LAST_ACTUAL_RECORD_DATE2
            where run_id = current_run_id and table_name = der_table2;
            commit;
       
       --сбор статистики
        begin
                dbms_stats.gather_table_stats('CDM',table_name2,estimate_percent=>10);   
                dbms_stats.gather_table_stats('CDM',der_table2,estimate_percent=>10); 
                update monitoring.rtdm_arch_history
                set statistics_status = 'OK'
                where run_id = current_run_id and( table_name = table_name2 or table_name=der_table2);
                commit;                
            exception
                when others THEN
                LOGING('>>>error: '||SQLERRM); 
                rollback;
                update  monitoring.rtdm_arch_history
                set statistics_status = 'ERROR'
                where run_id = current_run_id and ( table_name = table_name2 or table_name=der_table2);
                commit;
                return;
            end;  
       --логирование окончания архивации
       update monitoring.rtdm_arch_history
        set finish_dttm = sysdate
        where run_id = current_run_id and (table_name = table_name2 or table_name=der_table2);
        commit;
       
    end arch_rtdm_tables;

begin
  select nvl(max(run_id),0) + 1 into current_run_id from monitoring.rtdm_arch_history ;

  table_name:= v_table_name;
  der_table:=v_der_table;
  key_field:=v_key_field;
  
  insert into monitoring.rtdm_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit;
    insert into monitoring.rtdm_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, der_table, sysdate);
  commit;
   
      --создаем временную таблицу для основной таблицы
     DROP_TMP_IF_EXIST (  table_name2 => 'cdm.' || table_name);
     DROP_TMP_IF_EXIST (  table_name2 => 'cdm.' || der_table);  
    if  ( table_name='RTDM_CLIENT_APPLICATION' ) then
      v_sql :=  'create table cdm.RTDM_CLIENT_APPLICATION_TMP
              as  select 
                            APPLICATION_ID
                            ,CLIENT_CD
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
                            ,CAMPAIGN_CD
							,INTERACTION_ID
                            ,REQUEST_ID
          from CDM.RTDM_CLIENT_APPLICATION
            where trunc(REQUEST_DTTM)  < trunc(sysdate )-'||Compress_period; 
      execute immediate v_sql; 
        --создаем временную таблицу для зависимой таблицы
      v_sql :='create table cdm.RTDM_CLIENT_ALTERNATIVES_TMP
              as select * from cdm.RTDM_CLIENT_ALTERNATIVES
              where application_id in (select application_id from cdm.RTDM_CLIENT_APPLICATION_TMP) ';
      execute immediate v_sql; 
      ---------- Else Case для таблиц RTM_REQUEST_LOG и RTM_REQUEST_LOG_EXT
      Else 
      v_sql :=   'create table cdm.RTM_REQUEST_LOG_TMP
            as select
            RTM_REQUEST_ID,  
			SOURCE_EVENT_ID,             
			ESB_INTEGRATION_ID,            
			CLIENT_ID,
			REQUEST_MESSAGE,			
			REQUEST_DTTM,                   
			OPER_TYPE,                   
			RESPONSE_DTTM,                  
			ERROR_MESSAGE,  
			RESPONSE_MESSAGE,			
			PROCESSING_TIME,             
			ERROR_CODE,                  
			ERROR_TEXT,                  
			REQUEST_ID,                  
			REPLY_TO_QUEUE,              
			PROCESS_HOST
			from CDM.RTM_REQUEST_LOG
			where trunc(REQUEST_DTTM)  < trunc(sysdate )-'||Compress_period; 
		execute immediate v_sql;
			--создаем временную таблицу для зависимой таблицы
			v_sql := 'create table cdm.RTM_REQUEST_LOG_EXT_TMP
			as select 
			CHANNEL_CODE                    
			,RTM_REQUEST_ID                        
			,RTM_CAMPAIGN                   
			,RTM_REPLY     
			,CHANNEL_REQUEST_MESSAGE	
			,CHANNEL_RESPONSE_MESSAGE			
			,CHANNEL_START_DTTM              
			,CHANNEL_END_DTTM                
			,CHANNEL_ERROR_MESSAGE           
			,PROCESS_HOST
			from cdm.RTM_REQUEST_LOG_EXT
			where RTM_REQUEST_ID in (select RTM_REQUEST_ID from cdm.RTM_REQUEST_LOG_TMP)';
		execute immediate v_sql; 
    end if;   
   arch_rtdm_tables(table_name,der_table,key_field); 
    
end rtdm_tab_archivation;
/
grant EXECUTE,debug on CDM.rtdm_tab_archivation to MA_USER;