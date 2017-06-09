select 
s.sid, s.USERNAME, s.OSUSER,
s.MACHINE, s.PROCESS, s.MODULE, s.PROGRAM,
to_char(sm.BEGIN_TIME, 'HH24:MI:ss') as interval_start,
to_char(sm.END_TIME, 'HH24:MI:ss') as interval_end,
sm.cpu, sm.PGA_MEMORY, sm.LOGICAL_READS, sm.PHYSICAL_READS,
s.LOGON_TIME
from v$session  s
join v$sessmetric sm
on s.sid=sm.session_id
where s.type='USER'
order by sm.cpu desc;