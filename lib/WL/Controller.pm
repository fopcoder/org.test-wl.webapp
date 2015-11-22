package WL::Controller;

use strict;
use utf8;

use parent 'WL';

use DBI;
use CGI;
use Data::Dumper;
use File::Temp 'tempfile';
use POSIX;
use WL::Config;

my $q;


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
    
    unless( $q )    {
        $q = new CGI;
    }
    $self->{headers} = [];
    $self->{template_path} = $ENV{DOCUMENT_ROOT}.'/../template';
}

sub q   {
    my $self = shift;
    
    return $q;
}

sub headers {
    my $self = shift;
    
    if( @_ )    {
        push @{$self->{headers}}, shift;
    }
    
    if( $self->{status} == 404 )   {
        return "Status: 404 Not Found\n\n";
    }
    else    {
        unless( @{$self->{headers}} )   {
            return "Content-Type:text/html\n\n";    
        }
        else    {
            return join( "\n",@{$self->{headers}} )."\n\n";
        }
    }
}

sub print_headers   {
    my $self = shift;
    
    print $self->headers();
    
    return $self;
}

sub content {
    my $self = shift;
    
    if( @_ )    {
        $self->{content} = shift;
    }
   
    return $self->{content};
}

sub print_content   {
    my $self = shift;
    
    if( @_ )    {
        $self->content( shift );
    }
    
    print $self->content;
    
    return $self;
}

sub get_request_opt   {
    my $self = shift;
    my $uri = shift;
   
    my $opt = {};
    
    if( $self->q->cookie('order') )  {
        $opt->{order} = $self->q->cookie('order');
        $opt->{dir} = $self->q->cookie('dir') eq 'DESC' ? 'DESC' : 'ASC';
    }
    
    if( $uri =~ /(\/ord\/(\w+)\/(\w))/ )    {
        $opt->{order} = $2;
        $opt->{dir} = $3 eq 'd' ? 'DESC' : 'ASC';
        $uri =~ s/$1//;
        
        $self->headers( 'Set-Cookie: '. $self->q->cookie( -name => 'order', -value => $opt->{order}, -expires => '+1y' ) );
        $self->headers( 'Set-Cookie: '. $self->q->cookie( -name => 'dir', -value => $opt->{dir}, -expires => '+1y' ) );
        $self->headers( 'Location: http://'.$ENV{HTTP_HOST}.$uri );
    }
    
    if( $uri =~ /(\/p\/(\d+))/ )    {
        $opt->{page} = $2;
        $uri =~ s/$1//;
    }
    
    if( $uri =~ /(\/sfilm\/([^\/]*))\/?/ || $self->q->param('sfilm') ) {
        $opt->{sfilm} = $2|| $self->q->param('sfilm');
        $uri =~ s/$1//;
    }
    
    if( $uri =~ /(\/sactor\/([^\/]*))\/?/ || $self->q->param('sactor') ) {
        $opt->{sactor} = $2|| $self->q->param('sactor');
        $uri =~ s/$1//;
    }
    
    $opt->{uri} = $uri;
    
    return $opt;
}

sub route   {
    my $self = shift;
    
    warn 'route() unimplemented';
    
    return $self;
}

sub template_path   {
    my $self = shift;
    
    return $self->{template_path};
}

sub upload_file {
    my $self = shift;
    my $opt = shift;
    
    $opt->{field} ||= 'file';
        
    my( $fh, $filename ) = tempfile();
    my $file = $self->q->param( $opt->{field} );
    
    while( read( $file, my $buf, 1024 ) )   {
        print $fh $buf;
    }
    
    return $filename;
}

sub paging  {
    my $self = shift;
    my $opt = shift;
    
    my $pages = ceil( $opt->{count} / $CONFIG->{per_page} );
    my $url = $opt->{base};
    
    if( $opt->{sfilm} )   {
        $url .= '/sfilm/'.$opt->{sfilm};
    }
    
    if( $opt->{sactor} )   {
        $url .= '/sactor/'.$opt->{sactor};
    }
    
    my @res;
    
    for( my $i = 0; $i < $pages; $i++ )    {
        push @res, {
            text => $i + 1,
            href => $url.( $i ? '/p/'.$i : '' ),
            active => $opt->{page} == $i ? 1 : 0
        };
    }
    
    return \@res;
}


1;