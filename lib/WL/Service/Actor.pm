package WL::Service::Actor;

use strict;
use utf8;

use parent 'WL';

use Try::Tiny;


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
    
    my $query = 'SELECT * FROM actor';
    
    if( $opt->{actor_name} )    {
        push @q, 'actor_name LIKE ?';
        push @bind, $opt->{actor_name};
    }
    
    if( $opt->{actor_id} )    {
        push @q, 'actor_id = ?';
        push @bind, $opt->{actor_id};
    }
    
    if( @q )    {
        $query .= ' WHERE '.join( ' AND ', @q );
    }
    
    return $self->dbh->selectall_arrayref( $query, { Slice => {} }, @bind );
}

sub load    {
    my $self = shift;
    my $opt = shift;
    
    die 'actor_name or actor_id are required' unless( $opt->{actor_name} || $opt->{actor_id} );
    
    my @bind;
    my @q;
    
    my $query = 'SELECT * FROM actor WHERE ';
    
    if( $opt->{actor_name} )    {
        $query .= 'actor_name LIKE ?';
        push @bind, $opt->{actor_name};
    }
    elsif( $opt->{actor_id} )    {
        $query .= 'actor_id = ?';
        push @bind, $opt->{actor_id};
    }
    
    return $self->dbh->selectrow_hashref( $query, undef, @bind );
}

sub create  {
    my $self = shift;
    my $opt = shift;
    
    die 'actor_name is required' unless( $opt->{actor_name} );
    
    my $dbh = $self->dbh;
    
    my $res =
    try {
        $dbh->do( 'INSERT INTO actor(actor_name) VALUES( ? )', undef, $opt->{actor_name} );
        my $id = $dbh->last_insert_id( undef, undef, undef, undef );
        
        return {
            actor_id => $id,
            actor_name => $opt->{actor_name}
        };
    }
    catch   {
        warn $_;
        return undef;
    };
   
    return $res;    
}

sub add_film    {
    my $self = shift;
    my $opt = shift;
    
    die 'actor_id is required' unless( $opt->{actor_id} );
    die 'film_id is required' unless( $opt->{film_id} );
    
    my $res =
    try {
        $self->dbh->do( 'INSERT INTO film_actor( film_id, actor_id ) VALUES( ?, ? )', undef, $opt->{film_id}, $opt->{actor_id} );
        
        return 1;
    }
    catch {
        warn $_;
        return undef;
    };
    
    return $res;
}

1;