#use strict;

use utf8;
use DBI;

my $conffile = '../config.sh';
my $config;
{
    open my $fh, '<', $conffile or die;
    local $/ = undef;
    $config = <$fh>;
    close $fh;
}

$config =~ m/dbname=(\w*)/;
$dbname=$1;
$config =~ m/dbhost=(\w*)/;
$dbhost=$1;
$config =~ m/dbuser=(\w*)/;
$dbuser=$1;
$config =~ m/dbpwd=(\w*)/;
$dbpwd=$1;
$config =~ m/html_dir=\'([\.\w\/]*)\'/;
$out_dir=$1;

$dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpwd);

$head_html = <<END_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
		<meta http-equiv="Content-Script-Type" content="text/javascript" />
		<meta http-equiv="Content-Style-Type" content="text/css" />
		<title>Interface GTFS</title>
	</head>
<body>
END_HTML

my $in_url='leaflet@1.0.2';

$head_html_leaflet = <<END_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
		<meta http-equiv="Content-Script-Type" content="text/javascript" />
		<meta http-equiv="Content-Style-Type" content="text/css" />
		<title>Interface GTFS</title>
		<link rel="stylesheet" href="https://unpkg.com/$in_url/dist/leaflet.css" />
		<script src="https://unpkg.com/$in_url/dist/leaflet.js"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet-polylinedecorator/1.1.0/leaflet.polylineDecorator.js"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet-ajax/2.1.0/leaflet.ajax.min.js"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/1.6.0/clipboard.min.js"></script>
		<script src="https://cdn.rawgit.com/jfirebaugh/leaflet-osm/09acdf8f/leaflet-osm.js"></script>

	</head>
<body>
END_HTML



$end_html = <<END_HTML;
</body>
</html>
END_HTML

#@pt_type = ('tram','subway','train','bus','ferry','cablecar','aerialway','funicular');
@pt_type = ('Tramway','Métro','Train','Bus','Ferry','Tram à traction par câble','Téléphérique','Funiculaire');
@pt_type_osm = ('tram','subway','train','bus','ferry','cable_car','aerialway','funicular');

@osm_stop = (
'railway=tram_stop public_transport=stop_position tram=yes', #tram
'railway=stop public_transport=stop_position subway=yes', #subway
'railway=stop public_transport=stop_position train=yes', #train
'public_transport=stop_position bus=yes', #bus
'public_transport=stop_position ferry=yes', #ferry
'railway=tram_stop public_transport=stop_position tram=cable_car', #cablecar (LA)
'public_transport=stop_position aerialway=yes', #aerialway
'railway=stop public_transport=stop_position funicular=yes' #funicular
);

@osm_platform = (
'railway=platform public_transport=platform', #tram
'railway=platform public_transport=platform', #subway
'railway=platform public_transport=platform', #train
'highway=bus_stop public_transport=platform', #bus
'amenity=ferry_terminal public_transport=platform', #ferry
'railway=platform public_transport=platform', #cablecar (LA)
'aerialway=station public_transport=platform', #aerialway
'railway=platform public_transport=platform' #funicular
);




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



















