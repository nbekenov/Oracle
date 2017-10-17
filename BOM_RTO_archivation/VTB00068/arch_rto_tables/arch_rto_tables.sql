-- created by n.bekenov 09/2017
-- patch VTB00068 
-- issue BOMEXT-1037
SET serveroutput ON;
DECLARE
    current_run_id number;
    table_name varchar2(30);
    arch_period number :=14;
    current_records2 number;
    archived_records2 number;
    is_ok varchar2(3);
    sql_text varchar2(3000);
    type varray_varchar is varying array(20) of varchar2(60);
    refin_tables_arr varray_varchar;
    problem_with_attr EXCEPTION;
    problem_with_types EXCEPTION;
    schem varchar2(9);
    problem_tab VARCHAR2(30);
	
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
	  columnlist varchar2(3000);
    begin 
      if is_ok = 'yes' then
      -- логируем сколько записей будет добавлено в архив
            execute immediate 'select count(*) from ma_temp.' ||table_name2|| '_tmp' into archived_records2;
            
            update ma_temp.rto_arch_history
            set archived_records = archived_records2
            where run_id = current_run_id and table_name = table_name2;
            commit;
        -- переносим данные из временной таблицы в архивную
      SELECT listagg(COLUMN_NAME,',') WITHIN GROUP (ORDER BY COLUMN_NAME) cols into columnlist
             FROM ALL_TAB_COLumns WHERE OWNER = 'RTDM_CDM' AND TABLE_NAME = table_name2 group by TABLE_NAME  ;
		
        begin
          sql_text:='insert /*+ append */ into ma_temp.ARC_'|| table_name2 ||'( ' || columnlist ||
                          ') select '|| columnlist ||' from ma_temp.'|| table_name2 ||'_tmp';
          LOGING(sql_text);               
          execute immediate sql_text;  
          commit; 
          update ma_temp.rto_arch_history
                set archive_status = 'OK'
                where run_id = current_run_id and table_name = table_name2;
                commit;
          exception -- если словили ошибку, то делаем откат и логируем ошибку, что архивировать записи не удалось
                when others THEN
				LOGING('>>>error: '||SQLERRM); 
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
            execute immediate 'delete from RTDM_CDM.RET_SCORE_MODEL_RESULTS w 
              where (EVENT_ID,EID) in (select  EVENT_ID,EID from MA_TEMP.RET_SCORE_MODEL_RESULTS_TMP)';
            commit;   
          else
            if table_name2='NBO_OFFERS' then
              execute immediate 'delete from RTDM_CDM.NBO_OFFERS where CREATE_DATE <= sysdate-'||arch_period2||'';
              commit;   
            end if; 
          end if;          
          execute immediate 'drop table MA_TEMP.'||table_name2||'_tmp purge';         
          update ma_temp.rto_arch_history
                set delete_status = 'OK'
                where run_id = current_run_id and table_name = table_name2;
                commit;       
          exception -- если словили ошибку, то делаем откат и логируем что удалить записи не удалось
            when others then
			LOGING('>>>error: '||SQLERRM); 
            rollback;
            update ma_temp.rto_arch_history
                set delete_status = 'ERROR'
                where run_id = current_run_id and table_name = table_name2;
                commit;
                is_ok := 'no';
                return;      
        end;  
      -- логируем сколько записей осталось после архивации
        execute immediate 'select count(*) from RTDM_CDM.' ||table_name2|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = table_name2;
            commit;
            
          begin
                dbms_stats.gather_table_stats('RTDM_CDM',table_name2,estimate_percent=>10);
                
                update ma_temp.rto_arch_history
                set statistics_status = 'OK'
                where run_id = current_run_id and table_name = table_name2;
                commit;
            exception
                when others THEN
                rollback;
                update  ma_temp.rto_arch_history
                set statistics_status = 'ERROR'
                where run_id = current_run_id and table_name = table_name2;
                commit;
                is_ok := 'no';
                return;
            end;       
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
    col_text varchar2(10000);
    columnlist varchar2(10000);
    begin
    if is_ok = 'yes' then
      refin_tables_arr  := varray_varchar('ESP_REFINANCE','REFINANCE_LOG_DECISION_F8', 'PRED_RECALC_OFFER', 'PRED_RECALC_VARIANT'
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
                    from '||  CASE WHEN refin_tables_arr(tab) in ('ESP_REFINANCE' )
                              then 'ODM.'
                              else 'INFOMAP.' 
                              end 
                          || refin_tables_arr(tab)||' esp_rf
                  where esp_rf.event_id in ( select  inp_rf.event_id from  ma_temp.'||tmp_table_name||'_tmp inp_rf )';    
        LOGING('>>> create tmp tables: '||sql_text); 
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
                    ' select *  from MA_TEMP.'||refin_tables_arr(tab)||'_TMP';
          LOGING('>>>insert into archive tables: '||sql_text); 					
          execute immediate sql_text;       
        end loop; 	
        sql_text:= 'insert /*+ append */ into MA_TEMP.ARC_'||tmp_table_name||
                    ' select * from MA_TEMP.'||tmp_table_name||'_TMP';
		  LOGING('>>>insert into archive tables: ' ||sql_text); 					
        execute immediate sql_text;			
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
		  LOGING('>>>error: '||SQLERRM); 
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
          sql_text:= 'delete from '||CASE WHEN refin_tables_arr(tab) in ('ESP_REFINANCE' )
                                                then 'ODM.'
                                                  else 'INFOMAP.' 
                                                end  || refin_tables_arr(tab) 
                      ||' where event_id in ( select event_id from ma_temp.'||refin_tables_arr(tab)||'_tmp )';
        execute immediate  sql_text;           
        end loop;
        execute immediate 'delete from INFOMAP.REFINANCE_INPUT w 
              where EVENT_ID in (select  EVENT_ID from MA_TEMP.REFINANCE_INPUT_TMP)';
        commit;
        execute immediate 'drop table MA_TEMP.'||tmp_table_name||'_tmp purge';
        for tab in 1..refin_tables_arr.count loop
          execute immediate 'drop table MA_TEMP.'||refin_tables_arr(tab)||'_tmp purge';
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
		  LOGING('>>>error: '||SQLERRM); 
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
                           case WHEN refin_tables_arr(tab) in ('ESP_REFINANCE' )
                              then 'ODM.'
                              else 'INFOMAP.' 
                              end  ||refin_tables_arr(tab)|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = refin_tables_arr(tab);
      end loop;
      commit;	  
      -- логируем завершение
      for tab in 1..refin_tables_arr.count loop
          update ma_temp.rto_arch_history
          set finish_dttm = sysdate
           where run_id = current_run_id and table_name = refin_tables_arr(tab);
      end loop;   
      commit;  
	-- логируем сколько записей осталось после архивации
        execute immediate 'select count(*) from INFOMAP.' ||tmp_table_name|| '' into current_records2;
            update ma_temp.rto_arch_history
              set current_records = current_records2
              where run_id = current_run_id and table_name = tmp_table_name;
            commit;
      -- если архивация прошла успешно, то логируем время завершения
      
               begin
                for tab in 1..refin_tables_arr.count loop
                 schem:= case WHEN refin_tables_arr(tab) in ('ESP_REFINANCE' )
                              then 'ODM'
                              else 'INFOMAP' 
                              end ||''; 
                dbms_stats.gather_table_stats( schem,refin_tables_arr(tab),estimate_percent=>10);              
                update ma_temp.rto_arch_history
                set statistics_status = 'OK'
                where run_id = current_run_id and table_name = refin_tables_arr(tab);
                end loop;
                commit;
                dbms_stats.gather_table_stats( schem,tmp_table_name,estimate_percent=>10); 
                  update ma_temp.rto_arch_history
                  set statistics_status = 'OK'
                  where run_id = current_run_id and table_name = tmp_table_name;
                  commit;
                
                
            exception
                when others THEN
				LOGING('>>>error: '||SQLERRM); 
                rollback;
                for tab in 1..refin_tables_arr.count loop
                  update  ma_temp.rto_arch_history
                  set statistics_status = 'ERROR'
                where run_id = current_run_id and table_name = refin_tables_arr(tab);
                end loop;
                commit;
				
				update ma_temp.rto_arch_history
                  set statistics_status = 'ERROR'
                  where run_id = current_run_id and table_name = tmp_table_name;
                commit;
				  
                is_ok := 'no';
                
                return;
            end;  
    end if;
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
  is_ok := CHECKTYPES('RTDM_CDM',table_name, 'MA_TEMP','ARC_'||table_name);
  if is_ok='no' then
	LOGING('problem with check attribute types in table '||table_name);
   --проверка соответствия типов полей архивной и архиивруемой таблицы 
	else  is_ok := CHECKATTRIBUTES('RTDM_CDM',table_name, 'MA_TEMP','ARC_'||table_name);
  end if;  
  if is_ok='yes' then
	DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
    execute immediate 
    'create table MA_TEMP.NBO_OFFERS_TMP
        as select * from RTDM_CDM.NBO_OFFERS
          where CREATE_DATE <= sysdate-'||arch_period;   
	arch_rto_tables(table_name,arch_period); 
  else 	LOGING('problem with check attributes in table '||table_name);
  end if; 
   
  --RTDM_CDM.RET_SCORE_MODEL_RESULTS
  table_name:='RET_SCORE_MODEL_RESULTS';  
  insert into ma_temp.rto_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit; 
  is_ok:='yes';
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  is_ok := CHECKTYPES('RTDM_CDM',table_name, 'MA_TEMP','ARC_'||table_name);
  if is_ok='no' then
	LOGING('problem with check attribute types in table '||table_name);
    --проверка соответствия типов полей архивной и архиивруемой таблицы 
  else  is_ok := CHECKATTRIBUTES('RTDM_CDM',table_name, 'MA_TEMP','ARC_'||table_name);
  end if;
 
  if is_ok='yes' then
  DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
  sql_text:= 'create table ma_temp.RET_SCORE_MODEL_RESULTS_tmp 
                as
                select sc.*  from RTDM_CDM.RET_SCORE_MODEL_RESULTS sc
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
  arch_rto_tables(table_name,null);    
  else 	LOGING('problem with check attributes in table '||table_name);
  end if;
  
begin  
  --INFOMAP.REFINANCE_INPUT
  table_name:='REFINANCE_INPUT';
  is_ok:='yes';
    insert into ma_temp.rto_arch_history (run_id,table_name,start_dttm)
        values (current_run_id, table_name, sysdate);
  commit; 
  --проверка соответствия типов полей архивной и архиивруемой таблицы
  is_ok := CHECKTYPES('INFOMAP',table_name, 'MA_TEMP','ARC_'||table_name);
  if is_ok='no' then
	LOGING('problem with check attribute types in table '||table_name);
	raise problem_with_types;
  --проверка соответствия типов полей архивной и архиивруемой таблицы 
  else is_ok := CHECKATTRIBUTES('INFOMAP',table_name, 'MA_TEMP','ARC_'||table_name);
  end if;  
  if is_ok='yes' then
  DROP_TMP_IF_EXIST (  table_name2 => 'MA_TEMP.' || table_name);
    execute immediate 
    'create table ma_temp.REFINANCE_INPUT_TMP as
      select * from INFOMAP.REFINANCE_INPUT
        where EVENT_DTTM < sysdate-'||arch_period;   
else 	LOGING('problem with check attributes in table '||table_name);		
raise problem_with_attr;
  end if;  
  refin_tables_arr  := varray_varchar('ESP_REFINANCE','REFINANCE_LOG_DECISION_F8', 'PRED_RECALC_OFFER', 'PRED_RECALC_VARIANT'
                                        ,'PRED_RECALC_KN_RES','PRED_RECALC_KN_SUMS1','PRED_RECALC_CC_RES'
                                        ,'PRED_RECALC_SCORE_RES','REF_ERRONEOUS_DATA');
   
   for tab in 1..refin_tables_arr.count loop  
    is_ok := CHECKTYPES('INFOMAP',refin_tables_arr(tab), 'MA_TEMP','ARC_'||refin_tables_arr(tab));
      if is_ok='no' then
      problem_tab:=refin_tables_arr(tab);
        raise problem_with_types;
      end if;
	  is_ok := CHECKATTRIBUTES('INFOMAP',refin_tables_arr(tab), 'MA_TEMP','ARC_'||refin_tables_arr(tab));
      if is_ok='no' then 
      problem_tab:=refin_tables_arr(tab);
        raise problem_with_attr;
      end if;
	end loop;
    exception
    when  problem_with_attr then
	LOGING('>>>error: '||SQLERRM); 
    DBMS_OUTPUT.PUT_LINE('>>> proble with attributes in REFIN table '||problem_tab);
    
    when problem_with_types then 
	LOGING('>>>error: '||SQLERRM); 
     DBMS_OUTPUT.PUT_LINE('>>> proble with types in REFIN table ' ||problem_tab);
 end;  
  arch_refin_tables(table_name);
  
end;
/

exit;  