#!/usr/bin/perl

use strict;
use utf8;
use lib '../lib';

use WL::Controller::Film;

WL::Controller::Film->new->route->print_headers->print_content;


