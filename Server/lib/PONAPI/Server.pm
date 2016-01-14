# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Server;

our $VERSION = '0.002004';

use Plack::Request;
use Plack::Response;
use HTTP::Headers::ActionPack;
use Module::Runtime    ();
use Return::MultiLevel ();
use JSON::XS           ();
use HTTP::Headers::ActionPack;

use PONAPI::Server::ConfigReader;

use parent 'Plack::Component';

use constant {
    ERR_MISSING_CONTENT_TYPE => +{ __error__ => +[ 415, "{JSON:API} Missing Content-Type header" ] },
    ERR_WRONG_CONTENT_TYPE   => +{ __error__ => +[ 415, "{JSON:API} Invalid Content-Type header" ] },
    ERR_WRONG_HEADER_ACCEPT  => +{ __error__ => +[ 406, "{JSON:API} Invalid Accept header" ] },
    ERR_BAD_EXTENSION_REQ    => +{ __error__ => +[ 406, "{JSON:API} Request for non-supported extension" ] },
    ERR_BAD_REQ              => +{ __error__ => +[ 400, "{JSON:API} Bad request" ] },
    ERR_BAD_REQ_PARAMS       => +{ __error__ => +[ 400, "{JSON:API} Bad request (unsupported parameters)" ] },
    ERR_SORT_NOT_ALLOWED     => +{ __error__ => +[ 400, "{JSON:API} Server-side sorting not allowed" ] },
    ERR_NO_MATCHING_ROUTE    => +{ __error__ => +[ 404, "{JSON:API} No matching route" ] },
};

my $qr_member_name_prefix = qr/^[a-zA-Z0-9]/;

sub prepare_app {
    my $self = shift;

    my %conf;
    local $@;
    eval {
        %conf = PONAPI::Server::ConfigReader->new( dir => 'conf' )->read_config;
    };
    $self->{$_} //= $conf{$_} for keys %conf;

    # Some defaults
    my $default_media_type           = 'application/vnd.api+json';
    $self->{'ponapi.spec_version'} //= '1.0';
    $self->{'ponapi.mediatype'}    //= $default_media_type;

    $self->_load_dao();
}

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);

    my $ponapi_params = Return::MultiLevel::with_return {
        $self->_ponapi_params( shift, $req )
    };

    return $self->_error_response( $ponapi_params->{__error__} )
        if $ponapi_params->{__error__};

    my $action = delete $ponapi_params->{action};
    my ( $status, $headers, $res ) = $self->{'ponapi.DAO'}->$action($ponapi_params);
    return $self->_response( $status, $headers, $res );
}


### ...

sub _load_dao {
    my $self = shift;

    my $repository =
        Module::Runtime::use_module( $self->{'repository.class'} )->new( @{ $self->{'repository.args'} } )
          || die "[PONAPI Server] failed to create a repository object\n";

    $self->{'ponapi.DAO'} = PONAPI::DAO->new(
        repository => $repository,
        version    => $self->{'ponapi.spec_version'},
    );
}

sub _ponapi_params {
    my ( $self, $wr, $req ) = @_;

    # THE HEADERS
    my @ponapi_extentions = $self->_ponapi_check_headers($wr, $req);

    # THE PATH --> route matching
    my @ponapi_route_params = $self->_ponapi_route_match($wr, $req);

    # THE QUERY
    my @ponapi_query_params = $self->_ponapi_query_params($wr, $req);

    # THE BODY CONTENT
    my @ponapi_data = $self->_ponapi_data($wr, $req);

    # misc.
    my $req_base      = $self->{'ponapi.relative_links'} eq 'full' ? "".$req->base : '/';
    my $req_path      = $self->{'ponapi.relative_links'} eq 'full' ? "".$req->uri : $req->path_info;
    my $update_200    = !!$self->{'ponapi.respond_to_updates_with_200'};
    my $doc_self_link = ($req->method eq 'GET') ? !!$self->{'ponapi.doc_auto_self_link'} : 0;

    my %params = (
        @ponapi_extentions,
        @ponapi_route_params,
        @ponapi_query_params,
        @ponapi_data,
        req_base                    => $req_base,
        req_path                    => $req_path,
        respond_to_updates_with_200 => $update_200,
        send_doc_self_link          => $doc_self_link,
    );

    return \%params;
}

