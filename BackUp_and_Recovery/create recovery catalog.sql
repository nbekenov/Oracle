--create recovery catalog

create tablespace cattbs;

create user rman identified by rman
   temporary tablespace temp
   default tablespace cattbs
  quota unlimited on cattbs;

grant recovery_catalog_owner to rman;


 rman target /
connect catalog rman/rman
create catalog ;
register database;

RMAN> report schema ;
rman target / catalog rman/rman@oca12c

Recovery Manager: Release 12.1.0.2.0 - Production on Sun Jul 2 02:33:25 2017

Copyright (c) 1982, 2014, Oracle and/or its affiliates.  All rights reserved.

connected to target database: OCA12C (DBID=2472777883)
connected to recovery catalog database

RMAN>
