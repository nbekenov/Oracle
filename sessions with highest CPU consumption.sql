SELECT USERNAME,
  STATUS,
  SCHEMANAME,
  OSUSER,
  MACHINE,
  N.SQL_ID,
  VALUE,
  SQL.SQL_TEXT
FROM v$sesstat s,
  v$statname t,
  v$session n,
  V$SQL SQL
WHERE s.STATISTIC# = t.STATISTIC#
AND n.SID          = s.SID
AND N.SQL_ID       = SQL.SQL_ID
AND t.NAME LIKE '%CPU used by this session%';