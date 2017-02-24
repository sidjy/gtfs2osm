#!/usr/bin/perl

#use locale;
use Encode qw(decode);
use DateTime;
use URI::Escape;
require('common.pl');

use utf8;
binmode STDOUT, ":utf8";

$nb_stops=0;
$moy_simil=0;
$moy_dist=0;
$dt=DateTime->today();

my $type = $ARGV[0];
my $agency = $ARGV[1];
my $route = $ARGV[2];
my $direction = $ARGV[3];
my $trip = $ARGV[4];
my $p_trip = $ARGV[5];

$p_trip= decode("utf-8", $p_trip);

($agency_name,$route_short_name,$first_stop,$last_stop,$color)=split(/\|/,$p_trip);
$first_stop=pretty_stop($first_stop);
$last_stop=pretty_stop($last_stop);

my $filename = $out_dir.'/get_stops_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'_'.$trip;
my $html_fn = $filename . '.html';
#my $geojson_fn = $filename . '.json';

open(my $fh, '>', $html_fn) or die "Could not open file '$html_fn' $!";
#open(my $fhjson, '>', $geojson_fn) or die "Could not open file '$geojson_fn' $!";

binmode $fh, ":utf8";
#binmode $fhjson, ":utf8";

$sql = <<END_SQL;
SELECT stop_name,stops.stop_id,stop_lat,stop_lon,arrival_time, zder_id_ref_a
FROM stop_times,stops,stop_extensions
WHERE stop_times.trip_id LIKE '$trip'
AND stop_times.stop_id = stops.stop_id
AND stop_extensions.stop_id = stops.stop_id
ORDER BY stop_sequence
END_SQL

$sql_line = <<END_SQL;
SELECT ST_AsGeoJSON(ST_MakeLine(the_stops.geom))
FROM (SELECT geom
FROM stop_times,stops
WHERE stop_times.trip_id LIKE '$trip'
AND stop_times.stop_id = stops.stop_id
ORDER BY stop_sequence) AS the_stops;
END_SQL

$sql_start= <<END_SQL;
SELECT ST_AsGeoJSON(geom)
FROM stop_times,stops
WHERE stop_times.trip_id LIKE '$trip'
AND stop_times.stop_id = stops.stop_id
ORDER BY stop_sequence LIMIT 1;
END_SQL

#print $sql;
$query = $dbh->prepare($sql);
$query_line = $dbh->prepare($sql_line);
$query_start = $dbh->prepare($sql_start);
my $start = DateTime->now;
$res = $query->execute();
$res2 = $query_line->execute();
$res3 = $query_start->execute();
my $end = DateTime->now;
my $elapsedtime =($end->subtract_datetime($start))->seconds();
#print "SQL execution time : $elapsedtime s\n";

my ($linejson) = $query_line->fetchrow_array();
my ($startjson) = $query_start->fetchrow_array();

while (@data = $query->fetchrow_array()) {
    push @reduce_stop, $data[1];
    $stop_name{$data[1]}=pretty_stop($data[0]);
    $stop_lat{$data[1]}=$data[2];
    $stop_lon{$data[1]}=$data[3];
    $stop_time{$data[1]}=$data[4];
#specific stif
    $stop_id_stif{$data[1]}=$data[5];
}

$grad=gradient(1, 99);
$color_sim='';
$color_dist='';

my $osrm_url = 'http://router.project-osrm.org/match/v1/driving/';

print $fh $head_html_leaflet;

my $route_fname='get_routes_'.$type.'_'.$agency.'.html';
my $trip_fname = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'.html';

