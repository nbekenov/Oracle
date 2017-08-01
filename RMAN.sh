which rman
rman target /

show all ;

using target database control file instead of recovery catalog
RMAN configuration parameters for database with db_unique_name OCA12C are:
CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
CONFIGURE BACKUP OPTIMIZATION OFF; # default
CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
CONFIGURE CONTROLFILE AUTOBACKUP OFF; # default
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE MAXSETSIZE TO UNLIMITED; # default
CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
CONFIGURE RMAN OUTPUT TO KEEP FOR 7 DAYS; # default
CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/u01/app/oracle/product/12.1.0/dbhome_1/dbs/snapcf_oca.f'; # default


CONFIGURE BACKUP OPTIMIZATION on ;


backup database include current controlfile ;

backup incremental level 0 tablespace users ;
backup incremental level 1 tablespace users ;


--close backup
shutdown immediate;
startup mount;
backup database;



[oracle@localhost ~]$ cat rmanbackup.rman
run
{
allocate channel ch1 device type disk format '/u01/app/oracle/oradata/%U';
backup database;
release channel ch1;
}


[oracle@localhost ~]$ cat runshellbackup.sh
#!/bin/bash
rman target / catalog rman/rman@oca12c @rmanbackup.rman
