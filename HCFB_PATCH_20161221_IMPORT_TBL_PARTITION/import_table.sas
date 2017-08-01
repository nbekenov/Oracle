%stpbegin;
%global MA_PROCESS_NAME;
%let MA_PROCESS_NAME = ma_import_table;
%maspinit;

%macro ma_import_table;
    %macro dummy;%mend dummy;
	%include "&MA_WORK_DIR/scripts/common/mMAError.sas";

	%local mvFilExtension;

	%let MA_IMPORT_PATH = &MA_WORK_DIR./export/Import;
	
	/* Проверяем таблицу/входной файл на существование */
	%if ("&import_type" = "SAS") %then %do;
        %if not %sysfunc(exist(maimport.&table_name)) %then %do;
			%let MAMsg = %str(Error during import. Table &table_name not found);
			%goto ERROR_EXIT;
        %end;
	%end;
	%else %if ("&import_type" = "TXT" or "&import_type" = "CSV"  or "&import_type" = "XLS") %then %do;
        %if not %sysfunc(fileexist("&MA_IMPORT_PATH/&table_name")) %then %do;
			%let MAMsg = %str(Error during import. File &table_name not found);
			%goto ERROR_EXIT;
        %end;
	%end;
	%else %do;
		%let MAMsg = %str(Error during import. Wrong import type);
		%goto ERROR_EXIT;
	%end;
	
	/* Импорт в SAS-таблицу */
	%if ("&import_type" = "TXT" or "&import_type" = "CSV") %then %do;

		/* Для типа импорта TXT разделитель - табуляция, для CSV - символ точки с запятой */
		%local mvDelimiter;
		%if ("&import_type" = "TXT") %then %do;
			%let mvDelimiter = '09'x;
			%let mvDelimiterCol=%str( );
		%end;
		%else %if ("&import_type" = "CSV") %then %do;
			%let mvDelimiter = ';';
			%let mvDelimiterCol=%str(;);
		%end;

		/*Считывание 1 линии c названиями полей в макропеременную*/
		data OSFile;
			infile "&MA_IMPORT_PATH/&table_name" truncover;
			input @1 ColNames $32500.;
			if _n_>1 then stop;	
			call symput('mvColumnNames',ColNames);
			found = indexc(ColNames, byte(13));
		run;
		
		proc sql noprint;
			select found into :found from OSFile;
		quit;

		%if &found = 0 %then %let form_fil = lf;
		%else %let form_fil = crlf;
		
		/*Поиск повторяющихся полей*/
		%let mvCntCols=%sysfunc(countc(&mvColumnNames,&mvDelimiterCol));
		%do i=1 %to &mvCntCols+1;
			%let ColName&i=%scan(&mvColumnNames,&i,&mvDelimiterCol);
			%do q=&i+1 %to &mvCntCols+1;
				%let ColNameTemp=%scan(&mvColumnNames,&q,&mvDelimiterCol);
				%if &ColNameTemp eq &&ColName&i %then %do;
					%let q=%eval(&mvCntCols+1);
					%let i=%eval(&mvCntCols+1);
					%let mvFlgMatched=1;
				%end;
			%end;
		%end;
		%if %symexist(mvFlgMatched) %then %do;
			%let MAMsg = %str(Column names must be unique);
			%goto ERROR_EXIT;
		%end;


		filename ldfiles "&MA_IMPORT_PATH/&table_name" encoding="wcyrillic" termstr=&form_fil;
		proc import datafile = ldfiles
			dbms = dlm
			out = imported_sas_table
			replace;
			delimiter = &mvDelimiter;
			getnames = yes;
		run;
		%if %DWL_NOT_OK %then %do;
			%let MAMsg = %str(Error during import.) &SYSERRORTEXT;
			%goto ERROR_EXIT;
		%end;
	%end;
	%else %if ("&import_type" = "XLS") %then %do;
		proc import datafile = "&MA_IMPORT_PATH/&table_name"
					dbms = xls
					out = imported_sas_table
					replace;
			getnames = yes;
		run;
	%end;
	
	/* Назначаем SAS-таблицу для разных типов источников */
	%if ("&import_type" = "SAS") %then %let mvImportedTable = maimport.&table_name;
	%else %if ("&import_type" = "TXT" or "&import_type" = "CSV" or "&import_type" = "XLS") %then %let mvImportedTable = imported_sas_table;

	%let mvRandomSuffix = %sysevalf(%sysfunc (ranuni(-1)) * 10000000, ceil)_&SYSJOBID;
	proc contents data=&mvImportedTable out=column_list (keep=NAME TYPE);				
	run;
	%if %DWL_NOT_OK %then %do;
		%let MAMsg = %str(Error during import.) &SYSERRORTEXT;
		%goto ERROR_EXIT;
	%end;
	
	/* Проверка что есть CUID */
	proc sql noprint;
		select count(1) into :mvCUIDFound from column_list where name = 'CUID';
	quit;
	%if %DWL_NOT_OK %then %do;
		%let MAMsg = %str(Error during import.) &SYSERRORTEXT;
		%goto ERROR_EXIT;
	%end;
		
	%if %eval(&mvCUIDFound) = 0 %then %do;
		%let MAMsg = %str(Column 'CUID' is missing);
		%goto ERROR_EXIT;
	%end;

	/* Проверка дублей CUID */
	proc sql noprint;
		select count(CUID)
		  into :mvCountCUID separated by ""
		  from &mvImportedTable;
	quit;
	%if %DWL_NOT_OK %then %goto ERROR_EXIT;
	proc sql noprint;
		select count(distinct CUID)
		  into :mvCountDistCUID separated by ""
		  from &mvImportedTable;
	quit;
	%if %DWL_NOT_OK %then %goto ERROR_EXIT;
	%if (%eval(&mvCountCUID) ^= %eval(&mvCountDistCUID)) %then %do;
		%let MAMsg = %str(Duplicate CUIDs);
		%goto ERROR_EXIT;
	%end;
	
	/* Грузим в Oracle */
	%mSetOraLib(MA_TEMP);
	
	data ma_temp.t_&mvRandomSuffix (&gmvBulkOpt drop=import_type import_name import_date cuid num_param1-num_param10 char_param1-char_param10
			rename=(x_cuid=cuid x_num_param1-x_num_param10=num_param1-num_param10 x_char_param1-x_char_param10=char_param1-char_param10));
		set &mvImportedTable;
		attrib x_cuid length=8. x_NUM_PARAM1-x_NUM_PARAM10 length=8 x_CHAR_PARAM1-x_CHAR_PARAM10 length=$100;
		retain x_cuid .;
		retain x_num_param1-x_num_param10 .;
		retain x_char_param1-x_char_param10 '';
		x_cuid = input(cuid, ??32.);
		%do i=1 %to 10;
			x_num_param&i = input(num_param&i, ??32.);
			x_char_param&i = input(char_param&i, ??$100.);
		%end;
		if missing(x_cuid) = 0;
	run;
	/*data ma_temp.t_&mvRandomSuffix (&gmvBulkOpt);
		attrib cuid length=8 NUM_PARAM1-NUM_PARAM10 length=8 CHAR_PARAM1-CHAR_PARAM10 length=$100;
		set &mvImportedTable;
	run;*/
	
	proc sql noprint;
		&mvConnectToOra;
		/* Очистка CUTOMER_IMPORTED от прошлых загрузок */
		/* execute (delete from &customer_imported_table where import_name=%str(%')&import_name%str(%') ) by ora; */
			execute ( execute &gmvMA_CMDM..drop_previous_import(%str(%')&customer_imported_table%str(%')  ,%str(%')&import_name%str(%') )) by ora;
		execute (create table &gmvMA_TEMP..to_&mvRandomSuffix as select CUID from &gmvMA_TEMP..t_&mvRandomSuffix where 0 = 1) by ora;
		execute (
			insert %str(/)*+ append *%str(/) all
			  into &customer_imported_table (IMPORT_TYPE, IMPORT_NAME, IMPORT_DATE, CUID, NUM_PARAM1, NUM_PARAM2,
				NUM_PARAM3, NUM_PARAM4, NUM_PARAM5, NUM_PARAM6, NUM_PARAM7, NUM_PARAM8, NUM_PARAM9, NUM_PARAM10, CHAR_PARAM1,
				CHAR_PARAM2, CHAR_PARAM3, CHAR_PARAM4, CHAR_PARAM5, CHAR_PARAM6, CHAR_PARAM7, CHAR_PARAM8, CHAR_PARAM9, CHAR_PARAM10)
			  values(IMPORT_TYPE, IMPORT_NAME, IMPORT_DATE, CUID, NUM_PARAM1, NUM_PARAM2,
				NUM_PARAM3, NUM_PARAM4, NUM_PARAM5, NUM_PARAM6, NUM_PARAM7, NUM_PARAM8, NUM_PARAM9, NUM_PARAM10, CHAR_PARAM1,
				CHAR_PARAM2, CHAR_PARAM3, CHAR_PARAM4, CHAR_PARAM5, CHAR_PARAM6, CHAR_PARAM7, CHAR_PARAM8, CHAR_PARAM9, CHAR_PARAM10)
			  into to_&mvRandomSuffix
			  values(CUID)
			select %str(%')&import_type%str(%') IMPORT_TYPE, %str(%')&import_name%str(%') IMPORT_NAME, sysdate IMPORT_DATE, t.*
			from &gmvMA_TEMP..t_&mvRandomSuffix t
				,&gmvMA_CMDM..V_CM_CLIENT c
			where t.cuid = c.id_cuid
		) by ora;
		disconnect from ora;
	quit;
	
	data &outTable;
		set ma_temp.to_&mvRandomSuffix (keep=CUID rename=CUID=ID_CUID) end = eods;
		if eods = 1 then do;
			call symput("mvRecordsCound", _N_);
		end;
	run;
	%ma_set_count(&mvRecordsCound);

	%goto EXIT;
	%ERROR_EXIT:
		%local OSYSCC;
		%DWL_RAISE_ERROR("&SYSMACRONAME failed");
		%if ("&MAMsg" = "") %then %mMAError(%str(Internal server error, please contact administrator. Error code: P2C01));
		%else %mMAError(&MAMsg);
		%let SYSCC = &OSYSCC;
	%EXIT:
	/* Для неотладочного режима удалять вспомогательные таблицы */
	%if (&MA_DEBUG = 0) %then %do;
		%if %sysfunc(exist(ma_temp.t_&mvRandomSuffix)) %then %do;
			proc sql noprint;
				drop table ma_temp.t_&mvRandomSuffix;
			quit;
		%end;
		%if %sysfunc(exist(ma_temp.to_&mvRandomSuffix)) %then %do;
			proc sql noprint;
				drop table ma_temp.to_&mvRandomSuffix;
			quit;
		%end;
	%end;
%mend;

%ma_import_table;

options nomlogic nosymbolgen;
%mastatus ( &_stpwork.status.txt );
%stpend;
