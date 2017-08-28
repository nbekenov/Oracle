SET serveroutput ON;
DECLARE
    current_run_id number;
    table_name varchar2(30);
    arch_period number :=14;
    current_records2 number;
    archived_records2 number;
    is_ok varchar2(3);
    sql_text varchar2(1000);
    type varray_varchar is varying array(20) of varchar2(60);
    refin_tables_arr varray_varchar;
    
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
    
    procedure  arch_rto_tables (table_name2 IN varchar2, arch_period2 IN number) 
    is
    begin 
      if is_ok = 'yes' then
      -- логируем сколько записей будет добавлено в архив
            execute immediate 'select count(*) from ma_temp.' ||table_name2|| '_tmp' into archived_records2;
            
            update ma_temp.rto_arch_history
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = table_name2;
            commit;
        -- переносим данные из временной таблицы в архивную
        begin
          sql_text:='insert /*+ append */ into ma_temp.ARC_'|| table_name2 ||
                          ' select * from ma_temp.'|| table_name2 ||'_tmp';
                          
          execute immediate sql_text;  
          commit; 
          update ma_temp.rto_arch_history
                set archive_status = 'OK'
                where run_id = current_run_id and table_name = table_name2;
                commit;
          exception -- если словили ошибку, то делаем откат и логируем ошибку, что архивировать записи не удалось
                when others THEN
                rollback;
                update ma_temp.rto_arch_history
                set archive_status = 'ERROR'
                where run_id = current_run_id and table_name = table_name2;
                commit;
                is_ok := 'no';
                return;
        end;
        -- удаление заархивированных записей
        begin   
        if table_name2='RET_SCORE_MODEL_RESULTS' then
            execute immediate 'delete from MA_TEMP.RET_SCORE_MODEL_RESULTS w 
              where (EVENT_ID,EID) in (select  EVENT_ID,EID from MA_TEMP.RET_SCORE_MODEL_RESULTS_TMP)';
            commit;   
          else
            if table_name2='NBO_OFFERS' then
              execute immediate 'delete from ma_temp.NBO_OFFERS where CREATE_DATE <= sysdate-'||arch_period2||'';
              commit;   
            end if; 
          end if;          
          execute immediate 'drop table MA_TEMP.'||table_name2||'_tmp';         
          update ma_temp.rto_arch_history
                set delete_status = 'OK'
                where run_id = current_run_id and table_name = table_name2;
                commit;       
          exception -- если словили ошибку, то делаем откат и логируем что удалить записи не удалось
            when others then
            rollback;
            update ma_temp.rto_arch_history
                set delete_status = 'ERROR'
                where run_id = current_run_id and table_name = table_name2;
                commit;
                is_ok := 'no';
                return;      
        end;  
      -- логируем сколько записей осталось после архивации
        execute immediate 'select count(*) from ma_temp.' ||table_name2|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = table_name2;
            commit;
      end if; 
      -- если архивация прошла успешно, то логируем время завершения
      update ma_temp.rto_arch_history
        set finish_dttm = sysdate
        where run_id = current_run_id and table_name = table_name2;
      commit;
    end arch_rto_tables;
    
    procedure arch_refin_tables(tmp_table_name IN varchar2)
    is
