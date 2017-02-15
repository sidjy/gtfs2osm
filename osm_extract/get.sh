#!/bin/bash

source ../config.sh

rm $osm_dir/*
wget $osm_url -O $osm_dir/latest.osm.pbf

