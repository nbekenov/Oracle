			execute(
			/* PRODUCT_X_CELL - выделено в отдельный анонимный блок*/
				declare
					/*Курсор для получения по идентификатору волны пар (идентификатор ячейки, список продуктов из тритмента*/
					cursor c_get_products_lists(p_wave_id integer) is
						select 
							cc.cell_id
							,cpsk.products_uk_list
						from  MA_USER.TMP_CAMPAIGN_CELL_74856_238490  cc
							inner join MA_USER.MTRZ_NORMAL_28762_9201_cpsk cpsk on 
								cpsk.cell_package_sk = cc.cell_package_sk
						where cc.WAVE_ID = p_wave_id;
					l_count integer;
					/*Текущий продукт*/
					l_cur_product varchar2(32 char);
					/*Выражения для вставки записей в MA_PRODUCT_X_CELL*/
					l_insert_stmt varchar2(100 char);
				begin
					/*Инициализация выражения для вставки*/
					l_insert_stmt := 'insert into MA_USER.TMP_PROD_X_CELL_74856_238490 (CELL_ID, PRODUCT_UK) values (:bCell, :bProduct)';
				  
					/*Для всех записей в курсоре цикл*/
					for x in c_get_products_lists(238490) loop
					
						/*Инициализация цикла*/
						l_count := 1;
						l_cur_product := regexp_substr(x.products_uk_list, ' [^' || chr(9) || ']   +', 1, l_count);
						
						/*Цикл по всем словам разделенным табуляцией*/
						while l_cur_product is not null
						loop
							/*Вставка*/
							execute immediate l_insert_stmt using x.cell_id, to_number(l_cur_product,'9999.9');
							/*Переход к следующей итерации цикла*/
							l_count := l_count + 1;
							l_cur_product := regexp_substr(x.products_uk_list, '[^' || chr(9) || ']+', 1, l_count);
						end loop;				
					end loop; 
				end; 
			) by ora;