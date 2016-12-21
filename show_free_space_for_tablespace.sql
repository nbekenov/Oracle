select
    nvl(b.tablespace_name, nvl(a.tablespace_name,'UNKNOWN')) name,
    gbytes_alloc  gbytes,
    gbytes_alloc-nvl(gbytes_free,0) used,
    nvl(gbytes_free,0) free,
    ((gbytes_alloc-nvl(gbytes_free,0))/gbytes_alloc)*100 pct_used,
    nvl(largest,0) largest
from (select
        sum(bytes)/1024/ 1024 / 1024 gbytes_free,
        max(bytes)/1024/ 1024 / 1024 largest,
        tablespace_name
      from sys.dba_free_space
      group by tablespace_name) a,
     (select
        sum(bytes)/1024/ 1024 / 1024 gbytes_alloc,
        tablespace_name
      from sys.dba_data_files
      group by tablespace_name) b
where a.tablespace_name (+) = b.tablespace_name
order by gbytes desc;
