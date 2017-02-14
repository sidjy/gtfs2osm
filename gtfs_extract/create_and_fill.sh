#!/bin/sh

#sudo -u postgres dropdb -e stifdb
#sudo -u postgres createdb -e stifdb
sudo -u postgres psql -a -U postgres -d stifdb -f create_gtfs_table.sql
sudo -u postgres psql -a -U postgres -d stifdb -f copy_gtfs_table.sql
