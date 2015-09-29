package API::PONAPI::Hooks;

use Dancer2 appname => 'API::PONAPI';

# ... JSON-API content type

my $jsonapi_mediatype = 'application/vnd.api+json';

hook before => sub {
    ### handle parameters

    # break fields[] & page[] paramerts
    for my $k ( qw< fields page > ) {
        my %params;

        for ( query_parameters->keys ) {
            /^$k\[(.+)\]$/ or next;
            $params{$1} = [ split /,/ => query_parameters->get($_) ];
            query_parameters->remove($_);
        }

        query_parameters->add( $k => \%params );
    }

    # sort flags
    my @sort = map { /^(\-)?(.+)$/; +[ $2, ( $1 ? 'DESC' : 'ASC' ) ] } split ',' => query_parameters->get('sort');
    query_parameters->remove('sort') and query_parameters->add( 'sort', \@sort );

    # default to undef so we don't have to check it in all route-handlers
    query_parameters->get('include') or query_parameters->add( 'include', undef );


    ### handle media-type

    # check Content-Type
    my $ct = request->headers->{'content-type'};
    $ct eq $jsonapi_mediatype and return;

    $ct =~ /^$jsonapi_mediatype;/
        and send_error "[JSON-API] Content-Type header must not include parameters", 415;

    # check Accept
    my @accept = split /,/ => request->headers->{'accept'};
    grep { $_ eq $jsonapi_mediatype } @accept
        or send_error "[JSON-API] Accept header must have an entry without parameters", 406;

    return;
};

hook after => sub {
    header 'Content-Type' => $jsonapi_mediatype;
};

1;
