#!/usr/bin/perl

require('common.pl');

use utf8;
binmode STDOUT, ":utf8";

my $type = $ARGV[0];
my $filename = 'get_agency_'.$type.'.html';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
binmode $fh, ":utf8";

$sql_list_agency = <<END_SQL;
SELECT agency.*
FROM routes, agency
WHERE route_type = $type
AND routes.agency_id = agency.agency_id
GROUP BY agency.agency_id
ORDER BY agency.agency_id

END_SQL

$query = $dbh->prepare($sql_list_agency);
$res = $query->execute();

print $fh $head_html;

print $fh <<END_HOME;
<p><a href="type_of_pt.html">Home</a> - $pt_type[$type]</p>
<table>
<tr><th>agency_id</th><th>name</th><th>url</th><th>timezone</th><th>lang</th><th>phone</th><th>fare_url</th></tr>
END_HOME


while (@data = $query->fetchrow_array()) {
my $route=$data[0];
my $cur_file='get_routes_'.$type.'_'.$route.'.html';

print $fh <<END_HTML;
<tr>
<td>$route</td>
<td><a href="$cur_file">$data[1]</a></td>
<td>$data[2]</td>
<td>$data[3]</td>
<td>$data[4]</td>
<td>$data[5]</td>
<td>$data[6]</td>
</tr>
END_HTML

unless (-e $cur_file ) {
        print "creating $cur_file\n";
        system ('./get_routes.pl', $type, $route) == 0
        or die "failed : $?";
};


}

print $fh "</table>";

print $fh $end_html;
close($fh);
