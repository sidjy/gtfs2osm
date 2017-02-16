#!/bin/bash

source ../config.sh

rm $osm_dir/*
echo `date` > $osm_dir/download_timestamp.txt
wget $osm_url -O $osm_dir/latest.osm.pbf

