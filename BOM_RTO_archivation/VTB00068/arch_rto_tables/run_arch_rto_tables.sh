#!/bin/bash
export ORACLE_SID=adb
export ORACLE_HOME=/home/oracle/app/oracle/product/11.2.0/client_1
export NLS_LANG=RUSSIAN_RUSSIA.UTF8
DATE=`date +%m%d%H%M`
export LOGFILE="/temp/arch_logs/arch_rto_tables_$DATE.log"

export NLS_LANG=RUSSIAN_RUSSIA.UTF8

$ORACLE_HOME/bin/sqlplus 'gb_dba/yjdsqgfhjkm@e8b-km-sasdb/adb' @/home/oracle/arch_rto_tables/arch_rto_tables.sql > $LOGFILE
