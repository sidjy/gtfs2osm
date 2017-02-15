#!/bin/bash

source ./config.sh

psql -a --username=$dbuser --host=$dbhost --command="drop database if exists $dbname;"
psql -a --username=$dbuser --host=$dbhost --command="create database $dbname"
psql -a --username=$dbuser --host=$dbhost --dbname=$dbname --command="create extension hstore; create extension postgis;"


