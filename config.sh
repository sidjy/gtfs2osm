#postgis parameters
dbname=stifdb
dbhost=localhost
dbuser=postgres
dbpwd=newpassword

export PGPASSWORD=$dbpwd

#gtfs download url and working directory
gtfs_url='https://opendata.stif.info/explore/dataset/offre-horaires-tc-gtfs-idf/files/f24cf9dbf6f80c28b8edfdd99ea16aad/download/'
gtfs_dir='/media/Downloads/osm/gtfs/test'

#osm download url and working directory
osm_url='http://download.geofabrik.de/europe/france/ile-de-france-latest.osm.pbf'
osm_dir='/media/Downloads/osm/gtfs/geofabrik/'

