#!/usr/bin/perl

use Encode qw(decode);
use DateTime;
use URI::Escape;
use Pg::hstore;
require('common.pl');

$| = 1;
#print "started\n";

use utf8;
binmode STDOUT, ":utf8";


$moy_score=0;
$nb_trips=0;

my $type = $ARGV[0];
my $agency = $ARGV[1];
my $route = $ARGV[2];
my $direction = $ARGV[3];

my $filename = $out_dir.'/get_trips_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'.html';

open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
binmode $fh, ":utf8";


$sql = <<END_SQL;
SELECT DISTINCT agency_name,route_short_name,trip_headsign,'s',stop_times.stop_id,stop_sequence,direction_id,trips.trip_id --,ignore_trips
FROM agency,routes,trips,stop_times
WHERE
trips.route_id LIKE '$route'
AND direction_id = $direction
AND agency.agency_id = routes.agency_id
AND routes.route_id = trips.route_id
AND trips.trip_id = stop_times.trip_id
--ORDER BY route_short_name, trip_headsign, stop_sequence

END_SQL

$sql_hash = <<END_SQL;
SELECT ignore_trips_$direction
FROM routes
WHERE
routes.route_id LIKE '$route'

END_SQL


#print $sql;
my $inverse_dir=1-$direction;
my $inv_filename = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_'.$inverse_dir.'.html';


$query = $dbh->prepare($sql);
$query2 = $dbh->prepare($sql_hash);


my $start = DateTime->now; 
$res = $query->execute();
my $end = DateTime->now;
my $elapsedtime =($end->subtract_datetime($start))->seconds();
#print "SQL execution time : $elapsedtime s\n";

my $start = DateTime->now; 
$res2 = $query2->execute();
my $end = DateTime->now;
my $elapsedtime =($end->subtract_datetime($start))->seconds();
#print "SQL get hash execution time : $elapsedtime s\n";


#print $fh $head_html;
print $fh $head_html_leaflet;

my $back_fname='get_routes_'.$type.'_'.$agency.'.html';

print $fh <<END_HOME;
<p><a href="type_of_pt.html">Home</a>
 - <a href="get_agency_$type.html">$pt_type[$type]</a>
 - <a href="$back_fname">$agency</a>
 - $route $direction
</p>
<p><a href="$inv_filename">Inverser la direction</a></p>
<p>Seuls les parcours maitres sont affichés (les autres sont des sous-parcours)</p>

<table id="trips" class="main"><tr><th>trip_id</th><th>trip_headsign</th><th>debut → fin</th><th>score</th></tr>

END_HOME


my ($dat) = $query2->fetchrow_array();
#print ":$dat\n";
my $ignore_list_ref=Pg::hstore::decode($dat);
%ignore_list = %$ignore_list_ref;
my $nb_ignore = scalar (keys (%ignore_list));
#print "got ".keys (%ignore_list)." cached entries from db\n";
#print "got $nb_ignore cached entries from db\n";


my %HoA = ();
my %get_ID = ();

while (@data = $query->fetchrow_array()) {
#$data[2] is trip_headsign and $data[4] is stop_id
        push @{ $HoA{$data[2]} }, $data[4];
        $get_ID{$data[2]}=$data[7];

}

foreach my $trip (keys %HoA) {
        push @list_trip_tmp, $trip;
};

@list_trip = sort { scalar @{  $HoA{$b} } <=> scalar @{ $HoA{$a} } || $a cmp $b } @list_trip_tmp;
my $nb_full = scalar (keys (@list_trip));
#print "got $nb_full trip entries from gtfs\n";


#print "Full list of trips for $route_name, direction $direction:\n";
#print "list_trip[".scalar(@list_trip)."]:".join("|",@list_trip)."\n";

#foreach my $j (0 .. $#list_trip) {
#print $j." : ".$list_trip[$j].'['.scalar @{  $HoA{$list_trip[$j]} }."]\n";
#};

foreach my $i (0 .. $#list_trip) {
  foreach my $j ($i+1 .. $#list_trip) {
#	print 'verify if '.$list_trip[$j].'['.scalar @{  $HoA{$list_trip[$j]} }.'] is a subtrip of '.$list_trip[$i].'['.scalar @{ $HoA{$list_trip[$i]} }."]\n";
        unless ($ignore_list{$list_trip[$j]} eq 'yes') {
                if ((($nb_full-$nb_ignore)>1) && is_a_subarray_of (\@{ $HoA{$list_trip[$j]} }, \@{ $HoA{$list_trip[$i]} }) eq 'yes') {
#			print $list_trip[$j].' is a subtrip of '.$list_trip[$i].", ignoring it\n";
                        $ignore_list{$list_trip[$j]}='yes';
			$nb_ignore++;
                }
        }
  }
}

