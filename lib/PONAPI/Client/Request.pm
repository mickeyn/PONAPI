package PONAPI::Client::Request;

use Moose::Role;

use URI;
use URI::QueryParam;
use JSON::XS qw( encode_json );

requires 'method';
requires 'path';

sub request_params {
    my $self = shift;

    my $method = $self->method;

    my @ret = ( method => $method, path => $self->path );

    if ( $method eq 'GET' ) {
        push @ret => ( query_string => $self->_build_query_string );
    }

    if ( $method eq 'POST' or $method eq 'PATCH' ) {
        push @ret => ( body => encode_json( { data => $self->data } ) );
    }

    return @ret;
}

sub _build_query_string {
    my $self = shift;

    my $u = URI->new("", "http");

    if ( $self->does('PONAPI::Client::Request::Role::HasFilter') and $self->has_filter ) {
        $u->query_param( 'filter['.$_.']', join ',' => @{ $self->filter->{$_} } )
            for keys %{ $self->filter };
    }

    if ( $self->does('PONAPI::Client::Request::Role::HasFields') and $self->has_fields ) {
        $u->query_param( 'fields['.$_.']', join ',' => @{ $self->fields->{$_} } )
            for keys %{ $self->fields };
    }

    if ( $self->does('PONAPI::Client::Request::Role::HasPage') and $self->has_page ) {
        $u->query_param( 'page['.$_.']', $self->page->{$_} ) for keys %{ $self->page };
    }

    if ( $self->does('PONAPI::Client::Request::Role::HasInclude') and $self->has_include ) {
        $u->query_param( include => join ',' => @{ $self->include } );
    }

    if ( $self->does('PONAPI::Client::Request::Role::HasSort') and $self->has_sort ) {
        $u->query_param( sort => join ',' => @{ $self->sort } );
    }

    return $u->query;
}


no Moose::Role; 1;
__END__
