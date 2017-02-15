#!/usr/bin/perl

require('common.pl');



my $type = $ARGV[0];
my $agency = $ARGV[1];

my $filename = $out_dir.'/get_routes_'.$type.'_'.$agency.'.html';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
binmode $fh, ":utf8";


$sql_list_agency = <<END_SQL;
SELECT routes.*
FROM routes
WHERE route_type = $type
AND routes.agency_id LIKE '$agency'
ORDER BY route_id

END_SQL

$query = $dbh->prepare($sql_list_agency);
$res = $query->execute();

print $fh $head_html;
#print $sql_list_agency;

print $fh <<END_HOME;
<p><a href="type_of_pt.html">Home</a>
 - <a href="get_agency_$type.html">$pt_type[$type]</a>
 - $agency
</p>

<table>
<tr><th>route_id</th><th>agency_id</th><th>route_short_name</th><th>route_short_name</th><th>route_long_name</th><th>desc</th><th>type</th><th>url</th><th>color</th><th>text_color</th></tr>
END_HOME

while (@data = $query->fetchrow_array()) {
my $route = $data[0];
my $cur_file0 = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_0.html';
my $cur_file1 = 'get_trips_'.$type.'_'.$agency.'_'.$route.'_1.html';


unless (-e $cur_file0 ) {
        print "creating $cur_file0\n";
#        system ('./get_trips.pl', $type, $agency, $route, 0) == 0
        $cmd=qq(./get_trips.pl $type $agency $route 0);
#       print "$test\n";
        $score0=qx($cmd);
        $nb_trips++;
        $moy_score0 += $score0;
#

#        or die "failed : $?";
};
unless (-e $cur_file1 ) {
        print "creating $cur_file1\n";
#        system ('./get_trips.pl', $type, $agency, $route, 1) == 0
        $cmd=qq(./get_trips.pl $type $agency $route 1);
#       print "$test\n";
        $score1=qx($cmd);
#        $nb_trips++;
        $moy_score1 += $score1;


#        or die "failed : $?";
};

print $fh <<END_HTML;
<tr style="color:#$data[8]; background-color:#$data[7]">
<td>$data[0]</td>
<td>$data[1]</td>
<td><a href="$cur_file0">$data[2] (aller) $score0 %</a></td>
<td><a href="$cur_file1">$data[2] (retour) $score1 %</a></td>
<td>$data[3]</td>
<td>$data[4]</td>
<td>$data[5]</td>
<td>$data[6]</td>
<td>$data[7]</td>
<td>$data[8]</td>
</tr>
END_HTML


}

print $fh "</table>";

print $fh $end_html;

close($fh);
