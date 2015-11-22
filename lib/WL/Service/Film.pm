package WL::Service::Film;

use strict;
use utf8;

use parent 'WL';

use Try::Tiny;
use Data::Dumper;
use WL::Service::Actor;
use WL::Service::Format;


my $actor_service;
my $format_service;


sub new {
    my $class = shift;
    my $opt = shift || {};
    
    my $self = $class->SUPER::new( $opt );
    bless $self, $class;
    
    _init( $self );
    
    return $self;
}

sub _init    {
    my $self = shift;
    
    $actor_service = new WL::Service::Actor;
    $format_service = new WL::Service::Format;
}

sub find    {
    my $self = shift;
    my $opt = shift;
    
    my @bind;
    my @q;
    
    my $query = "
        FROM film fi
        JOIN format ff ON fi.format_id = ff.format_id
        LEFT JOIN film_actor fa ON fi.film_id = fa.film_id
        LEFT JOIN actor ac ON fa.actor_id = ac.actor_id
    ";
    
    if( $opt->{actor_name} )  {
        push @q, 'ac.actor_name LIKE ?';
        push @bind, $opt->{actor_name};
    }
    
    if( $opt->{film_name} )  {
        push @q, 'fi.film_name LIKE ?';
        push @bind, $opt->{film_name};
    }
    
    if( @q )    {
        $query .= ' WHERE '.join( ' AND ', @q );
    }

    $query .= ' GROUP BY fi.film_id';
    
    my $count = $self->dbh->selectrow_array( 'SELECT COUNT(*) FROM ( SELECT 1 '. $query.') t', undef, @bind );
    
    if( $opt->{order} )  {
        if( $opt->{order} eq 'film_name' )  {
            $query .= ' ORDER BY fi.film_name '.$opt->{dir};
        }
    }
    
    if( $opt->{limit} ) {
        $query .= ' LIMIT ?';
        push @bind, $opt->{limit};
    }
    
    if( $opt->{start} ) {
        $query .= ' OFFSET ?';
        push @bind, $opt->{start};
    }
    
    $query = 'SELECT fi.*, ff.*, GROUP_CONCAT( ac.actor_name ) actors '.$query;
    
    my $res = $self->dbh->selectall_arrayref( $query, { Slice => {} }, @bind );
    
    return wantarray ? ( $res, $count ) : $res;
}

sub exists  {
    my $self = shift;
    my $opt = shift;
    
    if( !$opt->{film_id} && !( $opt->{film_name} && $opt->{film_year} ) )   {
        die "film_id or film_name and film_year are required";
    }
    
    my @bind;
    my @q;
    
    my $query = 'SELECT film_id FROM film WHERE ';
    
    if( $opt->{film_id} )   {
        $query .= 'film_id = ?';
        push @bind, $opt->{film_id};
    }
    elsif( $opt->{film_name} && $opt->{film_year} )   {
        $query .= 'film_name LIKE ? AND film_year = ?';
        push @bind, $opt->{film_name}, $opt->{film_year};
    }
    
    return $self->dbh->selectrow_array( $query, undef, @bind );
}

sub load    {
    my $self = shift;
    my $opt = shift;
    
    if( !$opt->{film_id} && !( $opt->{film_name} && $opt->{film_year} ) )   {
        die "film_id or film_name and film_year are required";
    }
     
    my @bind;
    my @q;
    
    my $query = '
        SELECT fi.*, fo.*, GROUP_CONCAT(ac.actor_name) actors
        FROM film fi
        JOIN format fo ON fo.format_id = fi.format_id
        LEFT JOIN film_actor fa ON fa.film_id = fi.film_id
        LEFT JOIN actor ac ON ac.actor_id = fa.actor_id
        WHERE ';
    
    if( $opt->{film_id} )   {
        $query .= 'fi.film_id = ?';
        push @bind, $opt->{film_id};
    }
    elsif( $opt->{film_name} && $opt->{film_year} )   {
        $query .= 'fi.film_name LIKE ? AND fi.film_year = ?';
        push @bind, $opt->{film_name}, $opt->{film_year};
    }
    
    $query .= ' GROUP BY fi.film_id';
    
    return $self->dbh->selectrow_hashref( $query, undef, @bind );
}

sub create  {
    my $self = shift;
    my $opt = shift;
    
    die "film_name is required" unless( $opt->{film_name} );
    die "film_year is required" unless( $opt->{film_year} );
    die "format_id or format_name are required" unless( $opt->{format_id} || $opt->{format_name} );
    
    unless( $opt->{format_id} ) {
        my $f = $format_service->load( { format_name => $opt->{format_name} } );
        
        unless( $f )   {
            die 'format not found: ', $opt->{format_name};
        }
        
        $opt->{format_id} = $f->{format_id};
    }
    
    my $dbh = $self->dbh;
    my @actors;
    
    if( $opt->{actors} )    {
        foreach( @{$opt->{actors}} )    {
            my $act = $actor_service->load( { actor_name => $_ } );
            
            unless( $act )    {
                my $a = $actor_service->create( { actor_name => $_ } );
                
                unless( $a )    {
                    die 'actor create error: ', $_;   
                }
                
                push @actors, $a->{actor_id};
            }
            else    {
                push @actors, $act->{actor_id};
            }
        }
    }
    
    my $id;
    
    try {
        $dbh->begin_work;
        
        $dbh->do( 'INSERT INTO film( film_name, film_year, format_id ) VALUES( ?, ?, ? )', undef, $opt->{film_name}, $opt->{film_year}, $opt->{format_id} );    
        
        $id = $dbh->last_insert_id( undef, undef, undef, undef );
        
        foreach( @actors )  {
            $self->add_actor( { film_id => $id, actor_id => $_ } );
        }
        
        $dbh->commit;
    }
    catch   {
        $opt->{error} = $_;
        
        $dbh->rollback;
    };
    
    return $id;    
}

