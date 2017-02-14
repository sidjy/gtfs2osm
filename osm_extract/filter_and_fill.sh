#!/bin/sh

osmconvert ile-de-france-latest.osm.pbf --out-o5m >idf.o5m
#osmfilter idf.o5m --keep="public_transport= highway=bus_stop" > result.osm
osmfilter idf.o5m --hash-memory=240-30-2 --keep="public_transport= or highway=bus_stop or railway=halt or railway=station or railway=tram_stop or amenity=bus_station or route_master= or route=bus or route=train" > result.osm
rm idf.o5m
osmconvert result.osm --out-pbf >result.osm.pbf
rm result.osm
rm result_osmosis.txt
osmosis --read-pbf result.osm.pbf --log-progress --write-pgsql database=stifdb user=postgres password=newpassword >result_osmosis.txt 2>&1
