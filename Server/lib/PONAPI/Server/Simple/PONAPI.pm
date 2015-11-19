package PONAPI::Server::Simple::PONAPI;

use Plack::Request;
use Plack::Response;
use Hash::MultiValue;
use Module::Runtime    ();
use Return::MultiLevel ();
use JSON::XS           qw{ decode_json encode_json };

use PONAPI::DAO;

# TODO: move some to a config file !?
use constant {
    JSONAPI_MEDIATYPE => 'application/vnd.api+json',

    # server options
    PONAPI_SORT_ALLOWED => 0,
    PONAPI_SEND_VERSION_HEADER => 1,

    # repository
    REPOSITORY_CLASS    => 'Test::PONAPI::DAO::Repository::MockDB',
    REPOSITORY_ARGS     => [],

    # errors
    ERR_MISSING_CONTENT_TYPE => +{ __error__ => +[ 415, "{JSON:API} missing Content-Type header" ] },
    ERR_WRONG_CONTENT_TYPE   => +{ __error__ => +[ 415, "{JSON:API} Content-Type is not: 'application/vnd.api+json'" ] },
    ERR_WRONG_HEADER_ACCEPT  => +{ __error__ => +[ 406, "{JSON:API} Accept has only modified json-api media-types" ] },
    ERR_BAD_REQ              => +{ __error__ => +[ 400, "{JSON:API} Bad request" ] },
    ERR_BAD_REQ_PARAMS       => +{ __error__ => +[ 400, "{JSON:API} Bad request (unsupported parameters)" ] },
    ERR_SORT_NOT_ALLOWED     => +{ __error__ => +[ 400, "{JSON:API} Server-side sorting not allowed" ] },
    ERR_NO_MATCHING_ROUTE    => +{ __error__ => +[ 404, "{JSON:API} No matching route" ] },
};

my $QR_JSONAPI_MEDIATYPE = qr{application/vnd\.api\+json};

### TODO: ???
my $DAO;
BEGIN {
    my $repository = Module::Runtime::use_module( REPOSITORY_CLASS )->new( @{REPOSITORY_ARGS} )
        || die "[PONAPI Server] failed to create a repository object\n";

    $DAO = PONAPI::DAO->new( repository => $repository );
};

sub _request_headers {
    my $req = shift;

    return Hash::MultiValue->from_mixed(
        map { $_ => +[ split ', ' => $req->headers->header($_) ] }
        $req->headers->header_field_names
    );
}

sub _ponapi_params {
    my ( $wr, $req ) = @_;

    # THE HEADERS
    _ponapi_check_headers($wr, $req);

    # THE PATH --> route matching
    my ( $action, $type, $id, $rel_type ) = _ponapi_route_match($wr, $req->method, $req->path_info);

    # THE QUERY
    my $query = $req->query_parameters;
    my @ponapi_query_params = _ponapi_query_params($wr, $query);

    # THE BODY CONTENT
    my $data = _ponapi_data($wr, $req);

    my %params = (
        action   => $action,
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
        data     => $data,
        @ponapi_query_params,
    );

    return \%params;
}

sub _ponapi_route_match {
    my ( $wr, $method, $path ) = @_;

    $wr->(ERR_BAD_REQ) unless grep { $_ eq $method } qw< GET POST PATCH DELETE >;

    my ( $type, $id, $relationships, $rel_type ) = split '/' => substr($path,1);

    $wr->(ERR_BAD_REQ) unless $type;
    $wr->(ERR_BAD_REQ) if $rel_type and $relationships ne 'relationships';

    if ( !$rel_type and $relationships ) {
        $rel_type = $relationships;
        undef $relationships;
    }

    my $action;
    if ( defined $id ) {
        $action = 'create_relationships'     if $method eq 'POST'   and $relationships  and $rel_type;
        $action = 'retrieve'                 if $method eq 'GET'    and !$relationships and !$rel_type;
        $action = 'retrieve_by_relationship' if $method eq 'GET'    and !$relationships and $rel_type;
        $action = 'retrieve_relationships'   if $method eq 'GET'    and $relationships  and $rel_type;
        $action = 'update'                   if $method eq 'PATCH'  and !$relationships and !$rel_type;
        $action = 'update_relationships'     if $method eq 'PATCH'  and $relationships  and $rel_type;
        $action = 'delete'                   if $method eq 'DELETE' and !$relationships and !$rel_type;
        $action = 'delete_relationships'     if $method eq 'DELETE' and $relationships  and $rel_type;
    }
    else {
        $action = 'retrieve_all'             if $method eq 'GET';
        $action = 'create'                   if $method eq 'POST';
    }

    $wr->(ERR_NO_MATCHING_ROUTE) unless $action;

    return ( $action, $type, $id||'', $rel_type||'' );
}

