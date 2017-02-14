#!/bin/bash

pushd /media/Downloads/osm/gtfs/geofabrik/

./get.sh 2>&1 >result.log
./create_osmosis_table.sh 2>&1 >>result.log
./filter_and_fill.sh 2>&1 >>result.log

popd
