--вернуть таблицу из бекапа
RENAME  customer_imported TO customer_imported_test;
RENAME  CUSTOMER_IMPORTED_BKP TO CUSTOMER_IMPORTED;


drop procedure drop_previous_import;

drop sequence import_partition_name;

drop table CUSTOMER_IMPORTED_TEST;


--песобрать статистику 
exec dbms_stats.unlock_table_stats('MA_CMDM','customer_imported');
EXEC DBMS_STATS.GATHER_TABLE_STATS('MA_CMDM','customer_imported');