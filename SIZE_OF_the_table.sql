
-- размер таблицы
SELECT 
    lower( owner )      AS owner
    ,lower(table_name)  AS table_name
    ,tablespace_name
    ,num_rows
    ,blocks*8/1024      AS size_mb
    ,pct_free
    ,compression 
    ,logging
FROM    all_tables 
WHERE   owner           LIKE UPPER('CDM')
and table_name=upper('rtdm_client_application')
ORDER BY size_mb desc NULLS last;



--размер lob объектов

 Select s.owner, d.table_name, d.column_name, s.segment_name, s.segment_type, s. bytes/1024/1024/1024 as size_gb,
s.tablespace_name From DBA_SEGMENTS s, DBA_LOBS d
Where s.segment_name in (d.segment_name,d.index_name) and s.owner=d.owner
and d.owner='CDM' and d.table_name = upper('rtdm_client_application')  ;