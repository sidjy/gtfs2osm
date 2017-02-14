#!/usr/bin/perl

use Pg::hstore;
require('common.pl');


my $type = $ARGV[0];
my $agency = $ARGV[1];
my $route = $ARGV[2];
my $direction = $ARGV[3];

my $filename = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'.html';

open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";


$sql = <<END_SQL;
SELECT DISTINCT agency_name,route_short_name,trip_headsign,stop_name,stops.stop_id,stop_sequence,direction_id,trips.trip_id,ignore_trips
FROM agency,routes,trips,stop_times,stops
WHERE agency.agency_id = routes.agency_id
AND routes.route_id = trips.route_id
AND trips.trip_id = stop_times.trip_id
AND stop_times.stop_id = stops.stop_id
AND trips.route_id LIKE '$route'
AND direction_id = $direction
ORDER BY route_short_name, trip_headsign, stop_sequence

END_SQL

#print $sql;
my $inverse_dir=1-$direction;
my $inv_filename = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_'.$inverse_dir.'.html';


$query = $dbh->prepare($sql);
print "query:\n";
$res = $query->execute();
print "ok\n";

print $fh $head_html;

print $fh <<END_HOME;
<p><a href="type_of_pt.html">Home</a>
 - <a href="get_agency_$type.html">$pt_type[$type]</a>
 - <a href="get_routes_$type_$agency.html">$agency</a>
 - $route $direction
</p>
<p><a href="$inv_filename">Inverser la direction</a></p>
<p>Seuls les parcours maitres sont affichés (les autres sont des sous-parcours)</p>

<table><tr><th>trip_id</th><th>trip_headsign</th></tr>

END_HOME


my %HoA = ();
my %get_ID = ();
my $once=1;

while (@data = $query->fetchrow_array()) {
#$data[2] is trip_headsign and $data[4] is stop_id
#$data[8] is ignore_trips hstore
        push @{ $HoA{$data[2]} }, $data[4];
        $get_ID{$data[2]}=$data[7];
	if ($once) {
		$once=0;
		print "try to get\n";
		my $ignore_list_ref=Pg::hstore::decode($data[8]);
		%ignore_list = %$ignore_list_ref;
		print "got ".keys (%ignore_list)." entries from db\n";

	};

}

foreach my $trip (keys %HoA) {
        push @list_trip_tmp, $trip;
};

@list_trip = sort { scalar @{  $HoA{$b} } cmp scalar @{ $HoA{$a} } } @list_trip_tmp;

print "Full list of trips for $route_name, direction $direction:\n";
print "list_trip[".scalar(@list_trip)."]:".join('|',@list_trip)."\n";

foreach my $i (0 .. $#list_trip) {
  foreach my $j ($i+1 .. $#list_trip) {
        unless ($ignore_list{$list_trip[$j]} eq 'yes') {
                if (is_a_subarray_of (\@{ $HoA{$list_trip[$j]} }, \@{ $HoA{$list_trip[$i]} }) eq 'yes') {
                        $ignore_list{$list_trip[$j]}='yes';
                }
        }
  }
}

foreach my $i (0 .. $#list_trip) {
        unless ($ignore_list{$list_trip[$i]} eq 'yes') {
        push @reduce_trip, $list_trip[$i];
  }
}

#print "Reduced list of trips for $route_name, direction $direction:\n";
#print "reduce_trip[".scalar(@reduce_trip)."]:".join('|',@reduce_trip)."\n";

$dbh->do("update routes set ignore_trips=? where route_id like ?", undef,
Pg::hstore::encode(\%ignore_list),$route);


foreach my $trip (@list_trip) {


unless ($ignore_list{$trip} eq 'yes') {
my $cur_file = 'get_stops_'.$type.'_'.$agency.'_'.$route.'_'.$direction.'_'.$get_ID{$trip}.'.html';

print $fh <<END_HTML;
<tr>
<td>$get_ID{$trip}</td>
<td><a href="$cur_file">$trip</a></td>
</tr>
END_HTML

unless (-e $cur_file ) {
        print "creating $cur_file\n";
        system ('./get_stops.pl', $type, $agency, $route, $direction, $get_ID{$trip}) == 0
        or die "failed : $?";
};


}

}

print $fh "</table>";



print $fh $end_html;
close($fh);

# retourne yes ou no selon que arr1 est identique à
# arr2 ou bien un sous ensemble strict de arr2, ou
# non
sub is_a_subarray_of {
        my ($arr1, $arr2) = @_;
        my @array1 = @{ $arr1 };
        my @array2 = @{ $arr2 };

#print "array1[".scalar(@array1)."]:".join('|',@array1)."\n";
#print "array2[".scalar(@array2)."]:".join('|',@array2)."\n";

if( @array1 ~~ @array2 ) {
#print "isequal\n";
    return "yes";
}

        my (@union, @intersection, @difference);
        my %count = ();
        foreach my $element (@array1, @array2) { $count{$element}++ }
        foreach my $element (keys %count) {
                push @union, $element;
                push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
        }

#print "union[".scalar(@union)."]:".join('|',@union)."\n";
#print "intersection[".scalar(@intersection)."]:".join('|',@intersection)."\n";


# arr1 est un sous array de arr2 si et seulement si l'intersection et arr1 on le même cardinal
# (l'ordre change peut être)
if( scalar(@array1) == scalar(@intersection) ) {
#print "isincluded\n";



    return "yes";
}

        return "no";
}