my $r_name=$pt_type[$type].' '.$route_short_name.' : '.$first_stop.' → '.$last_stop;
#my $r_name=$pt_type[$type].' '.$route_short_name.' : '.$first_stop.' -> '.$last_stop;
my $r_from=$first_stop;
my $r_to=$last_stop;
my $r_network=$agency_name;
my $r_ref=$route_short_name;
my $r_color='#'.$color;
my $osm=<<END_OSM;
<?xml version='1.0' encoding='UTF-8'?>
<osm version="0.6" upload="false">
<relation id="-1">
<tag k="type" v="route"/>
<tag k="route" v="bus"/>
<tag k="public_transport:version" v="2"/>
<tag k="name" v="$r_name"/>
<tag k="from" v="$r_from"/>
<tag k="to" v="$r_to"/>
<tag k="ref" v="$r_ref"/>
<tag k="network" v="$r_network"/>
<tag k="colour" v="$r_color"/>
</relation>
</osm>
END_OSM

my $enc_osm=uri_escape_utf8($osm);

my $url_r="http://localhost:8111/load_data?new_layer=false&data=$enc_osm";

print $fh <<END_HOME;
<p><a href="type_of_pt.html">Home</a>
 - <a href="get_agency_$type.html">$pt_type[$type]</a>
 - <a href="$route_fname">$agency</a>
 - <a href="$trip_fname">$route $direction</a>
 $trip
</p>
<p><button onclick="get_itin()">Itinéraire</button></p>
<p id="load_josm"></p>
<table id="osm"><tr>
<th><a href="$url_r" target="hide">Créer la relation route dans JOSM</a> (attention aux doublons)
</th></tr>
<tr><td>name:$r_name</td></tr>
<tr><td>from:$r_from</td></tr>
<tr><td>to:$r_to</td></tr>
<tr><td>network:$r_network</td></tr>
<tr><td>ref:$r_ref</td></tr>
<tr><td>colour:$r_color</td></tr>
</table>
END_HOME

print $fh <<END_HTML;
<iframe name="hide" style="display: None;"></iframe>
<div>
<div style="width: 640px; float: left;">
<table id="stops" class="main">
<tr><th>name</th><th>OSM?</th><th>ajout</th><th>?</th></tr>

END_HTML


foreach my $data (@reduce_stop) {
    $result = get_nearest_stops($data);

$osrm_url = $osrm_url.$stop_lon{$data}.','.$stop_lat{$data}.';';
my ($h,$m,$s) = split(/:/,$stop_time{$data});
$dt->set(hour=>$h, minute=>$m, second=>$s);
$timestamps = $timestamps.$dt->epoch().';';
$radius=$radius.'20;';

my $l = $stop_lon{$data}-0.0003;
my $r = $stop_lon{$data}+0.0003;
my $b = $stop_lat{$data}-0.0003;
my $t = $stop_lat{$data}+0.0003;

if ($result eq 'no') {

my $url = "http://localhost:8111/add_node?lat=$stop_lat{$data}&lon=$stop_lon{$data}&addtags=highway=bus_stop%7Cpublic_transport=platform%7Cname=$stop_name{$data}";

$anchor = qq(<a href="$url" target="hide">ajouter arrêt</a>);
} elsif ($sim < 10) {

my $url = "http://localhost:8111/load_and_zoom?left=$l&right=$r&top=$t&bottom=$b&addtags=highway=bus_stop%7Cpublic_transport=platform%7Cname=$stop_name{$data}&select=node$node_id";

$anchor = qq(<a href="$url" target="hide">compléter arrêt</a>);

} else {
$anchor = '';
};

my $oclick = "map.fitBounds([[$b,$l],[$t,$r]]);";
my $urlzone = "http://localhost:8111/load_and_zoom?left=$l&right=$r&top=$t&bottom=$b";
$zone = qq(<a href="$urlzone" onclick="$oclick" target="hide">zoom JOSM</a>);

# test
my $butoclick=$oclick."window.open(".qq('$urlzone','hide').");";
$anchor = qq(<button class="cpy" data-clipboard-text="public_transport=platform ref:FR:STIF=$stop_id_stif{$data}" onclick="$butoclick">Copy josm data: Ctrl+Maj+V</button>);
# fin test

print $fh <<END_HTML;
<tr>
<td $color_sim>$stop_name{$data} [$stop_id_stif{$data}]</td>
<td $color_dist>$result</td>
<td>$anchor</td>
<td>$zone</td>
</tr>
END_HTML

}

