create table test_table (
first_name varchar2(36),
last_name varchar2(36),
state varchar2(9),
id number
);

create table cdm.states(
id number,
name varchar2(4)
);

insert into  cdm.states
values(1,'IA');
insert into  cdm.states
values(2,'LA');
insert into  cdm.states
values(3,'CL');
insert into  cdm.states
values(4,'NY');
insert into  cdm.states
values(5,'KY');
commit;

declare 
a number := 1;
n number;
m number;
state_name varchar2(36);
begin
  while a < &total
  loop
   SELECT round( dbms_random.value(1,10)) num 
    into n
    FROM dual;
    
   SELECT round( dbms_random.value(1,4)) num 
    into m
    FROM dual; 
    
    select name 
    into state_name
    from STATES
    where id= m;
    
    insert into cdm.test_table (
      id,
      first_name,
      last_name,
      state
    ) 
      values(
      a,
      substr('IvanPetrIgorAlexPaulJogh',  n  ,4),
      'LastName'||a||n,
      state_name
      );
   a:=a+1;      
  end loop;
end;
commit;


select * from test_table
where 
--FIRST_NAME='Igor'
--and 
LAST_NAME='LastName69';  




select count(*) from TEST_TABLE;

truncate table TEST_TABLE;


create unique INDEX test_tabel_ix ON test_table (first_name,last_name);

drop index test_tabel_ix;