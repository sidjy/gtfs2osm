#!/bin/bash

source ../config.sh

pushd $osm_dir

# récupère le delta et l'insère dans la base
osmosis --rri workingDirectory=. --wpc database=$dbname host=$dbhost user=$dbuser password=$dbpwd >result_osmosis.txt 2>&1


popd