sub update  {
    my $self = shift;
    my $opt = shift;
    
    die "film_id is required" unless( $opt->{film_id} );
    die "film_name is required" unless( $opt->{film_name} );
    die "film_year is required" unless( $opt->{film_year} );
    die "format_id or format_name are required" unless( $opt->{format_id} || $opt->{format_name} );
       
    my $dbh = $self->dbh;
    my @actors;
    
    if( $opt->{actors} )    {
        foreach( @{$opt->{actors}} )    {
            my $act = $actor_service->load( { actor_name => $_ } );
            
            unless( $act )    {
                my $a = $actor_service->create( { actor_name => $_ } );
                
                unless( $a )    {
                    die 'actor create error: ', $_;   
                }
                
                push @actors, $a->{actor_id};
            }
            else    {
                push @actors, $act->{actor_id};
            }
        }
    }
    
    my $id;
    
    try {
        $dbh->begin_work;
        
        $dbh->do( 'UPDATE film SET film_name = ?, film_year = ?, format_id = ? WHERE film_id = ?',
                undef, $opt->{film_name}, $opt->{film_year}, $opt->{format_id}, $opt->{film_id} );    
        
        $self->remove_all_actors( { film_id => $opt->{film_id} } ) or die 'error while removing actors';
        
        foreach( @actors )  {
            $self->add_actor( { film_id => $opt->{film_id}, actor_id => $_ } );
        }
        
        $dbh->commit;
    }
    catch   {
        $opt->{error} = $_;
        
        $dbh->rollback;
    };
    
    return $id;   
    
}

sub delete  {
    my $self = shift;
    my $opt = shift;
    
    die 'film_id is required' unless( $opt->{film_id} );
    
    my $dbh = $self->dbh;
    
    try {
        $dbh->begin_work;
        
        $self->remove_all_actors( { film_id => $opt->{film_id} } ) or die 'error while removing actors';
        $dbh->do( 'DELETE FROM film WHERE film_id = ?', undef, $opt->{film_id} );    
        
        $dbh->commit;
    }
    catch   {
        $opt->{error} = $_;
        
        $dbh->rollback;
    };
    
}

sub add_actor    {
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

sub remove_all_actors   {
    my $self = shift;
    my $opt = shift;
    
    die 'film_id is required' unless( $opt->{film_id} );
    
    my $res =
    try {
        $self->dbh->do( 'DELETE FROM film_actor WHERE film_id = ?', undef, $opt->{film_id} );
        
        return 1;
    }
    catch {
        warn $_;
        return undef;
    };
    
    return $res;
}

sub bulk_create_films_from_file {
    my $self = shift;
    my $opt = shift;
    
    die "filepath is required" unless( $opt->{filepath} );
    die "file not found: ",$opt->{filepath} unless( -f $opt->{filepath} );
    
    my $data = $self->parse_data_file( $opt );
    
    my @err;
    #use Data::Dumper;
    foreach( @$data )   {
        my $id = $self->create( $_ );
        #warn Dumper $f;
        push @err, $_ if( $_->{error} );
    }
    
    return \@err;
}

sub parse_data_file  {
    my $self = shift;
    my $opt = shift;
    
    die "filepath is required" unless( $opt->{filepath} );
    die "file not found: ",$opt->{filepath} unless( -f $opt->{filepath} );
    
    my @data; # result array
    
    if( open FILE, $opt->{filepath} )   {
        my $f = 0; # parser's flag. parse: on/off
        my $hash; # film data
        
        while(<FILE>)   {
            my $line = $_;
            
            $line =~ s/^\s+|\s+$//g;
            
            if( $line && $f == 0 ) { # turn parsing on
                $f = 1;
            }
            elsif( !$line && $f == 1 )    { # turn parsing off
                $f = 0;
                push @data, $hash;
                $hash = {};
                next;
            }
            
            if( $f == 1 ) {
                my( $k, $v ) = split( ':', $line, 2 );
                
                $v =~ s/^\s+|\s+$//g;
                
                if( $k =~ /title/i )    {
                    $hash->{film_name} = $v;
                }
                elsif( $k =~ /year/i )  {
                    $hash->{film_year} = $v;
                }
                elsif( $k =~ /format/i )  {
                    $hash->{format_name} = $v;
                }
                elsif( $k =~ /stars/i )  {
                    $hash->{actors} = [ map { $_ =~ s/^\s+|\s+$//g; $_ ? $_ : () } split( ',', $v ) ];
                }
            }
        }
        
        close FILE;
    }
    
    return \@data;
}



1;