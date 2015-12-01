package PONAPI::Server;

use Plack::Request;
use Plack::Response;
use Hash::MultiValue;
use Module::Runtime    ();
use Return::MultiLevel ();
use Path::Class::File  ();
use YAML::XS           ();
use JSON::XS           qw{ decode_json encode_json };

use PONAPI::Server::ConfigReader;

use parent 'Plack::Component';

use constant {
    ERR_MISSING_CONTENT_TYPE => +{ __error__ => +[ 415, "{JSON:API} missing Content-Type header" ] },
    ERR_WRONG_CONTENT_TYPE   => +{ __error__ => +[ 415, "{JSON:API} Content-Type is not: 'application/vnd.api+json'" ] },
    ERR_WRONG_HEADER_ACCEPT  => +{ __error__ => +[ 406, "{JSON:API} Accept has only modified json-api media-types" ] },
    ERR_BAD_REQ              => +{ __error__ => +[ 400, "{JSON:API} Bad request" ] },
    ERR_BAD_REQ_PARAMS       => +{ __error__ => +[ 400, "{JSON:API} Bad request (unsupported parameters)" ] },
    ERR_SORT_NOT_ALLOWED     => +{ __error__ => +[ 400, "{JSON:API} Server-side sorting not allowed" ] },
    ERR_NO_MATCHING_ROUTE    => +{ __error__ => +[ 404, "{JSON:API} No matching route" ] },
};

sub prepare_app {
    my %conf = PONAPI::Server::ConfigReader->new( dir => 'conf' )->read_config;
    $_[0]->{$_} = $conf{$_} for keys %conf;
}

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);

    my $ponapi_params = Return::MultiLevel::with_return {
        $self->_ponapi_params( shift, $req )
    };

    return $self->_error_response( $ponapi_params->{__error__} )
        if $ponapi_params->{__error__};

    $ponapi_params->{req_base} =
        $self->{'ponapi.relative_links'} eq 'full' ? "".$req->base : '/';

    $ponapi_params->{send_doc_self_link} = $self->{'ponapi.doc_auto_self_link'}
        if $req->method eq 'GET';

    my $action = delete $ponapi_params->{action};
    my ( $status, $headers, $res ) = $self->{'ponapi.DAO'}->$action($ponapi_params);
    return $self->_response( $status, $headers, $res );
}


### ...

sub _request_headers {
    my ( $self, $req ) = @_;

    return Hash::MultiValue->from_mixed(
        map { $_ => +[ split ', ' => $req->headers->header($_) ] }
        $req->headers->header_field_names
    );
}

sub _ponapi_params {
    my ( $self, $wr, $req ) = @_;

    # THE HEADERS
    $self->_ponapi_check_headers($wr, $req);

    # THE PATH --> route matching
    my @ponapi_route_params = $self->_ponapi_route_match($wr, $req);

    # THE QUERY
    my @ponapi_query_params = $self->_ponapi_query_params($wr, $req);

    # THE BODY CONTENT
    my $has_body = !!( $req->content_length > 0 );
    $wr->(ERR_BAD_REQ) if $req->method eq 'GET' and $has_body;

    my $data = $self->_ponapi_data($wr, $req);

    my %params = (
        @ponapi_route_params,
        @ponapi_query_params,
        data     => $data,
        has_body => $has_body,
        respond_to_updates_with_200 => $self->{'ponapi.respond_to_updates_with_200'},
    );

    return \%params;
}