--    type varray_varchar is varying array(20) of varchar2(60);
--    refin_tables_arr varray_varchar;
    begin
      refin_tables_arr  := varray_varchar('ESP_REFINANCE2','REFINANCE_LOG_DECISION_F8', 'PRED_RECALC_OFFER', 'PRED_RECALC_VARIANT'
                                        ,'PRED_RECALC_KN_RES','PRED_RECALC_KN_SUMS1','PRED_RECALC_CC_RES'
                                        ,'PRED_RECALC_SCORE_RES','REF_ERRONEOUS_DATA');
                                        
      for tab in 1..refin_tables_arr.count 
      loop                                     
        insert into ma_temp.rto_arch_history  (run_id,table_name,start_dttm)
          values (current_run_id, refin_tables_arr(tab), sysdate);
      end loop;
      commit; 
      -- цикл создания  tmp таблиц
      for tab in 1..refin_tables_arr.count 
      loop
       DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || refin_tables_arr(tab));
        sql_text:='create table MA_TEMP.'||refin_tables_arr(tab)||'_TMP 
                    as select esp_rf.* 
                    from '||  CASE WHEN refin_tables_arr(tab) in ('ESP_REFINANCE2' )
                              then 'ODM.'
                              else 'MA_TEMP.' 
                              end 
                          || refin_tables_arr(tab)||' esp_rf
                  where esp_rf.event_id in ( select  inp_rf.event_id from  ma_temp.'||tmp_table_name||'_tmp inp_rf )';
         LOGING(sql_text);      
        execute immediate sql_text;   
      end loop; 
      -- цикл запись в отчет
      for tab in 1..refin_tables_arr.count 
      loop
        execute immediate 'select count(*) from MA_TEMP.' ||refin_tables_arr(tab)||'_tmp' into archived_records2;
        update ma_temp.rto_arch_history 
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = refin_tables_arr(tab);
      end loop;
      execute immediate 'select count(*) from MA_TEMP.' ||tmp_table_name||'_tmp' into archived_records2;
        update ma_temp.rto_arch_history 
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = tmp_table_name;
      commit;  
      begin
       -- цикл инсерта в архивные таблицы
        for tab in 1..refin_tables_arr.count loop 
          sql_text:='insert /*+ append */ into MA_TEMP.ARC_'||refin_tables_arr(tab)||
                    ' select * from MA_TEMP.'||refin_tables_arr(tab)||'_TMP';
                    LOGING(sql_text);   
          execute immediate sql_text;       
        end loop; 
        execute immediate 'insert /*+ append */ into MA_TEMP.ARC_'||tmp_table_name||
                    ' select * from MA_TEMP.'||tmp_table_name||'_TMP';
        commit;
        for tab in 1..refin_tables_arr.count loop 
            update ma_temp.rto_arch_history
                set archive_status = 'OK'
                where run_id = current_run_id and table_name = refin_tables_arr(tab);
			end loop;
		update ma_temp.rto_arch_history
                set archive_status = 'OK'
                where run_id = current_run_id and table_name = tmp_table_name;		  
        commit;
		
        exception
          when others then
          rollback; 
          for tab in 1..refin_tables_arr.count loop 
            update ma_temp.rto_arch_history
                set archive_status = 'ERROR'
                where run_id = current_run_id and  table_name = refin_tables_arr(tab);
          end loop;
			update ma_temp.rto_arch_history
                set archive_status = 'ERROR'
                where run_id = current_run_id and table_name = tmp_table_name;	
          commit;
          is_ok := 'no';  
          return;       
      end;
      -- удаление заархивированных записей
      begin
        for tab in 1..refin_tables_arr.count loop 
          sql_text:= 'delete from '||CASE WHEN refin_tables_arr(tab) in ('ESP_REFINANCE2' )
                                                then 'ODM.'
                                                  else 'MA_TEMP.' 
                                                end  || refin_tables_arr(tab) 
                      ||' where event_id in ( select event_id from ma_temp.'||refin_tables_arr(tab)||'_tmp )';
        execute immediate  sql_text;           
        end loop;
        execute immediate 'delete from MA_TEMP.REFINANCE_INPUT w 
              where EVENT_ID in (select  EVENT_ID from MA_TEMP.REFINANCE_INPUT_TMP)';
        commit;
        execute immediate 'drop table MA_TEMP.'||tmp_table_name||'_tmp';
        for tab in 1..refin_tables_arr.count loop
          execute immediate 'drop table MA_TEMP.'||refin_tables_arr(tab)||'_tmp';
			update ma_temp.rto_arch_history
                set delete_status = 'OK'
                where run_id = current_run_id and table_name = refin_tables_arr(tab) ;                 
        end loop;
			update ma_temp.rto_arch_history
                set delete_status = 'OK'
                where run_id = current_run_id and table_name = tmp_table_name;
        commit;
        
        exception 
          when others then
          rollback;
          for tab in 1..refin_tables_arr.count loop
            update ma_temp.rto_arch_history
              set delete_status = 'ERROR'
              where run_id = current_run_id and table_name = refin_tables_arr(tab);
          end loop;  
			update ma_temp.rto_arch_history
                set delete_status = 'ERROR'
                where run_id = current_run_id and table_name = tmp_table_name;		  
          commit;
          is_ok := 'no';
          return;  
      end;              
      -- логируем сколько записей осталось после архивации
      for tab in 1..refin_tables_arr.count loop
        execute immediate 'select count(*) from '||
                           case WHEN refin_tables_arr(tab) in ('ESP_REFINANCE2' )
                              then 'ODM.'
                              else 'MA_TEMP.' 
                              end  ||refin_tables_arr(tab)|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = refin_tables_arr(tab);
      end loop;
      commit;	  
      for tab in 1..refin_tables_arr.count loop
          update ma_temp.rto_arch_history
          set finish_dttm = sysdate
           where run_id = current_run_id and table_name = refin_tables_arr(tab);
      end loop;   
      commit;  
	-- логируем сколько записей осталось после архивации
        execute immediate 'select count(*) from ma_temp.' ||tmp_table_name|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = tmp_table_name;
            commit;
      -- если архивация прошла успешно, то логируем время завершения
      update ma_temp.rto_arch_history
        set finish_dttm = sysdate
        where run_id = current_run_id and table_name = tmp_table_name;
      commit;	  
    end arch_refin_tables; 
