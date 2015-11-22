Application site http://wl.axisdesktop.com/

1. Structure

/htdocs - DOCUMENT_ROOT of an application. All requests are redirected according to rules in /htdocs/.htaccess

/cgi-bin/film.cgi - a film's starter script

/conf/scheme.sql - a database structure of an application

/lib - applicaton modules

WL - the root class
WL::Config - application's configuration file ( databases, application variables )
WL::Controller - the base controllers class
WL::Controller::* - controller layers for different entities, they know all about request routing and use services to get/persist data
WL::Service::* - service layers for entities, they know all about database structure

/template - HTML page templates

2. Short description

- .htaccess rule redirects request to /cgi-bin/film.cgi
- in depends of the URL, the WL::Controller::Film will run appropriate method, that will use services to perform actions on database
- data from database will be pushed to template engine and will be displayed by browser