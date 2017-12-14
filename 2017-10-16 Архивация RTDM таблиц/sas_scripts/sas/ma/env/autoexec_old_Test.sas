/*Переопределения основной директории среды на время подготовки второго релиза*/
%let MA_HOME_DIR = /sas/ma/env;


/*Объявление подключения к серверу метаданных*/
%global MA_META_CONN;
%global METADATA_REPOSITORY;
%let METADATA_REPOSITORY=Foundation;
%let MA_META_CONN = metaserver='172.18.18.15'
					metaport=8561
					metauser="sasadm@saspw"
					metapass='q1q1q1'
					metaprotocol=bridge
					metarepository="&METADATA_REPOSITORY";

/*Подключение к серверу метаданных*/
%macro mMetaProp;
	options &MA_META_CONN;
%mend mMetaProp;

/* Подключение общих макросов */
%include "&MA_HOME_DIR./scripts/common/*.sas";

/* Переменная уровня логирования */
%global MA_DEBUG;
%let MA_DEBUG = 2;
/* Задание опция логирования в соответствии с заданным уровнем*/
%mDebugLevel(mvDebugLevel = &MA_DEBUG);

/* Контроль ошибок */
/* Переменная стандартного текста внутренней ошибки */
%global MA_INTERNAL_ERROR_TEXT;
%let MA_INTERNAL_ERROR_TEXT = Internal error, please contact administrator;
/* Инициализация контроля ошибок */
%MA_INIT_ERROR;

/* Перенаправление логов */
%global MA_PROCESS_NAME;

/* Переменная с именем библиотеки, которая будет использоваться для коммуникаций */
%global MA_COMM_EXPORT_LIBRARY;
%let MA_COMM_EXPORT_LIBRARY = EXP_LIB;

%global MA_LIBRARIES;
%let MA_LIBRARIES=CDM|CMDM|MONITOR|PREVIEW|MA_USER|TESTRUN|INTEGR|EXP_LIB;

/*Инициализация имен используемых библиотек*/
%global CDM_LIB CMDM_LIB MON_LIB PREV_LIB MAUSER_LIB TESTR_LIB INT_LIB;
%let CDM_LIB=CDM;
%let CMDM_LIB=CMDM;
%let MON_LIB=MONITOR;
%let PREV_LIB=PREVIEW;
%let MAUSER_LIB=MA_USER;
%let TESTR_LIB=TESTRUN;
%let INT_LIB=INTEGR;
/*Обяления глобальных макропеременных с параметрами подключения и их инициализация*/
/*Для каждой библиотеки есть 4 макропеременные:
[PREFIX]_LIB
[PREFIX]_PATH
[PREFIX]_AUTH
[PREFIX]_SCHEMA
*/

%mDefineLibraries(CDM_LIB CMDM_LIB MON_LIB PREV_LIB MAUSER_LIB TESTR_LIB INT_LIB);

/**********************************************************************************/
/*Настроечные параметры*/
%global CLIENT_IDENTITY CONTACT_EXT_ATTRS;
%let CLIENT_IDENTITY = CLIENT_UK;

%let COMM_WAVE_ATTR = PATTERN_ID SERVICES_UK 
END_DATE
END_TIME
FLG_DELAY
DELAY
DELIVERY_DAYS
PATTERN_TEXT
START_DATE
START_TIME
SUBJECT
PRIORITY
TEST_LAUNCH_FLG
EXP_TABLE_NAME
TRANSPOSE_COLUMN_NUM; 

/*Неспецифичные для канала необязательные атрибуты CONTACT_EXT*/
%let CONTACT_EXT_ADD_ATTRS = ?DEAL_LOAN_UK#1 ?PAYMENT_SUM#1;

/*Обязательные  аттрибуты таблицы экспорта, специфичные для канала DM */
%let DMCI_PARAMS = ADDRESS_POST POST_POST_INDEX LAST_NAME FIRST_NAME MIDDLE_NAME;
/*Аттрибуты таблицы экспорта которые необходимо переименовать (поддерживается только в DM)*/
%let ATTRS_TO_RENAME = ADDRESS_POST POST_POST_INDEX;
%let ATTRS_NEW_NAME  = ADDRESS "INDEX";

/*Общие переменные*/
%global CNT_PREVIEW_RECORDS;/*Кол-во записей, выводимое на экран при нажатии на имя таблицы в веб интерфейсе*/
%let CNT_PREVIEW_RECORDS=50;

