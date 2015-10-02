package PONAPI::Client;

use Moose;

use Hijk;
use URI;
use URI::QueryParam;
use JSON::XS qw( decode_json encode_json );

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'localhost' },
);

has port => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { 5000 },
);


### public methods

sub retrieve_all {
    my ( $self, %args ) = @_;
    $args{method} = 'retrieve_all';

    my $type  = $self->_validate_param( 'type', \%args );
    my $query = $self->_get_query( \%args );

    return $self->_send_ponapi_request(
        method       => "GET",
        path         => "/$type",
        query_string => $query,
    );
}

sub retrieve {
    my ( $self, %args ) = @_;
    $args{method} = 'retrieve';

    my $type  = $self->_validate_param( 'type', \%args );
    my $id    = $self->_validate_param( 'id',   \%args );
    my $query = $self->_get_query( \%args );

    return $self->_send_ponapi_request(
        method       => "GET",
        path         => "/$type/$id",
        query_string => $query,
    );
}

sub retrieve_relationship {
    my ( $self, %args ) = @_;
    $args{method} = 'retrieve_relationship';

    my $type         = $self->_validate_param( 'type',     \%args );
    my $id           = $self->_validate_param( 'id',       \%args );
    my $rel_type     = $self->_validate_param( 'rel_type', \%args );
    my $query_string = $self->_get_query( \%args );

    return $self->_send_ponapi_request(
        method       => "GET",
        path         => "/$type/$id/$rel_type",
        query_string => $query_string,
    );
}

sub create {
    my ( $self, %args ) = @_;
    $args{method} = 'create';

    my $type = $self->_validate_param( 'type', \%args );
    my $data = $self->_validate_param( 'data', \%args );

    # in case of client-generated id
    if ( exists $args{id} ) {
        my $id = $self->_validate_param( 'id', \%args );
        $data->{id} = $id;
    }

    return $self->_send_ponapi_request(
        method => "POST",
        path   => "/$type",
        body   => encode_json( { data => $data } ),
    );
}

sub del {
    my ( $self, %args ) = @_;
    $args{method} = 'del';

    my $type = $self->_validate_param( 'type', \%args );
    my $id   = $self->_validate_param( 'id',   \%args );

    return $self->_send_ponapi_request(
        method => "DELETE",
        path   => "/$type/$id",
    );
}


### private methods

sub _validate_param {
    my ( $self, $key, $args ) = @_;
    my $method = ( $args->{method} ||= "anon" );

    my $val = $args->{$key} || die "[PONAPI::Client] $method: missing '$key' param\n";

    if ( $key eq 'data' ) {
        ref($val) eq 'HASH' or die "[PONAPI::Client] $method: $key must be a hashref\n";
    }
    else {
        !ref($val) or die "[PONAPI::Client] $method: $key must be a scalar\n";
    }

    return $val;
}

sub _get_query {
    my ( $self, $args ) = @_;
    my $method = ( $args->{method} ||= "anon" );

    my $u = URI->new("", "http");

# TODO: global valid params per $method???

    for my $k ( qw< filter fields page > ) {
        next unless $args->{$k};
        ref $args->{$k} eq 'HASH' or die "[PONAPI::Client] $method: '$k' must be a hash";
        $u->query_param( $k.'['.$_.']' => $args->{$k}{$_} ) for keys %{ $args->{$k} };
    }

    $u->query_param( $args->{include} ) if exists $args->{include};

    return $u->query;
}

sub _send_ponapi_request {
    my $self = shift;
    my %args = @_;

    my $res = Hijk::request({
        %args,
        host => $self->host,
        port => $self->port,
        head => [ 'Content-Type' => 'application/vnd.api+json' ],
    });

    return decode_json( $res->{body} );
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
