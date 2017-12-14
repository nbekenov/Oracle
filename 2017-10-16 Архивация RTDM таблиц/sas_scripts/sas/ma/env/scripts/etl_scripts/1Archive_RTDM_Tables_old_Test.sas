options mprint mlogic symbolgen sastrace=',,,d' sastraceloc=saslog;
%include '/sas/ma/env/autoexec.sas';
%include "&MA_HOME_DIR/scripts/etl_scripts/UpdateLaunchHistory.sas";
/******************************* *******************/
/*Макрос архивации таблицы RTDM_CLIENT_APPLICATION
  параметры:
	mvCompress_period - период архивации
	cdm.ARCHIVE_PARTITION.ARCH_PARTITION - процедруа PL/SQL находится в пакете ARCHIVE_PARTITION
*/
/**************************************************/

%macro mArch_partition (mvCompress_period);
%macro d; %mend d;

%include '/sas/ma/env/autoexec.sas';

%global STATUS;
%let STATUS = ''; 

%local mvProcessName mvSrartFlag;
	%let mvProcessName=ArchiveRTDM_table;
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


proc sql noprint; 
connect to oracle as ora (AuthDomain=&CDM_AUTH Path=&CDM_PATH); 
	execute (call cdm.ARCHIVE_PARTITION.ARCH_PARTITION ('CDM.RTDM_CLIENT_APPLICATION', &mvCompress_period., '_ARCH', '','')
	) by ora; 
	disconnect from ora; 
quit;

proc sql noprint; 
connect to oracle as ora (AuthDomain=&CDM_AUTH Path=&CDM_PATH); 
	execute (call cdm.rebuild_index('RTDM_CLIENT_APPLICATION')
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
	%mUpdateLaunchHistory(&mvSrartFlag, &mvCurrDateTime, &mvProcessName, mvTypeFail=&mvTypeErr, mvErrorText=&mvError);
	%if %MA_NOT_OK %then %do;
		%MA_RAISE_ERROR(%nrquote(&MA_INTERNAL_ERROR_TEXT),mvErrorNum=12335);
	%end;

%macro COMPRESS_STATUS;
%if (%eval(&sysrc)^=0 or %eval(&syserr)>4) %then %do;
		%let STATUS = 'ERROR'; %end;
	%else %do;
		%let STATUS = 'SUCCESS';
%end;

/* отправка оповещения */
FILENAME Mailbox  EMAIL 'leto_mccm_support@glowbyteconsulting.com'
Subject = "LTB [TEST] SERVER ARCHIVE TABLE 'SUCCESS"  encoding='utf-8';
DATA _NULL_;
FILE Mailbox;
PUT "The archivation process of the tables ended with the status &STATUS.";
%if &STATUS. = 'ERROR' %then %do;
PUT "Error message:";
PUT "&SYSERRORTEXT";
%end;
RUN;

%mend COMPRESS_STATUS;
%COMPRESS_STATUS;

%EXIT:
%mend mArch_partition;
%mArch_partition(2);