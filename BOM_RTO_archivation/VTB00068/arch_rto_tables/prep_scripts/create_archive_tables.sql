create table ma_temp.arc_REFINANCE_INPUT TABLESPACE SAS  as select * from infomap.REFINANCE_INPUT where 1=0 ;
create table ma_temp.arc_REFINANCE_LOG_DECISION_F8 TABLESPACE SAS as select * from infomap.REFINANCE_LOG_DECISION_F8 where 1=0 ;
create table ma_temp.arc_PRED_RECALC_OFFER  TABLESPACE SAS as select * from infomap.PRED_RECALC_OFFER where 1=0 ;
create table ma_temp.arc_PRED_RECALC_VARIANT TABLESPACE SAS as select * from infomap.PRED_RECALC_VARIANT where 1=0 ;
create table ma_temp.arc_PRED_RECALC_KN_RES TABLESPACE SAS as select * from infomap.PRED_RECALC_KN_RES where 1=0 ;
create table ma_temp.arc_PRED_RECALC_KN_SUMS1  TABLESPACE SAS as select * from infomap.PRED_RECALC_KN_SUMS1 where 1=0 ;
create table ma_temp.arc_PRED_RECALC_CC_RES TABLESPACE SAS as select * from infomap.PRED_RECALC_CC_RES where 1=0 ;
create table ma_temp.arc_PRED_RECALC_SCORE_RES  TABLESPACE SAS as select * from infomap.PRED_RECALC_SCORE_RES where 1=0 ;
create table ma_temp.arc_REF_ERRONEOUS_DATA TABLESPACE SAS as select * from infomap.REF_ERRONEOUS_DATA where 1=0 ;
create table ma_temp.arc_ESP_REFINANCE TABLESPACE SAS as select * from odm.ESP_REFINANCE where 1=0 ;
create table ma_temp.arc_NBO_OFFERS TABLESPACE SAS as select * from RTDM_CDM.NBO_OFFERS where 1=0 ;
create table ma_temp.arc_RET_SCORE_MODEL_RESULTS TABLESPACE SAS as select * from RTDM_CDM.RET_SCORE_MODEL_RESULTS where 1=0 ;


CREATE TABLE MA_TEMP.RTO_ARCH_HISTORY 
(
  RUN_ID NUMBER NOT NULL 
, TABLE_NAME VARCHAR2(30 BYTE) 
, START_DTTM DATE 
, FINISH_DTTM DATE 
, ARCHIVE_STATUS VARCHAR2(8 BYTE) 
, DELETE_STATUS VARCHAR2(8 BYTE) 
, STATISTICS_STATUS VARCHAR2(8 BYTE) 
, CURRENT_RECORDS NUMBER 
, ARCHIVED_RECORDS NUMBER 
) 
TABLESPACE SAS ;

exit;