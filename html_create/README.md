#Principes de fonctionnement :
*On suppose la base postgis chargée avec des données OSM et GTFS fraiches.*

## show_type_of_pt.pl
Cherche dans les tables GTFS les types de transport présents (0=tram,1=metro,2=train,3=bus,etc.. et crée type_of_pt.html

Pour chaque type de transport, on appelle get_agency.pl n (avec n le numéro du type de transport)

## get_agency.pl
get_agency.pl 3 va par exemple chercher toutes les agency pour les bus et les lister dans [get_agency_3.html](http://sidjy.github.io/gtfs/get_agency_3.html)

Pour chaque agency, on appelle get_routes.pl avec 2 parametres: le type de transport et le numéro d'agency

## get_routes.pl
get_routes.pl 3 758 pour Busval d'Oise par exemple qui va generer [get_routes_3_758.html](http://sidjy.github.io/gtfs/get_routes_3_758.html)

Ce fichier liste toutes les routes [au sens GTFS du terme](https://developers.google.com/transit/gtfs/reference/routes-file), c'est à dire route_master [au sens OSM du terme](https://wiki.openstreetmap.org/wiki/Relation:route_master).
Pour chaque route, le pourcentage sur les trajets aller et retour essaye de calculer un score sur le nombre d'arrets convenablement matchés.

Pour chaque route, on appelle get_trips.pl avec 4 paramètres : les 2 précedents + l'identifiant de route + la direction (0 ou 1)

## get_trips.pl
Exemple : get_trips.pl 3 758 014195001:95-01 0 pour le bus 95-01 direction aller
On a alors le fichier [get_trips_3_758_014195001:95-01_0.html](http://sidjy.github.io/gtfs/get_trips_3_758_014195001:95-01_0.html)

Ce fichier liste un certain nombre de trips [au sens GTFS](https://developers.google.com/transit/gtfs/reference/trips-file) ou [routes au sens OSM](https://wiki.openstreetmap.org/wiki/Relation:route)
Le programme essaye de se limiter aux trips 'maitres' c'est à dire les plus longs qui sont des sur-ensembles des autres.
Tous les sub-trips inclus dans ces trips maitres n'apparaissent pas.

On appelle ensuite pour chaque trip maitre le programme get_stops.pl qui va chercher les arrets dans GTFS et essayer de les matcher dans OSM.
Il y a 5 paramètres: les 4 précédents + l'identifiant du trip

## get_stops.pl
Exemple : get_stops.pl 3 758 014195001:95-01 0 8118260-1300189

On obtient [get_stops_3_758_014195001:95-01_0_81182680-1300189.html](http://sidjy.github.io/gtfs/get_stops_3_758_014195001:95-01_0_81182680-1300189.html)

Cette page indique tout d'abord le contenu relation route qui doit être intégré dans OSM, calculé à partir des données GTFS.

Ensuite, la liste des arrêts est indiquée, dans l'ordre du trip.
Pour chaque arrêt, une ligne de tableau :
* à gauche le nom tel que renseigné dans le fichier GTFS. La couleur (de rouge=0 à vert=100) du fond indique si ce nom ressemble ou pas à celui d'OSM (calcul de similarité)
* au milieu, le nom tel que trouvé (s'il existe) dans OSM. La couleur indique ici la distance entre l'arrêt trouvé côté OSM et GTFS. Vert indique que les 2 sont très proches, rouge qu'il n'y a rien dans OSM à cet endroit.
Dans cette cas, la similarité (=ressemblance des noms en %) est indiquée + la distance en m.

* à droite, 2 actions JOSM possibles :
..* compléter arrêt (uniquement si l'arrêt OSM existe mais ne semble pas complet)
..* zoom JOSM, pour charger la zone dans JOSM. A noter que ce zoom agit aussi sur la vignette

* tout à droite ou en bas après le tableau, une vignette qui indique le trip
La ligne est bleue, et va en zig zag sur tous les arrêts mentionnés dans GTFS
Le sens du trip est indiqué par des flèches, celà permet d'aider à construire la route dans JOSM en respectant l'itinéraire

Bonus : en haut de la page, un bouton "itinéraire". La fonction est pour l'instant HS, mais quand elle fonctionne, elle permet de calculer un
itinéraire sur OSRM, basé sur la fonction match :
- j'envoie les coordonnées des arrêts issus de GTFS
- j'envoie les durées de trajet issus de GTFS (il suffit de prendre des horaires)
- je demande à OSRM de trouver un itinéraire qui respecte et les arrêts et le timing
- quand ça marche, il rajoute un itinéraire orange dans la vignette...
L'instance OSRM n'ayant qu'un profil "voiture", l'itinéraire calculé fonctionne globalement bien, sauf pour les routes autorisées aux bus mais interdites aux autres véhicules...


