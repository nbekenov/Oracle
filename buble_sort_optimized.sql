
declare 
type artype is varray(8) of integer;
my_array artype;
total integer;
temp integer;
swap boolean;
begin
my_array := artype(1,2,3,4,5);
total := my_array.count;

for i in 1 ..total loop
DBMS_OUTPUT.PUT_line(i||' step');
  swap:=false;
  for  j in 1 ..(total-i) loop
     DBMS_OUTPUT.PUT_line(j||' index');
    if my_array(j) > my_array(j+1)
    then temp := my_array(j);
         my_array(j) := my_array(j+1);
         my_array(j+1):=temp;
         swap:=true;
    end if;
   
  end loop;
  
  if not swap
  then exit;
  end if;
end loop;
/* Prints the array */
DBMS_OUTPUT.PUT_line('sorted array :');
for k in 1..total loop
  DBMS_OUTPUT.PUT_line(my_array(k));
    end loop;
end;