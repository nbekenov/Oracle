set serveroutput on
/*****************
The selection sort algorithm sorts an array by repeatedly finding the minimum element (considering ascending order) from unsorted part and putting it at the beginning. 
The algorithm maintains two subarrays in a given array.
1) The subarray which is already sorted.
2) Remaining subarray which is unsorted.
*****************/
declare 
type array_type is VARRAY(5) of integer;
ar array_type;
total integer;
min_value integer;
min_value_index integer;
begin
ar := array_type(5,1,3,2,4);
total := ar.count;

  for i in 1..total loop
  
  -- Find the minimum element in unsorted array
    min_value_index := i;
    for j in (i+1) ..total loop
      if ar(j)<ar(min_value_index)
        then min_value_index := j;
      end if;
    end loop;
    --Swap the found minimum element with the first
     min_value:=ar(min_value_index);
     ar(min_value_index):=ar(i);
     ar(i):=min_value;
    
  end loop;
/* Prints the array */
DBMS_OUTPUT.PUT_line('sorted array :');
for k in 1..total loop
  DBMS_OUTPUT.PUT_line(ar(k));
    end loop;
end;