begin
  select nvl(max(run_id),0) + 1 into current_run_id from ma_temp.rto_arch_history;
    is_ok := 'yes';
  
  -- RTDM_CDM.NBO_OFFERS
  table_name := 'NBO_OFFERS';

  insert into ma_temp.rto_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit;
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
  if is_ok='yes' then
    execute immediate 
    'create table MA_TEMP.NBO_OFFERS_TMP
        as select * from ma_temp.NBO_OFFERS
          where CREATE_DATE <= sysdate-'||arch_period;
  end if; 
  arch_rto_tables(table_name,arch_period);
  
  --RTDM_CDM.RET_SCORE_MODEL_RESULTS
  table_name:='RET_SCORE_MODEL_RESULTS';  
  insert into ma_temp.rto_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit; 
  is_ok:='yes';
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
  if is_ok='yes' then
  sql_text:= 'create table ma_temp.RET_SCORE_MODEL_RESULTS_tmp 
                as
                select sc.*  from ma_temp.RET_SCORE_MODEL_RESULTS sc
                  left join  
                  (
                    select  EVENT_ID, EID, CREATE_DATE from ODM.ESP_CREDCARD
                          where CREATE_DATE < sysdate-'||arch_period||'
                    union all
                    select  EVENT_ID, EID, CREATE_DATE from ODM.ESP_CREDIT
                          where CREATE_DATE < sysdate-'||arch_period||'
                    union all
                    select EVENT_ID, EID, CREATE_DATE  from ODM.ESP_DEPOSIT
                          where CREATE_DATE < sysdate-'||arch_period||'
                  ) esp
                  on esp.EVENT_ID=sc.EVENT_ID and esp.EID=sc.EID';
  execute immediate sql_text;                  
  end if;
  arch_rto_tables(table_name,null);  
  
  --INFOMAP.REFINANCE_INPUT
  table_name:='REFINANCE_INPUT';
    insert into ma_temp.rto_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit; 
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  --проверка соответствия типов полей архивной и архиивруемой таблицы 
  DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
  if is_ok='yes' then
    execute immediate 
    'create table ma_temp.REFINANCE_INPUT_TMP as
      select * from INFOMAP.REFINANCE_INPUT
        where EVENT_DTTM < sysdate-14';     
  end if;
  arch_refin_tables(table_name);
end;
--by nb
  

  