sub _ponapi_route_match {
    my ( $self, $wr, $req ) = @_;
    my $method = $req->method;

    $wr->(ERR_BAD_REQ) unless grep { $_ eq $method } qw< GET POST PATCH DELETE >;

    my ( $type, $id, $relationships, $rel_type ) = split '/' => substr($req->path_info,1);

    # validate `type`
    $wr->(ERR_BAD_REQ) unless defined $type and $type =~ /$qr_member_name_prefix/ ;

    # validate `rel_type`
    if ( defined $rel_type ) {
        $wr->(ERR_BAD_REQ) if $relationships ne 'relationships';
    }
    elsif ( $relationships ) {
        $rel_type = $relationships;
        undef $relationships;
    }

    my $def_rel_type = defined $rel_type;

    $wr->(ERR_BAD_REQ) if $def_rel_type and $rel_type !~ /$qr_member_name_prefix/;

    # set `action`
    my $action;
    if ( defined $id ) {
        $action = 'create_relationships'     if $method eq 'POST'   and $relationships  and $def_rel_type;
        $action = 'retrieve'                 if $method eq 'GET'    and !$relationships and !$def_rel_type;
        $action = 'retrieve_by_relationship' if $method eq 'GET'    and !$relationships and $def_rel_type;
        $action = 'retrieve_relationships'   if $method eq 'GET'    and $relationships  and $def_rel_type;
        $action = 'update'                   if $method eq 'PATCH'  and !$relationships and !$def_rel_type;
        $action = 'update_relationships'     if $method eq 'PATCH'  and $relationships  and $def_rel_type;
        $action = 'delete'                   if $method eq 'DELETE' and !$relationships and !$def_rel_type;
        $action = 'delete_relationships'     if $method eq 'DELETE' and $relationships  and $def_rel_type;
    }
    else {
        $action = 'retrieve_all'             if $method eq 'GET';
        $action = 'create'                   if $method eq 'POST';
    }

    $wr->(ERR_NO_MATCHING_ROUTE) unless $action;

    # return ( action, type, id?, rel_type? )
    my @ret = ( action => $action, type => $type );
    defined $id   and push @ret => id => $id;
    $def_rel_type and push @ret => rel_type => $rel_type;
    return @ret;
}

sub _ponapi_check_headers {
    my ( $self, $wr, $req ) = @_;

    my $pack = HTTP::Headers::ActionPack->new;
    my $mt   = $self->{'ponapi.mediatype'};
    my %ext;

    # Accept
    if ( my $accept = $req->headers->header('Accept') ) {
        my @jsonapi_accept =
            map { ( $_->[1]->type eq $mt ) ? $_->[1] : () }
            $pack->create_header( 'Accept' => $accept )->iterable;

        ### TODO: http://discuss.jsonapi.org/t/clarification-on-extensions-media-type-headers/296
        $wr->(ERR_WRONG_HEADER_ACCEPT)
            if grep { $_ ne 'ext' } map { keys %{ $_->params } } @jsonapi_accept;

        $ext{$_} = 1 for map { split ',' => $_->params->{ext} } @jsonapi_accept;
    }

    # Content-Type
    my $content_type = $req->headers->header('Content-Type');
    $wr->(ERR_MISSING_CONTENT_TYPE) unless $content_type;

    my $pack_ct = $pack->create_header( 'Content-Type' => $content_type );
    $wr->(ERR_WRONG_CONTENT_TYPE) unless $pack_ct->subject eq $self->{'ponapi.mediatype'};

    my $params = $pack_ct->params;
    my $ext    = delete $params->{ext};
    $wr->(ERR_WRONG_CONTENT_TYPE) if keys %{$params};
    $ext{$_} = 1 for split /,/ => $ext;

    $wr->(ERR_BAD_EXTENSION_REQ) if grep { ! $self->{'ponapi.extensions.' . $_} } keys %ext;

    return ( extensions => \%ext );
}

