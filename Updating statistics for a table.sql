exec dbms_stats.unlock_table_stats('SCHEMA1','COMPANY');
EXEC DBMS_STATS.GATHER_TABLE_STATS('SCHEMA1','COMPANY');
