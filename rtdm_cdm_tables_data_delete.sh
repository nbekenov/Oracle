#!/usr/bin/expect

send_user "$env(PATH)\n"
send_user "$env(ORACLE_HOME)\n"
send_user "$env(TNS_ADMIN)\n"

set userName  "RTDM_CDM@ADB_TST"
set passwd    "sasuser"
set RTO_LOG_delete_expr      "delete from RTDM_CDM.RTO_LOG where trunc(REQUEST_TIME_INCOME) < trunc(sysdate )-7;"
set RTO_LOG_move_expr        "ALTER TABLE RTDM_CDM.RTO_LOG MOVE TABLESPACE USERS;"

set NBO_OFFERS_delete_expr   "delete from RTDM_CDM.NBO_OFFERS where trunc(create_date) < trunc(sysdate )-28;"
set NBO_OFFERS_move_expr     "ALTER TABLE RTDM_CDM.NBO_OFFERS MOVE TABLESPACE USERS;"

set CI_TREATMENT_NUM_UDF_delete_expr "delete from RTDM_CDM.CI_TREATMENT_NUM_UDF where trunc(processed_dttm) < trunc(sysdate)-28;"
set CI_TREATMENT_NUM_UDF_move_expr "ALTER TABLE RTDM_CDM.CI_TREATMENT_NUM_UDF MOVE TABLESPACE USERS;"
set TREAT_NUM_UDF_rebuild_ind_expr "ALTER INDEX TREAT_NM_UDF_PK REBUILD;"

set  CI_CONTACT_HISTORY_delete_expr "delete from RTDM_CDM.CI_CONTACT_HISTORY where trunc(CONTACT_DT) < trunc(sysdate )-14;"
set  CI_CONTACT_HISTORY_move_expr   "ALTER TABLE RTDM_CDM.CI_CONTACT_HISTORY MOVE TABLESPACE USERS;"
set  CONT_HIST_rebuild_ind_expr     "ALTER INDEX CONT_HIST_PK REBUILD;"

set commit "commit;"
#invoke sqlplus
spawn /home/oracle/app/oracle/product/11.2.0/client_1/bin/sqlplus
expect "Enter user-name:"
send "$userName\r"
expect "Enter password:"
send "$passwd\r"

#RTO_LOG data delete
expect "SQL>"
send "$RTO_LOG_delete_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$RTO_LOG_move_expr\r"
expect "SQL>"
send "$commit\r"

#$NBO_OFFERS data delete
expect "SQL>"
send "$NBO_OFFERS_delete_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$NBO_OFFERS_move_expr\r"
expect "SQL>"
send "$commit\r"

#CI_TREATMENT_NUM_UDF data delete
expect "SQL>"
send "$CI_TREATMENT_NUM_UDF_delete_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$CI_TREATMENT_NUM_UDF_move_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$TREAT_NUM_UDF_rebuild_ind_expr\r"
expect "SQL>"
send "$commit\r"


#CI_CONTACT_HISTORY data delete
expect "SQL>"
send "$CI_CONTACT_HISTORY_delete_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$CI_CONTACT_HISTORY_move_expr\r"
expect "SQL>"
send "$commit\r"
expect "SQL>"
send "$CONT_HIST_rebuild_ind_expr\r"
expect "SQL>"
send "$commit\r"


#Close sqplus 
expect "SQL>"
send "exit\r"

close