sub _ponapi_query_params {
    my ( $self, $wr, $req ) = @_;

    my %params;
    my $query_params = $req->query_parameters;

    # loop over query parameters (unique keys)
    for my $k ( keys %{ $query_params } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # valid parameter names
        $wr->(ERR_BAD_REQ_PARAMS)
            unless grep { $p eq $_ } qw< fields filter page include sort >;

        # "complex" parameters have the correct structre
        $wr->(ERR_BAD_REQ)
            if !defined $f and grep { $p eq $_ } qw< page fields filter >;

        # 'sort' requested but not supported
        $wr->(ERR_SORT_NOT_ALLOWED)
            if $p eq 'sort' and !$self->{'ponapi.sort_allowed'};

        # values can be passed as CSV
        my @values = map { split /,/ } $query_params->get_all($k);

        # check we have values for a given key
        # (for 'fields' an empty list is valid)
        $wr->(ERR_BAD_REQ)
            if $p ne 'fields' and exists $query_params->{$k} and !@values;

        # values passed on in array-ref
        grep { $p eq $_ } qw< fields filter >
            and $params{$p}{$f} = \@values;

        # page info has one value per request
        $p eq 'page' and $params{$p}{$f} = $values[0];

        # values passed on in hash-ref
        $p eq 'include' and $params{include} = \@values;

        # sort values: indicate direction
        # Not doing any processing here to allow repos to support
        # complex sorting, if they want to.
        $p eq 'sort' and $params{'sort'} = \@values;
    }

    return %params;
}

sub _ponapi_data {
    my ( $self, $wr, $req ) = @_;

    return unless $req->content_length > 0;

    $wr->(ERR_BAD_REQ) if $req->method eq 'GET';

    my $body;
    eval { $body = JSON::XS::decode_json( $req->content ); 1 };

    $wr->(ERR_BAD_REQ)
        unless $body and ref $body eq 'HASH' and exists $body->{data};

    return ( data => $body->{data} );
}

sub _response {
    my ( $self, $status, $headers, $content ) = @_;
    my $res = Plack::Response->new( $status || 200 );

    $res->headers($headers);
    $res->content_type( $self->{'ponapi.response.mediatype'} );
    $res->header( 'X-PONAPI-Server-Version' => $self->{'ponapi.spec_version'} )
        if $self->{'ponapi.send_version_header'};
    if ( ref $content ) {
        my $enc_content = JSON::XS::encode_json $content;
        $res->content($enc_content);
        $res->content_length( length($enc_content) );
    }
    $res->finalize;
}

sub _error_response {
    my ( $self, $args ) = @_;

    return $self->_response( $args->[0], [], +{
        jsonapi => { version => $self->{'ponapi.spec_version'} },
        errors  => [ { detail => $args->[1], status => $args->[0] } ],
    });
}

1;

__END__
=encoding UTF-8

=head1 SYNOPSIS

    # Run the server
    $ plackup -MPONAPI::Server -e 'PONAPI::Server->new("repository.class" => "Test::PONAPI::Repository::MockDB")->to_app'

    $ perl -MPONAPI::Client -E 'say Dumper(PONAPI::Client->new->retrieve(type => "people", id => 88))'

    # Or with cURL:
    $ curl -X GET -H "Content-Type: application/vnd.api+json" 'http://0:5000/people/88'

=head1 DESCRIPTION

C<PONAPI::Server> is a small plack server that implements the
L<{json:api}|http://jsonapi.org/> specification.

You'll have to set up a repository (to provide access to the data
you want to server) and tweak some server configurations, so
hop over to L<PONAPI::Manual> for the next steps!

=head1 BUGS, CONTACT AND SUPPORT

For reporting bugs or submitting patches, please use the github
bug tracker at L<https://github.com/mickeyn/PONAPI>.

=cut
