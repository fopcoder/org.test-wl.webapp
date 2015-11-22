package WL::Controller::Film;

use strict;
use utf8;

use parent 'WL::Controller';

use Data::Dumper;
use HTML::Template::Pro;
use Try::Tiny;
use WL::Config;
use WL::Service::Film;


my $film_service;
my $format_service;
my %tmpl_conf;

sub new {
    my $class = shift;
    my $self = shift || {};
    
    $self = $class->SUPER::new( $self );
    
    _init( $self );
    
    return $self;
}

sub _init    {
    my $self = shift;
    
    unless( $film_service ) {
        $film_service = new WL::Service::Film;
        $format_service = new WL::Service::Format;
    }
    
    %tmpl_conf = (
        case_sensitive => 0,
        path => [ $self->template_path.'/admin/film' ],
        die_on_bad_params => 0,
        loop_context_vars => 1
    );
}

# simple router  
sub route   {
    my $self = shift;
    
    my $uri = $self->q->request_uri;    
    my $opt = $self->get_request_opt( $uri );
    $uri = $opt->{uri};
    
    if( $uri =~ m!/admin/film/(\d+)! )   {
        $self->load( $opt );
    }
    elsif( $uri =~ m!/admin/film/new! )   {
        $self->create( $opt );
    }
    elsif( $uri =~ m!/admin/film/save! )   {
        $self->save( $opt );
    }
    elsif( $uri =~ m!/admin/film/delete! )   {
        $self->delete( $opt );
    }
    elsif( $uri =~ m!/admin/film/bulk/?$! )   {
        $self->bulk( $opt );
    }
    elsif( $uri =~ m!/admin/film/bulk/upload/?$! )   {
        $self->bulk_upload( $opt );
    }
    elsif( $uri =~ m!/admin/film/?$! )   {
        $self->list( $opt );
    }
    else    {
        $self->{status} = 404;
        warn 'page not found: '.$uri;
    }
    
    return $self;
}


sub list    {
    my $self = shift;
    my $opt = shift||{};
    
    try {
        my $sfilm = $opt->{sfilm} || scalar $self->q->param('sfilm');
        my $sact = $opt->{sactor} || scalar $self->q->param('sactor');
    
        my( $res, $count ) = $film_service->find( {
            %$opt,
            film_name => $sfilm ? '%'.$sfilm.'%' : undef,
            actor_name => $sact ? '%'.$sact.'%' : undef,
            start => $opt->{page} * $CONFIG->{per_page},
            limit => $CONFIG->{per_page}
        } );
        
        my $paging = $self->paging( { %$opt, count => $count, base => '/admin/film' } );
        
        my $ordapp;
        
        if( $sfilm )    {
            $ordapp .= '/sfilm/'.$sfilm;
        }
        if( $sact )    {
            $ordapp .= '/sactor/'.$sact;
        }
        if( $opt->{page} )  {
            $ordapp .= '/p/'.$opt->{page};
        }
        
        my $tmpl = new HTML::Template::Pro( %tmpl_conf, filename => 'index.html' );
        $tmpl->param( films => $res );
        $tmpl->param( paging => $paging );
        $tmpl->param( sfilm => $opt->{sfilm} || scalar $self->q->param('sfilm') );
        $tmpl->param( sactor => $opt->{sactor} || scalar $self->q->param('sactor') );
        $tmpl->param( paging => $paging );
        $tmpl->param( ordapp => $ordapp );
        
        $self->content( $tmpl->output );
    }
    catch {
        $self->content( $_ );
    };
}

sub load    {
    my $self = shift;
    my $opt = shift||{};
    
    try {
        
        $opt->{uri} =~ /film\/(\d+)/;
        
        my $res = $film_service->load( { film_id => $1 } );
        
        my $formats = $format_service->find();
        
        foreach( @$formats )    {
            if( $_->{format_id} == $res->{format_id} )    {
                $_->{active} = 'selected';
            }
        }
        
        my $tmpl = new HTML::Template::Pro( %tmpl_conf, filename => 'edit.html' );
        $tmpl->param( $res );
        $tmpl->param( formats => $formats );
        
        $self->content( $tmpl->output );
    }
    catch {
        $self->content( $_ );
    };
}

sub create    {
    my $self = shift;
    my $opt = shift||{};
    
    try {
        my $tmpl = new HTML::Template::Pro( %tmpl_conf, filename => 'edit.html' );
        $tmpl->param( film_name => 'New Film' );
        $tmpl->param( formats => $format_service->find() );
        
        $self->content( $tmpl->output );
    }
    catch {
        $self->content( $_ );
    };
}

sub save    {
    my $self = shift;
    my $opt = shift||{};
    
    try {
        
        my $data = {
            film_id => scalar $self->q->param('film_id'),
            film_name => scalar $self->q->param('film_name'),
            film_year => scalar $self->q->param('film_year'),
            format_id => scalar $self->q->param('format_id'),
            actors => [ map { $_ =~ s/^\s+|\s+$//g; $_ ? $_ : () } split( ',', scalar $self->q->param('actors') ) ]
        };
        
        my $id;
        
        if( $data->{film_id} ) {
            $film_service->update( $data ); 
        }
        else    {
            $data->{film_id} = $film_service->create( $data );
        }
        
        $self->headers( "Location: http://$ENV{HTTP_HOST}/admin/film/".$data->{film_id} );
    }
    catch {
        $self->content( $_ );
    };
    
}

sub delete    {
    my $self = shift;
    my $opt = shift||{};
    
    try {
        foreach( $self->q->param('film_id') )   {
            $film_service->delete( { film_id => $_ } );     
        }
        
        $self->headers( "Location: http://$ENV{HTTP_HOST}/admin/film" );
    }
    catch {
        $self->content( $_ );
    };
}

sub bulk    {
    my $self = shift;
    
    try {
        my $tmpl = new HTML::Template::Pro( %tmpl_conf, filename => 'bulk.html' );
        $self->content( $tmpl->output );
    }
    catch {
        $self->content( $_ );
    };
}

sub bulk_upload {
    my $self = shift;
    
    try {
        my $fn = $self->upload_file();
        my $res = $film_service->bulk_create_films_from_file( { filepath => $fn } );
       
        unless( @$res )  { # no errors
            $self->headers( "Location: http://$ENV{HTTP_HOST}/admin/film" );
        }
        else    {
            my $tmpl = new HTML::Template::Pro( %tmpl_conf, filename => 'bulk_upload.html' );
            $tmpl->param( errors => $res ) ;
            $self->content( $tmpl->output );
        }
    }
    catch {
        $self->content( $_ );
    };
}

1;