chop $osrm_url;
chop $timestamps;
chop $radius;

$osrm_url .= '?timestamps='.$timestamps;
$osrm_url .= '&radiuses='.$radius;
$osrm_url .= '&overview=full&geometries=geojson&generate_hints=false&annotations=true';

#$osrm_url=uri_escape_utf8($osrm_url);



print $fh <<END_HTML;
</table>
</div>
<div id="map" style="width: 640px; height: 400px; float: left;">
</div></div>

END_HTML

print $fh <<ENDJSON;

<script type='text/javascript'>

var btns = document.querySelectorAll('.cpy');
    var clipboard = new Clipboard(btns);
    clipboard.on('success', function(e) {
        console.log(e);
    });
    clipboard.on('error', function(e) {
        console.log(e);
    });


// couche "osmfr" 
var osmfr = L.tileLayer('http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', 
{
    attribution: 'donn&eacute;es &copy; <a href="http://osm.org/copyright">OpenStreetMap</a>/ODbL - rendu cquest',
    minZoom: 1,
    maxZoom: 20
});
  
// liste des couches de base
var baseMaps = {
    "Rendu FR": osmfr
};
var geojsonFeature ={
  "type":"Feature",
  "geometry": {
	"type":"GeometryCollection",
	"geometries": [
	$linejson,
	$startjson]},

  "properties": {
	"name":"test"
  }
};


map = L.map('map', { center: [47.000,2.000], zoom: 10, layers: [osmfr] } );
json = L.geoJSON(geojsonFeature).addTo(map); 

var myStyle = {
    "color": "#ff7800",
    "weight": 5,
    "opacity": 0.65
};

var nodes = [];
var legs;
var loadurl="http://localhost:8111/load_object?referrers=true&objects=";


function get_itin() {
var geojsonLayer = new L.GeoJSON.AJAX("$osrm_url",{
	style:myStyle,
	middleware:function(data){
legs = data.matchings[0].legs;
for(var i in legs) {
nodes.push(legs[i].annotation.nodes);
}

for(i=0; i < nodes.length; i++){
for(j=0; j < nodes[i].length; j++) {
	loadurl += "n" + nodes[i][j] + ",";
}
}

document.getElementById("load_josm").innerHTML = '<a href="'+loadurl+'" target="hide">Load JOSM</a>';

		return data.matchings[0].geometry;
	}
});

geojsonLayer.addTo(map);
};



map.fitBounds(json.getBounds());
jj=json.getLayers()[0]._layers;

idx=Object.keys(jj)[0]

//debugger;
var decorator = L.polylineDecorator(jj[idx]._latlngs, 
{
    patterns: [
            {offset: 25, repeat: 50, symbol: L.Symbol.arrowHead({pixelSize: 15, pathOptions: 
{fillOpacity: 1, weight: 0}})}
        ]
}).addTo(map);

// ajout de l'échelle
L.control.scale().addTo(map);

</script>


ENDJSON


print $fh $end_html;
close($fh);
$moy_dist=$moy_dist/$nb_stops;
$moy_simil=$moy_simil/$nb_stops;
printf("%.0f\n", $moy_simil);


#close($fhjson);


sub get_nearest_stops {
        my ($stop) = @_;



if ($type eq '3') {
$sql = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,nodes.geom) AS dist,nodes.tags -> 'name' AS osmname, similarity (stop_name, nodes.tags -> 'name') AS simil, nodes.id
FROM stops, nodes
WHERE stops.stop_id = '$stop'
AND (nodes.tags -> 'highway' = 'bus_stop'
OR nodes.tags -> 'public_transport' = 'platform'
OR nodes.tags -> 'public_transport' = 'station'
OR nodes.tags -> 'amenity' = 'bus_station')
AND ST_DWithin(stops.geom, nodes.geom, 0.2/111.325)
ORDER BY dist
LIMIT 10

END_SQL

$sqlW = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,ways.linestring) AS dist,ways.tags -> 'name' AS osmname, similarity (stop_name, ways.tags -> 'name') AS simil, ways.id
FROM stops, ways
WHERE stops.stop_id = '$stop'
AND (ways.tags -> 'public_transport' = 'station'
OR ways.tags -> 'amenity' = 'bus_station')
AND ST_DWithin(stops.geom, ways.linestring, 0.2/111.325)
ORDER BY dist
LIMIT 10