/* Переменные для интеграции с системой RTDM */
%global RTDM_SERVER_URL RTDM_REQUEST_CNT RTDM_PATH_TO_XML;
/* URL */
%let RTDM_SERVER_URL = http://dc1-rtmtdev:8680/RTDM/Event;
/*%let RTDM_SERVER_URL = http://dc1-rtmttst:8680/RTDM/Event;*/ /*ђхёђ*/
/* Максимальное количество попыток отправки запроса */
%let RTDM_REQUEST_CNT = 2;
/* Путь к временным xml-файлам */
%let RTDM_PATH_TO_XML = /temp/rtdm_int_xml;

%global ADMIN_EMAIL ;
%let ADMIN_EMAIL ="leto_mccm_support@glowbyteconsulting.com";
%global USER_EMAIL;
%let USER_EMAIL ="savichevav@letobank.ru" "sidorovan@letobank.ru";


%global SEND_EMAIL_TO SEND_EMAIL_FROM SERVERNAME;
%let SEND_EMAIL_TO = "leto_mccm_support@glowbyteconsulting.com"  "kostomarovis@letobank.ru";;
%let SEND_EMAIL_FROM = "noreply@letobank.ru";
%let mvServerName = TST;

%global SEND_EMAIL_TO_MONITORING;
%let SEND_EMAIL_TO_MONITORING = "leto_mccm_support@glowbyteconsulting.com" "sas_cm_support@letobank.ru" "tsaturyanka@letobank.ru" "kostomarovis@letobank.ru";

/*Bulkload*/
%global BULK_OPTIONS;
%let BULK_OPTIONS=%str(BULKLOAD=yes BL_DEFAULT_DIR='/temp/SQLLOADER_DATA/');

/* Статус загрузки */
%global LOAD_STATUS DEACTIVATE_STATUS;
%let LOAD_STATUS = NEW;
%let DEACTIVATE_STATUS = NEW;

%global SashomePath;
%let SashomePath=SASHome;

%global UserName UserPassword;
%let UserName=sasdemo;	
%let UserPassword=q1q1q1;	

%global mvAPNonIncludedAttrs mvEXPIncludedAttrs;
%let mvAPNonIncludedAttrs = CLIENT_UK ACTION_ID CAMPAIGN_CD PRODUCT_UK RTDM_DECISION_DTTM EXPIRE_DECISION_DT LAST_UPDATE_DTTM RATE_ON_INSURANCE;
%let mvEXPIncludedAttrs = BASE_DEAL_LOAN_UK RESTR_DEAL_LOAN_NO CREDIT_AMT CREDIT_RATE CREDIT_TERM CM_CALC_PAY SEGMENT SEGMENT_GROUP;



/*Интеграция с Siebel*/
/*путь к xml*/
%let SIEBEL_PATH_TO_XML=/temp/siebel_int_xml;
/*список обязательных полей*/
%let mvExpTableCols=DELIVERYORGCODE,INSURANCEFORM,INSURANCETYPE,CARDTYPE,ProductCode;
%let mvExpTableColsExt=DELIVERYORGCODE INSURANCEFORM INSURANCETYPE CARDTYPE ProductCode;
/*вложенные пути xml*/
%let mvPathSiebelRequest2=&SIEBEL_PATH_TO_XML./&mvExportTableName./request/sec_request_to_siebel;
%let mvPathSiebelResponse1=&SIEBEL_PATH_TO_XML./&mvExportTableName./response/fst_response_from_siebel;
%let mvPathSiebelResponse2=&SIEBEL_PATH_TO_XML./&mvExportTableName./response/sec_response_from_siebel;
%let mvPathSiebelRequest1=&SIEBEL_PATH_TO_XML./&mvExportTableName./request/fst_request_to_siebel;
%let mvSiebelFstRequestMap=/sas/ma/env/work/maps/first_response_allchar.map;
%let mvSiebelSecRequestMap=/sas/ma/env/work/maps/sec_response_allchar.map;
/*адрес логин и пароль к siebel*/
%let SIEBEL_SERVER_URL='http://172.19.2.10/eai_rus/start.swe?SWEExtSource=WebService&SWEExtCmd=Execute&username=BROKER&password=QWERTY$4';
%let mvExpTableColsNull=PARTICIPANT_ID is null or DELIVERYORGCODE is null or INSURANCEFORM is null/* or INSURANCETYPE is null */ or CARDTYPE is null or ProductCode is null;
