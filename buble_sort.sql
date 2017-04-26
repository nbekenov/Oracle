
declare 
type artype is varray(8) of integer;
my_array artype;
total integer;
temp integer;
begin
my_array := artype(2,7,6,3,4,1,8,5);
total := my_array.count;

for i in 1 ..total loop
  for  j in 1 ..(total-i) loop
    if my_array(j) > my_array(j+1)
    then temp := my_array(j);
         my_array(j) := my_array(j+1);
         my_array(j+1):=temp;
    end if;
  end loop;
end loop;
/* Prints the array */
DBMS_OUTPUT.PUT_line('sorted array :');
for k in 1..total loop
  DBMS_OUTPUT.PUT_line(my_array(k));
    end loop;
end;