foreach my $i (0 .. $#list_trip) {
        unless ($ignore_list{$list_trip[$i]} eq 'yes') {
        push @reduce_trip, $list_trip[$i];
  }
}

#print "Reduced list of trips for $route, direction $direction:\n";
#print "reduce_trip[".scalar(@reduce_trip)."]:".join('|',@reduce_trip)."\n";

$dbh->do("update routes set ignore_trips_".$direction."=? where route_id like ?", undef,
Pg::hstore::encode(\%ignore_list),$route);
#print "put ".keys (%ignore_list)." entries into db\n";


foreach my $trip (@list_trip) {

unless ($ignore_list{$trip} eq 'yes') {

my $cur_file = 'get_stops_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'_'.$get_ID{$trip}.'.html';

my $sql_first_last = <<END_SQL;

(SELECT stop_name
FROM stop_times,stops
WHERE stop_times.trip_id LIKE '$get_ID{$trip}'
AND stop_times.stop_id = stops.stop_id
ORDER BY stop_sequence ASC
LIMIT 1)
UNION ALL
(SELECT stop_name
FROM stop_times,stops
WHERE stop_times.trip_id LIKE '$get_ID{$trip}'
AND stop_times.stop_id = stops.stop_id
ORDER BY stop_sequence DESC
LIMIT 1)
UNION ALL
(SELECT CAST(COUNT(stop_id) AS text)
FROM stop_times
WHERE stop_times.trip_id LIKE '$get_ID{$trip}')
UNION ALL
(SELECT agency_name FROM agency
WHERE agency_id LIKE '$agency'
LIMIT 1)
UNION ALL
(SELECT route_short_name FROM routes
WHERE route_id LIKE '$route'
LIMIT 1)
UNION ALL
(SELECT route_color FROM routes
WHERE route_id LIKE '$route'
LIMIT 1)

END_SQL

my $query3 = $dbh->prepare($sql_first_last);
my $res = $query3->execute();

($first_stop) = $query3->fetchrow_array();
($last_stop) = $query3->fetchrow_array();
($number) = $query3->fetchrow_array();
($agency_name) = $query3->fetchrow_array();
($route_short_name) = $query3->fetchrow_array();
($color) = $query3->fetchrow_array();

$first_stop=ucfirst($first_stop);
$last_stop=ucfirst($last_stop);


#print "$first_stop → $last_stop ($number)\n";

unless (defined($rm_first)) {
	$rm_first = $first_stop;
};
unless (defined($rm_last)) {
	$rm_last = $last_stop;
};

$p_trip=join('|',($agency_name,$route_short_name,$first_stop,$last_stop,$color));

unless (-e $cur_file ) {
#        print "creating $cur_file\n";
        $cmd=qq(./get_stops.pl $type $agency $route $direction $get_ID{$trip} "$p_trip");
#	print "$test\n";
        $score=qx($cmd);
	$nb_trips++;
	$moy_score += $score;
#        system ('./get_stops.pl', $type, $agency, $route, $direction, $get_ID{$trip}, $p_trip) == 0
#        or die "failed : $?";
};


print $fh <<END_HTML;
<tr>
<td>$get_ID{$trip}</td>
<td><a href="$cur_file">$trip</a></td>
<td>$first_stop → $last_stop ($number)</td>
<td>$score %</td>
</tr>
END_HTML



}

}

print $fh "</table>";

