package WL::Service::Format;

use strict;
use utf8;

use parent 'WL';


sub new {
    my $class = shift;
    my $opt = shift || {};
    
    my $self = $class->SUPER::new( $opt );
    bless $self, $class;
    
    #_init( $self );
    
    return $self;
}

#sub _init    {
#    my $self = shift;
#}

sub find  {
    my $self = shift;
    my $opt = shift;
    
    my @bind;
    my @q;
    
    my $query = 'SELECT * FROM format';
    
    if( $opt->{format_name} )    {
        push @q, 'format_name LIKE ?';
        push @bind, $opt->{format_name};
    }
    
    if( $opt->{format_id} )    {
        push @q, 'format_id = ?';
        push @bind, $opt->{format_id};
    }
    
    if( @q )    {
        $query .= ' WHERE '.join( ' AND ', @q );
    }

    return $self->dbh->selectall_arrayref( $query, { Slice => {} }, @bind );
}

sub load    {
    my $self = shift;
    my $opt = shift;
    
    die 'format_name or format_id are required' unless( $opt->{format_name} || $opt->{format_id} );
    
    my @bind;
    my @q;
    
    my $query = 'SELECT * FROM format WHERE';
    
    if( $opt->{format_name} )    {
        $query .= ' format_name LIKE ?';
        push @bind, $opt->{format_name};
    }
    elsif( $opt->{format_id} )    {
        $query .= ' format_id = ?';
        push @bind, $opt->{format_id};
    }
    
    return $self->dbh->selectrow_hashref( $query, { Slice => {} }, @bind );    
}

1;