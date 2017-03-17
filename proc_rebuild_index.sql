create or replace PROCEDURE rebuild_index(tabName in varchar2) 
as
	begin 
						for x in (select INDEX_NAME  from USER_INDEXES  where TABLE_NAME=upper(tabName)  )
						loop
							EXECUTE IMMEDIATE 
							'alter index '||x.INDEX_NAME || ' rebuild' ;
						end loop;
  end;
