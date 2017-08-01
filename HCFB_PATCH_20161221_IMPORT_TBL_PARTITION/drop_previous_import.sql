create or replace PROCEDURE drop_previous_import (table_name in varchar2, partition_value in varchar2)
is
exist_flag number;
begin
    EXECUTE IMMEDIATE  'select count(1) from '||table_name||'  where import_name='''||partition_value||'''' into exist_flag;
    if (exist_flag >=1)
    then --удаляем партицию если она существует
    EXECUTE IMMEDIATE 'alter table '||table_name|| ' drop PARTITION for( '||q'<'>'||partition_value|| q'<'>' ||')';
  end if;
  -- создаем новую партицию для нового импорта
  EXECUTE IMMEDIATE 'alter table '|| table_name || ' add partition P_' ||import_partition_name.NEXTVAL || ' values( '||q'<'>'||partition_value|| q'<'>' ||')';
end drop_previous_import; 
/


GRANT EXECUTE ON drop_previous_import TO MA_TEMP;