sub _ponapi_route_match {
    my ( $self, $wr, $req ) = @_;
    my $method = $req->method;

    $wr->(ERR_BAD_REQ) unless grep { $_ eq $method } qw< GET POST PATCH DELETE >;

    my ( $type, $id, $relationships, $rel_type ) = split '/' => substr($req->path_info,1);

    $wr->(ERR_BAD_REQ) unless $type;
    $wr->(ERR_BAD_REQ) if defined($rel_type) and $relationships ne 'relationships';

    if ( defined($rel_type) ) {
        $wr->(ERR_BAD_REQ) if !length($rel_type);
    }
    elsif ( $relationships ) {
        $rel_type = $relationships;
        undef $relationships;
    }

    my $action;
    if ( defined $id ) {
        $action = 'create_relationships'     if $method eq 'POST'   and $relationships  and defined($rel_type);
        $action = 'retrieve'                 if $method eq 'GET'    and !$relationships and !defined($rel_type);
        $action = 'retrieve_by_relationship' if $method eq 'GET'    and !$relationships and defined($rel_type);
        $action = 'retrieve_relationships'   if $method eq 'GET'    and $relationships  and defined($rel_type);
        $action = 'update'                   if $method eq 'PATCH'  and !$relationships and !defined($rel_type);
        $action = 'update_relationships'     if $method eq 'PATCH'  and $relationships  and defined($rel_type);
        $action = 'delete'                   if $method eq 'DELETE' and !$relationships and !defined($rel_type);
        $action = 'delete_relationships'     if $method eq 'DELETE' and $relationships  and defined($rel_type);
    }
    else {
        $action = 'retrieve_all'             if $method eq 'GET';
        $action = 'create'                   if $method eq 'POST';
    }

    $wr->(ERR_NO_MATCHING_ROUTE) unless $action;

    my @ret = ( action => $action, type => $type );
    defined $id       and push @ret => id => $id;
    defined $rel_type and push @ret => rel_type => $rel_type;

    return @ret;
}

sub _ponapi_check_headers {
    my ( $self, $wr, $req ) = @_;
    my $headers = $self->_request_headers($req);

    # check Content-Type
    my $content_type = $headers->get('Content-Type');
    $wr->(ERR_MISSING_CONTENT_TYPE) unless $content_type;
    $wr->(ERR_WRONG_CONTENT_TYPE)   unless $content_type eq $self->{'ponapi.mediatype'};

    # check Accept
    my $qr = $self->{'ponapi.qr_mediatype'};
    my @jsonapi_accept = grep { /$qr/ } split /,/ => $headers->get_all('Accept');
    return unless @jsonapi_accept;
    $wr->(ERR_WRONG_HEADER_ACCEPT) unless grep { /^$qr;?$/ } @jsonapi_accept;
}

sub _ponapi_query_params {
    my ( $self, $wr, $req ) = @_;

    my %params = (
        fields  => {},
        filter  => {},
        page    => {},
        include => [],
        'sort'  => [],
    );

    # loop over query parameters (unique keys)
    for my $k ( keys %{ $req->query_parameters } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # valid parameter names
        $wr->(ERR_BAD_REQ_PARAMS)
            unless grep { $p eq $_ } qw< fields filter page include sort >;

        # 'sort' requested but not supported
        $wr->(ERR_SORT_NOT_ALLOWED)
            if $p eq 'sort' and !$self->{'ponapi.sort_allowed'};

        # values can be passed as CSV
        my @values = map { split /,/ } $req->query_parameters->get_all($k);

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
    my ( $self, $wr, $req ) = @_;
    $req->method eq 'GET' and return +{};

    my $body = decode_json( $req->content );

    $wr->(ERR_BAD_REQ)
        unless $body and ref $body eq 'HASH' and exists $body->{data};

    return $body->{data};
}

sub _response {
    my ( $self, $status, $headers, $content ) = @_;
    my $res = Plack::Response->new( $status || 200 );

    $res->headers( $headers );
    $res->content_type( $self->{'ponapi.mediatype'} );
    $res->header( 'X-PONAPI-Server-Version' => $self->{'ponapi.spec_version'} )
        if $self->{'ponapi.send_version_header'};
    $res->content( encode_json $content ) if ref $content;
    $res->finalize;
}

sub _error_response {
    my ( $self, $args ) = @_;

    return $self->_response( $args->[0], [], +{
        jsonapi => { version => $self->{'ponapi.spec_version'} },
        errors  => [ { message => $args->[1] } ],
    });
}


1;

__END__
