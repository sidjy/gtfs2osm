#!/usr/bin/perl

require('common.pl');

my $filename = $out_dir.'/type_of_pt.html';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

use utf8;
binmode STDOUT, ":utf8";
binmode $fh, ":utf8";



$sql_list_route_type = <<END_SQL;
SELECT DISTINCT route_type
FROM routes
ORDER BY route_type

END_SQL

$query = $dbh->prepare($sql_list_route_type);
$res = $query->execute();


print $fh $head_html;

print $fh <<END_HOME;
<p>Home</p>
<table>
<tr><th>transport_type</th><th>name</th></tr>
END_HOME


while (@data = $query->fetchrow_array()) {
my $type = $data[0];
unless (-e "get_agency_$type.html" ) {
	print "creating get_agency_$type.html\n";
	system ('./get_agency.pl', $type) == 0
	or die "failed : $?";
};


print $fh <<END_HTML;
<tr>
  <td>$type</td>
  <td><a href="get_agency_$type.html">$pt_type[$type]</a></td>
</tr>
END_HTML
}

print $fh "</table>";

print $fh $end_html;

close $fh;
