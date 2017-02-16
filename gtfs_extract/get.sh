#!/bin/bash

source ../config.sh

rm $gtfs_dir/*

echo `date` > $gtfs_dir/download_timestamp.txt
wget $gtfs_url -O $gtfs_dir/gtfs.zip
unzip $gtfs_dir/gtfs.zip -d $gtfs_dir

result=$gtfs_dir/copy_gtfs_table.sql

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
