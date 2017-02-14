#!/bin/sh

sudo -u postgres psql -a -U postgres -d stifdb -f pgsnapshot_schema_0.6.sql
sudo -u postgres psql -a -U postgres -d stifdb -f pgsnapshot_schema_0.6_linestring.sql
