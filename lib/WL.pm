package WL;

use strict;
use utf8;

use WL::Config;

my $dbh;

sub new {
    my $class = shift;
    my $self = shift || {};
    
    bless $self, $class;
    
    _init();
    
    return $self;
}


sub _init    {
      
    unless ( $dbh ) {
        my $dbh_conf = $CONFIG->{connections}->{ $CONFIG->{db} }; 
        $dbh = DBI->connect( $dbh_conf->{dsn}, $dbh_conf->{user}, $dbh_conf->{password}, { RaiseError => 1 } );
        $dbh->do('SET NAMES UTF8');
    }
}

sub dbh {
    my $self = shift;
    
    return $dbh;
}


1;