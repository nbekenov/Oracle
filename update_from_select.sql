UPDATE  qrtz_triggers t1
   SET START_TIME = (SELECT t2.START_TIME
                         FROM qrtz_triggers_ext t2
                        WHERE t1.trigger_name = t2.trigger_name)
 WHERE EXISTS (
    SELECT 1
      FROM qrtz_triggers_ext t2
     WHERE t1.trigger_name = t2.trigger_name);
