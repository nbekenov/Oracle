create or replace procedure DROP_PAR (tab_name in varchar2,p_par_name in varchar2) 
is 
  begin 
    execute immediate 'alter table '|| tab_name || ' drop partition '||p_par_name; 
  end; 

grant execute on CDM.DROP_PAR to MA_USER;
