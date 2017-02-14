DROP DATABASE stifdb;
CREATE DATABASE stifdb;
CREATE EXTENSION postgis;

drop table if exists agency;
drop table if exists stops;
drop table if exists routes;
drop table if exists route_types;
drop table if exists directions;
drop table if exists trips;
drop table if exists stop_times;
drop table if exists calendar;
drop table if exists pickup_dropoff_types;
drop table if exists calendar_dates;
drop table if exists fare_attributes;
drop table if exists fare_rules;
drop table if exists shapes;
drop table if exists frequencies;
drop table if exists transfer_types;
drop table if exists transfers;
drop table if exists feed_info;
drop table if exists payment_methods;

