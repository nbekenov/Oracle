%include '/sas/sas/env/scripts/ma/ma_autoexec.sas';

%let ADMIN_EMAIL ="";
%let USER_EMAIL = "nursultan.bekenov@glowbyteconsulting.com";

options emailhost="&EMAILHOST"
			emailauthprotocol=&EMAILAUTHPROTOCOL
			EMAILFROM
			emailport=&EMAILPORT
			emailid="&EMAILID"
			emailpw="&EMAILPW"; 
		

&MA_TEMP_LIBNAME_STATEMENT;

%let max_run_id;
proc sql noprint;
select max(run_id) into :max_run_id from ma_temp.rto_arch_history;
quit;

data added_values;
format archived_pct percent6.0;
format delta_minutes 10.2;
set ma_temp.rto_arch_history;
archived_pct = archived_records / (current_records + archived_records);
delta_minutes = (finish_dttm - start_dttm) / 60.0;
run;


proc sort data=added_values out=sorted;
where run_id=&max_run_id;
by start_dttm;
run;

filename mail email to=(&USER_EMAIL) cc=(&ADMIN_EMAIL) subject="SAS RTO Archivation results" content_type="text/html";
ODS LISTING CLOSE;
ODS HTML BODY=mail encoding='wcyrillic';

proc report data=sorted ;
TITLE 'Это тест! Результаты архивирования таблиц RTO';
COLUMN run_id table_name archive_status delete_status statistics_status archived_pct
current_records archived_records start_dttm finish_dttm delta_minutes ;
LABEL run_id='#';
LABEL table_name='Имя таблицы';
LABEL start_dttm='Начало архивации';
LABEL finish_dttm='Конец архивации';
LABEL delta_minutes='Время архивации, мин.';
LABEL archived_pct='Доля архивированных записей';
LABEL current_records='Актуальных записей';
LABEL archived_records='Архивированных записей';
LABEL archive_status='Статус добавления в архив';
LABEL delete_status='Статус удаления из CIDM';
LABEL statistics_status='Статус сборки статистики';
compute table_name;
	count+1;
	if count <=5 then
		call define(_row_,"style","style={background=cxCCFFFF}");
	else 
		call define(_row_,"style","style={background=cxE5FFCC}");
endcomp;
compute archive_status;
	if archive_status = 'OK' then
		call define (3, "style", "style={background=cxB2FF66}");
	else
		call define (3, "style", "style={background=cxFF6666}");
endcomp;
compute delete_status;
	if delete_status = 'OK' then
		call define (4, "style", "style={background=cxB2FF66}");
	else
		call define (4, "style", "style={background=cxFF6666}");
endcomp;
compute statistics_status;
	if statistics_status = 'OK' then
		call define (5, "style", "style={background=cxB2FF66}");
	else
		call define (5, "style", "style={background=cxFF6666}");
endcomp;
run;
ODS HTML CLOSE;
ODS LISTING;
