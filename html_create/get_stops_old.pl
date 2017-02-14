#!/usr/bin/perl

use DateTime;
require('common.pl');

use utf8;
binmode STDOUT, ":utf8";

my $type = $ARGV[0];
my $agency = $ARGV[1];
my $route = $ARGV[2];
my $direction = $ARGV[3];
my $trip = $ARGV[4];

my $filename = 'get_stops_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'_'.$trip.'.html';

open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

binmode $fh, ":utf8";

$sql = <<END_SQL;
SELECT stop_name,stops.stop_id,stop_lat,stop_lon
FROM stop_times,stops
WHERE stop_times.trip_id LIKE '$trip'
AND stop_times.stop_id = stops.stop_id

END_SQL

#print $sql;
$query = $dbh->prepare($sql);
my $start = DateTime->now;
$res = $query->execute();
my $end = DateTime->now;
my $elapsedtime =($end->subtract_datetime($start))->seconds();
print "SQL execution time : $elapsedtime s\n";


while (@data = $query->fetchrow_array()) {
    push @reduce_stop, $data[1];
    $stop_name{$data[1]}=$data[0];
    $stop_lat{$data[1]}=$data[2];
    $stop_lon{$data[1]}=$data[3];
}

$grad=gradient(1, 99);
$color_sim='';
$color_dist='';


print $fh $head_html;

print $fh <<END_HTML;
<iframe name="hide" style="display: None;"></iframe>
<table>
<tr><th>name</th><th>OSM?</th><th>ajout</th><th>?</th></tr>

END_HTML


foreach my $data (@reduce_stop) {
    $result = get_nearest_stops($data);

my $l = $stop_lon{$data}-0.001;
my $r = $stop_lon{$data}+0.001;
my $b = $stop_lat{$data}-0.001;
my $t = $stop_lat{$data}+0.001;

if ($result eq 'no') {

my $url = "http://localhost:8111/add_node?lat=$stop_lat{$data}&lon=$stop_lon{$data}&addtags=highway=bus_stop%7Cname=$stop_name{$data}";
$anchor = '<a href="'.$url.'" target="hide">ajouter arrêt</a>';
} else {
$anchor = '';
}

my $urlzone = "http://localhost:8111/load_and_zoom?left=$l&right=$r&top=$t&bottom=$b";
$zone = '<a href="'.$urlzone.'" target="hide">zoom JOSM</a>';

my $url_analyze = "/cgi-bin/analyze.pl?lat=$stop_lat{$data}&lon=$stop_lon{$data}";
$analyze = '<a href="'.$url_analyze.'">analyze</a>';


print $fh <<END_HTML;
<tr>
<td $color_sim>$stop_name{$data}</td>
<td $color_dist>$result</td>
<td>$anchor</td>
<td>$zone $analyze</td>
</tr>
END_HTML

}

print $fh "</table>";



print $fh $end_html;
close($fh);


sub get_nearest_stops {
        my ($stop) = @_;



if ($type eq '3') {
$sql = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,nodes.geom) AS dist,nodes.tags -> 'name' AS osmname, similarity (stop_name, nodes.tags -> 'name') AS simil
FROM stops, nodes
WHERE stops.stop_id = '$stop'
AND nodes.tags -> 'highway' = 'bus_stop'
AND ST_DWithin(stops.geom, nodes.geom, 0.1/111.325)
ORDER BY dist
LIMIT 10

END_SQL
} else {
$sql = <<END_SQL;

SELECT stop_name,stops.stop_id,ST_Distance_Sphere(stops.geom,nodes.geom) AS dist,nodes.tags -> 'name' AS osmname, similarity (stop_name, nodes.tags -> 'name') AS simil
FROM stops, nodes
WHERE stops.stop_id = '$stop'
-- AND (nodes.tags -> 'railway' = 'station'
--OR nodes.tags -> 'railway' = 'halt'
--OR nodes.tags -> 'railway' = 'tram_stop'
--OR nodes.tags ? 'public_transport' )
AND ST_DWithin(stops.geom, nodes.geom, 0.3/111.325)
ORDER BY simil
LIMIT 10

END_SQL
}

$query = $dbh->prepare($sql); $res=$query->execute();

while (@data = $query->fetchrow_array()) {
        my $dist = $data[2];
        my $simil = $data[4];
        if (($simil == 1) || ($dist < 200)) {
#print "data[".scalar(@data)."]:".join('|',@data)."\n";


$sim=sprintf("%.0f", $simil*100);
$meter=sprintf("%.0f", $dist);
$color_sim='style="background-color:#'.$grad->($sim).'";';
$color_dist='style="background-color:#'.$grad->(100-$meter).'";';

return "$data[3] (similaire à $sim%) - distance $meter m\n";
        }
}

$color_sim='style="background-color:#FF0000";';
$color_dist='style="background-color:#FF0000";';
return "no";
}



sub gradient {
    my ( $min, $max ) = @_;

    my $middle = ( $min + $max ) / 2;
    my $scale = 255 / ( $middle - $min );

    return sub {
        my $num = shift;
        return "FF0000" if $num <= $min;    # lower boundry
        return "00FF00" if $num >= $max;    # upper boundary

        if ( $num < $middle ) {
            return sprintf "FF%02X00" => int( ( $num - $min ) * $scale );
        }
        else {
            return
              sprintf "%02XFF00" => 255 - int( ( $num - $middle ) * $scale );
        }
    };
}
