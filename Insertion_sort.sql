set serveroutput on
DECLARE 
type ar_type is varray(5) of integer;
ar ar_type;
total integer;
cur_val integer;
j integer;
begin

ar :=ar_type(2,3,4,5,1);
total :=ar.count;

for i in 2..total loop
  cur_val:=ar(i);
  j:=i-1;
  
  while (j>0 and  cur_val<ar(j)  ) loop
  ar(j+1):=ar(j);
  j:=j-1;
  end loop;
ar(j+1):=cur_val;
end loop;

/* Prints the array */
DBMS_OUTPUT.PUT_line('sorted array :');
for k in 1..total loop
  DBMS_OUTPUT.PUT_line(ar(k));
    end loop;

end;