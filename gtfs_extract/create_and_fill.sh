#!/bin/bash

source ../config.sh

psql -a --username=$dbuser --dbname=$dbname --host=$dbhost -f create_gtfs_table.sql
psql -a --username=$dbuser --dbname=$dbname --host=$dbhost -f $gtfs_dir/copy_gtfs_table.sql


