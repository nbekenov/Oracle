/*Макрос архивации таблиц RTDM_CLIENT_APPLICATION,RTDM_CLIENT_ALTERNATIVES, RTM_REQUEST_LOG, RTM_REQUEST_LOG_EXT
  параметры:
	cdm.rtdm_tab_archivation - PL/SQL процедруа архивация
		- v_table_name - название основной архивируемой таблицы
		- v_der_table - название зависимой таблицы
		- v_key_field - поле по которому связанны таблицы
		- mvCompress_period -период архивации указан в autoexec.sas
*/
%macro mArch_rtdm_tables;
	%macro d; %mend d;
	
	/*Подключение файла autoexec и других вспомогательных скриптов*/
	%include '/sas/ma/env/autoexec.sas';
	%include "&MA_HOME_DIR/scripts/etl_scripts/UpdateLaunchHistory.sas";
	%include "&MA_HOME_DIR/scripts/etl_scripts/SendEmail.sas";
	
	/*Объявление и инициализация общих переменных*/
	%local mvProcessName mvSrartFlag;
	%let mvProcessName=ArchiveRTDM_tables;
	%let mvSrartFlag=1;
	
	/*Получение текущего времени*/
	%local mvCurrDateTime;
	data _null_;
		curr_datetime=datetime();
		call symput('mvCurrDateTime',curr_datetime);
		call symput('mvFormatDateTime', put(curr_datetime, datetime15.));
	run;	
	
	/*Редирект лога*/
	%let MA_PROCESS_NAME=&mvProcessName;
	%mRedirectLog(mvIsETL = 1);
	%local mvTypeErr;
	%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvTypeFail=RUNNING);
	%let mvSrartFlag=0;
	%let mvTypeErr=ERROR;
	%if %MA_NOT_OK %then %do;
		%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvErrorText=%nrquote(&SYSERRORTEXT), mvTypeFail=ERROR);
		%MA_RAISE_ERROR(%nrQuote(&MA_INTERNAL_ERROR_TEXT),mvErrorNum = 12300);
		%goto EXIT;
	%end;

	/*E-MAIL оповещение */
	/*Объявление переменной с темой письма*/
	%local mvSubject;
	%local mvPrStatus;
	%let mvPrStatus=START;
	%let mvSubject=LTB ETL &mvServerName &mvPrStatus Архивация таблиц RTM &mvFormatDateTime;

	/*Вызываем макрос отправки письма*/
	%mSendEmail(&mvProcessName, mvSubject=&mvSubject);
	%if %MA_NOT_OK %then %do;
		%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvErrorText=%nrquote(&SYSERRORTEXT), mvTypeFail=ERROR);
		%MA_RAISE_ERROR(%nrQuote(&MA_INTERNAL_ERROR_TEXT),mvErrorNum = 12310);
		%goto EXIT;
	%end;
	
	/*вызов процедуры архивации */	
	proc sql noprint; 
		connect to oracle as ora (AuthDomain=&CDM_AUTH Path=&CDM_PATH); 
			execute (call cdm.rtdm_tab_archivation ('RTDM_CLIENT_APPLICATION','RTDM_CLIENT_ALTERNATIVES','APPLICATION_ID',&mvCompress_period.)
					) by ora; 
			execute (call cdm.rtdm_tab_archivation ('RTM_REQUEST_LOG','RTM_REQUEST_LOG_EXT','RTM_REQUEST_ID',&mvCompress_period.)
					) by ora; 
		disconnect from ora; 
	quit;
	%if %MA_NOT_OK %then %do;
		%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvErrorText=%nrquote(&SYSERRORTEXT), mvTypeFail=&mvTypeErr);
		%MA_RAISE_ERROR(%nrquote(&MA_INTERNAL_ERROR_TEXT),mvErrorNum=12330);
		%goto EXIT;
	%end;
	%else %do;
		%local mvError;
		%let mvTypeErr=SUCCESS;
		%let mvError=;	
	%end;
	%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvErrorText=&mvError, mvTypeFail=&mvTypeErr );
	%if %MA_NOT_OK %then %do;
		%MA_RAISE_ERROR(%nrquote(&MA_INTERNAL_ERROR_TEXT),mvErrorNum=12335);
	%end;
	
	%EXIT:
	
		%local mvMailMessage;
		%if &mvTypeErr ne SUCCESS %then %do;
			%let mvMailMessage=%sysfunc(cat(&mvTypeErr.. Более детальная информация находится в таблице MA_ETL_LAUNCHER_HISTORY));
		%end;
		%else %do;
			%let mvMailMessage=SUCCESS;
		%end;

		%let mvPrStatus=&mvTypeErr;
		%let mvSubject=LTB ETL &mvServerName &mvPrStatus Архивация таблиц RTM &mvFormatDateTime;

		%mSendEmail(&mvProcessName, mvSubject=&mvSubject,mvIsStart=0, mvRes=&mvMailMessage.);	
		
%mend mArch_rtdm_tables;
%mArch_rtdm_tables;