END_SQL




} else {
$sql = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,nodes.geom) AS dist,nodes.tags -> 'name' AS osmname, similarity (stop_name, nodes.tags -> 'name') AS simil, nodes.id
FROM stops, nodes
WHERE stops.stop_id = '$stop'
AND (nodes.tags -> 'railway' = 'station'
OR nodes.tags -> 'railway' = 'halt'
OR nodes.tags -> 'railway' = 'tram_stop'
OR nodes.tags -> 'public_transport' = 'station' )
AND ST_DWithin(stops.geom, nodes.geom, 0.3/111.325)
ORDER BY dist
LIMIT 10

END_SQL

$sqlW = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,ways.linestring) AS dist,ways.tags -> 'name' AS osmname, similarity (stop_name, ways.tags -> 'name') AS simil, ways.id
FROM stops, ways
WHERE stops.stop_id = '$stop'
AND (ways.tags -> 'public_transport' = 'station'
OR ways.tags -> 'railway' = 'tram_stop'
OR ways.tags -> 'railway' = 'station'
OR ways.tags -> 'railway' = 'halt')
AND ST_DWithin(stops.geom, ways.linestring, 0.2/111.325)
ORDER BY dist
LIMIT 10

END_SQL

}

$query = $dbh->prepare($sql); $res=$query->execute();

while (@data = $query->fetchrow_array()) {
        my $dist = $data[2];
        my $simil = $data[4];
$sim=sprintf("%.0f", $simil*100);
$meter=sprintf("%.0f", $dist);

$nb_stops++;
$moy_dist+=$meter;
$moy_simil+=$sim;

        if (($simil == 1) || ($dist < 200)) {
#print "data[".scalar(@data)."]:".join('|',@data)."\n";
$node_id = $data[5];

$dist_pourcent=(200-$meter)/2;
$color_sim='style="background-color:#'.$grad->($sim).'";';
$color_dist='style="background-color:#'.$grad->($dist_pourcent).'";';

return "$data[3] (node similaire à $sim%) - distance $meter m\n";
        }
}

$query = $dbh->prepare($sqlW); $res=$query->execute();

while (@data = $query->fetchrow_array()) {
        my $dist = $data[2];
        my $simil = $data[4];
$sim=sprintf("%.0f", $simil*100);
$meter=sprintf("%.0f", $dist);

$nb_stops++;
$moy_dist+=$meter;
$moy_simil+=$sim;

        if (($simil == 1) || ($dist < 200)) {
#print "data[".scalar(@data)."]:".join('|',@data)."\n";
$node_id = $data[5];

$dist_pourcent=(200-$meter)/2;
$color_sim='style="background-color:#'.$grad->($sim).'";';
$color_dist='style="background-color:#'.$grad->($dist_pourcent).'";';

return "$data[3] (way similaire à $sim%) - distance $meter m\n";
        }
}

$color_sim='style="background-color:#FF0000";';
$color_dist='style="background-color:#FF0000";';
return "no";
}



sub pretty_stop {
        my ($stop) = @_;
	$stop =~ s/(\b)(\w{1,3})/$1\L$2\E/g; #minuscule les mots < 3 lettres
	$stop =~ s/(\b)(\w)(\w{3,})/$1\u$2\L$3\E/g;
	$stop =~ s/^(\w)/\u$1/; # majuscule 1er caractère
	$stop =~ s/(\b)rer/$1RER/; # majuscule certains mots
	$stop =~ s/(\b)cdg/$1CDG/; # majuscule certains mots
	$stop =~ s/(\b)st(\b)/$1St$2/; # majuscule certains mots
	$stop =~ s/(\b)ste(\b)/$1Ste$2/; # majuscule certains mots

	return $stop;
};








