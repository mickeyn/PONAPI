package PONAPI::Client;

use Hijk;

use URI;
use URI::QueryParam;
use JSON::XS qw( decode_json );


### public methods

sub retrieve_all {
    my ( $class, %args ) = @_;
    $args{method} = 'retrieve_all';

    my $type  = _validate_param( 'type', \%args );
    my $query = _get_query( \%args );

    return _send_ponapi_request(
        method       => "GET",
        path         => "/$type",
        query_string => $query,
    );
}

sub retrieve {
    my ( $class, %args ) = @_;
    $args{method} = 'retrieve';

    my $type  = _validate_param( 'type', \%args );
    my $id    = _validate_param( 'id',   \%args );
    my $query = _get_query( \%args );

    return _send_ponapi_request(
        method       => "GET",
        path         => "/$type/$id",
        query_string => $query,
    );
}

sub retrieve_relationship {
    my ( $class, %args ) = @_;
    $args{method} = 'retrieve_relationship';

    my $type         = type_validate_param( 'type',     \%args );
    my $id           = type_validate_param( 'id',       \%args );
    my $rel_type     = type_validate_param( 'rel_type', \%args );
    my $query_string = _get_query    ( \%args );

    return _send_ponapi_request(
        method       => "GET",
        path         => "/$type/$id/$rel_type",
        query_string => $query_string,
    );
}


### private methods

sub _validate_param {
    my ( $key, $args ) = @_;
    my $method = ( $args->{method} ||= "anon" );

    my $val = $args->{$key} || die "[PONAPI::Client] $method: missing '$key' param\n";
    !ref($val) or die "[PONAPI::Client] $method: $key must be a scalar\n";

    return $val;
}

sub _get_query {
    my $args   = shift;
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
    my %args = @_;

    my $res = Hijk::request({
        %args,
        host => "localhost",
        port => "5000",
        head => [ 'Content-Type' => 'application/vnd.api+json' ],
    });

    return decode_json( $res->{body} );
}


1;

__END__
