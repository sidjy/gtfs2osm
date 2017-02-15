#!/bin/sh

source ../config.sh


pushd $osm_dir

osmconvert latest.osm.pbf --out-o5m >latest.o5m
#osmfilter idf.o5m --keep="public_transport= highway=bus_stop" > result.osm
osmfilter latest.o5m --hash-memory=240-30-2 --keep="public_transport= or highway=bus_stop or railway=halt or railway=station or railway=tram_stop or amenity=bus_station or route_master= or route=bus or route=train" > reduced.osm
rm latest.o5m
osmconvert reduced.osm --out-pbf >reduced.osm.pbf
rm reduced.osm
rm result_osmosis.txt
osmosis --read-pbf reduced.osm.pbf --log-progress --write-pgsql database=$dbname host=$dbhost user=$dbuser password=$dbpwd >result_osmosis.txt 2>&1

popd
