#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

BEGIN {
    use_ok('PONAPI::Server');
}

my $JSONAPI_MEDIATYPE = 'application/vnd.api+json';

subtest '... basic server test' => sub {

    my $app = Plack::Test->create( PONAPI::Server->to_app );

    {
        my $res = $app->request( GET '/' );
        is( $res->code, 415, 'missing the {json:api} content-type' );
    }

    {
        my $res = $app->request( GET '/' , 'Content-Type' => 'application/json' );
        is( $res->code, 415, 'different content-type' );
    }

    {
        my $res = $app->request( GET '/', 'Content-Type' => $JSONAPI_MEDIATYPE, 'Accept' => $JSONAPI_MEDIATYPE . ";v=1" );
        is( $res->code, 406, 'only modified Accept header' );
    }

    {
        my $res = $app->request( GET '/', 'Content-Type' => $JSONAPI_MEDIATYPE, 'Accept' => $JSONAPI_MEDIATYPE );
        is( $res->code, 400, 'missing type - invalid request' );
    }

    {
        my $res = $app->request( GET '/', 'Content-Type' => $JSONAPI_MEDIATYPE );
        is( $res->code, 400, 'missing type - invalid request' );
    }

    {
        my $res = $app->request( GET '/articles', 'Content-Type' => $JSONAPI_MEDIATYPE );
        ok( $res->is_success, 'Successful request' );
        is( $res->headers->content_type, 'application/vnd.api+json', 'Successful Content-Type' );
    }

};

done_testing;