sub _ponapi_check_headers {
    my ( $wr, $req ) = @_;
    my $headers = _request_headers($req);

    # check Content-Type

    my $content_type = $headers->get('Content-Type');

    $wr->(ERR_MISSING_CONTENT_TYPE)
        unless $content_type;

    $wr->(ERR_WRONG_CONTENT_TYPE)
        unless $content_type eq JSONAPI_MEDIATYPE;


    # check Accept

    my @jsonapi_accept =
        grep { /$QR_JSONAPI_MEDIATYPE/ }
        split /,/ => $headers->get_all('Accept');

    if ( @jsonapi_accept ) {
        $wr->(ERR_WRONG_HEADER_ACCEPT)
            unless grep { /^$QR_JSONAPI_MEDIATYPE;?$/ } @jsonapi_accept;
    }

    return;
}

sub _ponapi_query_params {
    my ( $wr, $query ) = @_;

    my %params = (
        fields  => {},
        filter  => {},
        page    => {},
        include => [],
        'sort'  => [],
    );

    # loop over query parameters (unique keys)
    for my $k ( keys %{ $query_parameters } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # valid parameter names
        $wr->(ERR_BAD_REQ_PARAMS)
            unless grep { $p eq $_ } qw< fields filter page include sort >;

        # 'sort' requested but not supported
        $wr->(ERR_SORT_NOT_ALLOWED)
            if $p eq 'sort' and !PONAPI_SORT_ALLOWED;

        # values can be passed as CSV
        my @values = map { split /,/ } $query_parameters->get_all($k);

        # values passed on in array-ref
        grep { $p eq $_ } qw< fields filter >
            and $params{$p}{$f} = \@values;

        # page info has one value per request
        $p eq 'page' and $params{$p}{$f} = $values[0];

        # values passed on in hash-ref
        $p eq 'include' and $params{include} = \@values;

        # sort values: indicate direction
        $p eq 'sort' and $params{'sort'} = +[
            map { /^(\-?)(.+)$/; +[ $2, ( $1 ? 'DESC' : 'ASC' ) ] }
            @values
        ];
    }

    return %params;
}

sub _ponapi_data {
    my ( $wr, $req ) = @_;

    $req->method eq 'GET' and return;

    my $body = decode_json( $req->content );

    $wr->(ERR_BAD_REQ)
        unless $body and ref $body eq 'HASH' and exists $body->{data};

    return $body->{data};
}

sub _response {
    my $res = Plack::Response->new( $_[0] || 200 );

    $res->content_type( JSONAPI_MEDIATYPE );
    $res->header( 'X-PONAPI-Server-Version' => '1.0' ) if PONAPI_SEND_VERSION_HEADER;
    $res->content( encode_json $_[1] );
    $res->finalize;
}

sub _error_response {
    my $args = shift;

    return _response( $args->[0], +{
        jsonapi => { version => "1.0" },
        errors  => [ { message => $args->[1] } ],
    } );
}

sub to_app {
    return sub {
        my $req = Plack::Request->new($_[0]);

        my $ponapi_params = Return::MultiLevel::with_return {
            _ponapi_params( shift, $req )
        };

        return _error_response( $ponapi_params->{__error__} )
            if $ponapi_params->{__error__};

        my $action = delete $ponapi_params->{action};

        my ( $status, $res ) = $DAO->$action($ponapi_params);
        return _response( $status, $res );
    }
}

1;

__END__
