explain plan for
select * from CDM.TETS
where id= :id_num;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());