#!/bin/bash

gtfs_url='https://opendata.stif.info/explore/dataset/offre-horaires-tc-gtfs-idf/files/f24cf9dbf6f80c28b8edfdd99ea16aad/download/'
gtfs_dir='/media/Downloads/osm/gtfs/test'
rm $gtfs_dir/*

wget $gtfs_url -O $gtfs_dir/gtfs.zip
unzip $gtfs_dir/gtfs.zip -d $gtfs_dir

result='copy_gtfs_table.sql'

if [ -e $result ]
	then rm $result
fi

for file in $gtfs_dir/*.txt; do
	head=`head -1 $file`
	head=${head::-1}
	table=$(basename "$file")
	table="${table%.*}"
	echo $table

	cat <<EOT >> $result
copy $table ($head)
from '$file'
with delimiter ',' csv header;

EOT
done