if ($direction == 0) {
my $pt = $pt_type[$type];
my $pt_osm = $pt_type_osm[$type];
my $r_name=$pt.' '.$route_short_name.' : '.$rm_first.' ↔ '.$rm_last;
my $r_network=$agency_name;
my $r_ref=$route_short_name;
my $r_color='#'.$color;

my $sql_find_rm=<<END_SQL;
SELECT COUNT(*) FROM relations
WHERE (tags->'type' = 'route_master'
and tags->'route_master' = '$pt_osm'
and tags->'ref:FR:STIF:ExternalCode_Line' = '$route');
END_SQL

#recherche sur ref
#and tags->'ref' = '$route_short_name');

my $count_rm = $dbh->selectrow_array($sql_find_rm);

#print $sql_find_rm."\n";
#print $count_rm."\n";

my $osm=<<END_OSM;
<?xml version='1.0' encoding='UTF-8'?>
<osm version="0.6" upload="false">
<relation id="-1">
<tag k="type" v="route_master"/>
<tag k="route_master" v="$pt_osm" />
<tag k="public_transport:version" v="2"/>
<tag k="name" v="$r_name"/>
<tag k="ref" v="$r_ref"/>
<tag k="ref:FR:STIF:ExternalCode_Line" v="$route"/>
<tag k="network" v="$r_network"/>
<tag k="colour" v="$r_color"/>
</relation>
</osm>
END_OSM

my $enc_osm=uri_escape_utf8($osm);
my $url_r="http://localhost:8111/load_data?new_layer=false&data=$enc_osm";

if ($count_rm == 0) {


my $sql_find_rm=<<END_SQL;
SELECT id FROM relations
WHERE (tags->'type' = 'route_master'
and tags->'route_master' = '$pt_osm'
and tags->'ref' = '$route_short_name');
END_SQL

my $id_rm = $dbh->selectrow_array($sql_find_rm);

if ($id_rm) {
$link_id = qq(<p><a href="http://api.openstreetmap.org/api/0.6/relation/$id_rm">$id_rm</a></p>);
};

print $fh <<END_HTML;
$link_id
<p id="load_josm"></p>
<table id="osm"><tr>
<th><a href="$url_r" target="hide">Créer la relation route_master dans JOSM</a> (attention aux doublons)
</th></tr>
<tr><td>name: $r_name</td></tr>
<tr><td>network: $r_network</td></tr>
<tr><td>ref: $r_ref</td></tr>
<tr><td>ref:FR:STIF:ExternalCode_Line: $route</td></tr>
<tr><td>colour: $r_color</td></tr>
</table>
END_HTML
} else {

my $sql_find_rm=<<END_SQL;
SELECT id FROM relations
WHERE (tags->'type' = 'route_master'
and tags->'route_master' = '$pt_osm'
and tags->'ref:FR:STIF:ExternalCode_Line' = '$route');
END_SQL

#recherche sur ref
#and tags->'ref' = '$route_short_name');

my $id_rm = $dbh->selectrow_array($sql_find_rm);

my $sql_geom=<<END_SQL;
(select ST_AsGeoJSON(geom) from nodes where id in
	(select member_id from relation_members where
		member_type = 'N' and
		relation_id in (select member_id from relation_members where member_type = 'R' and relation_id = '$id_rm')
	)
)
union
(select ST_AsGeoJSON(linestring) from ways where id in
	(select member_id from relation_members where
		member_type = 'W' and
		relation_id in (select member_id from relation_members where member_type = 'R' and relation_id = '$id_rm')
	)
);
END_SQL

@result = @{ $dbh->selectcol_arrayref($sql_geom); };
$json_obj = join(',',@result);
$json_obj = '{ "type": "GeometryCollection", "geometries": ['.$json_obj.']}';

$full_url = qq("http://api.openstreetmap.org/api/0.6/relation/$id_rm/full");

print $fh <<END_HTML;
<p>Il y a $count_rm relation route_master dans OpenStreetmap !<p>

<p><a href="http://api.openstreetmap.org/api/0.6/relation/$id_rm/full">$id_rm</a></p>
<p><a href="http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/relation/$id_rm">charger JOSM</a></p>

<div id="map" style="width: 640px; height: 400px; float: left;"></div>
<script type='text/javascript'>
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
map = L.map('map', { center: [47.000,2.000], zoom: 10, layers: [osmfr] } );

var myStyle = {
    "color": "$r_color",
    "weight": 5,
    "opacity": 0.65
};

var myData = $json_obj;

json = L.geoJSON(myData, {
    style: myStyle
}).addTo(map);

map.fitBounds(json.getBounds());



</script>

END_HTML

};

};

print $fh $end_html;
close($fh);

$moy_score = $moy_score / $nb_trips;
printf("%.0f\n", $moy_score);


# retourne yes ou no selon que arr1 est identique à
# arr2 ou bien un sous ensemble strict de arr2, ou
# non
sub is_a_subarray_of {
        my ($arr1, $arr2) = @_;
        my @array1 = @{ $arr1 };
        my @array2 = @{ $arr2 };

#print "array1[".scalar(@array1)."]:".join('|',@array1)."\n";
#print "array2[".scalar(@array2)."]:".join('|',@array2)."\n";

#if( @array1 ~~ @array2 ) {
#print "isequal\n";
#    return "yes";
#}

        my (@union, @intersection, @difference);
        my %count = ();
        foreach my $element (@array1, @array2) { $count{$element}++ }
        foreach my $element (keys %count) {
                push @union, $element;
                push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
        }

#print "union[".scalar(@union)."]:".join('|',@union)."\n";
#print "intersection[".scalar(@intersection)."]:".join('|',@intersection)."\n";

if( scalar(@union) == scalar(@intersection) ) {
	return "yes"; #egalité des 2 arrays
}

# arr1 est un sous array de arr2 si et seulement si l'intersection et arr1 on le même cardinal
# (l'ordre change peut être). attention aux elements doublons
if( scalar(@array1) == scalar(@intersection) ) {

#	if( scalar(@array1) == scalar(@array2) ) {
		
#		return "yes"; #egalité des 2 arrays
#	} else {

#print "array1[".scalar(@array1)."]:".join('|',@array1)."\n";
#print "array2[".scalar(@array2)."]:".join('|',@array2)."\n";

		return "yes";
#	}
}

#print "isnotincluded\n";

        return "no";
}

