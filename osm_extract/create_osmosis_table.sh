#!/bin/sh

source ../config.sh

psql -a --username=$dbuser --dbname=$dbname --host=$dbhost  -f pgsnapshot_schema_0.6.sql
psql -a --username=$dbuser --dbname=$dbname --host=$dbhost  -f pgsnapshot_schema_0.6_linestring.sql


