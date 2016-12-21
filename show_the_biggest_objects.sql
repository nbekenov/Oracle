select
owner,
segment_name,
sum(bytes) / 1024 / 1024 / 1024 size_Gb
from dba_segments
group by owner, segment_name
order by size_Gb desc;
