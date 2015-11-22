package WL::Config;

use strict;
use utf8;

use base 'Exporter';

our @EXPORT = qw($CONFIG);

our $CONFIG = {
    connections => {
        default => {
            dsn => 'dbi:mysql:wl_test:localhost',
            user => 'wl_test',
            password => 'wl_test'
        }
    },
    db => 'default', # used connection
    per_page => 8 # items per page in list
};


1;