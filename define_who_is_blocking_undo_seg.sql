select S.Username,S.Sid,S.Serial#,T.Start_time,T.Xidusn
  from V$Session S, V$TRANSACTION T, V$ROLLSTAT R
 where S.Saddr = T.Ses_addr 
   and T.Xidusn = R.Usn
   and ((R.Curext = T.Start_uext-1)
       or  
       ((R.Curext = R.Extents - 1) and (T.Start_uext = 0))
    );