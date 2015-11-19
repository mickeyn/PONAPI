#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

BEGIN {
    use_ok('PONAPI::Server::Simple::PONAPI');
}

my $JSONAPI_CONTENT_TYPE = 'application/vnd.api+json';
my @CONTENT_TYPE = ( 'Content-Type' => $JSONAPI_CONTENT_TYPE );

subtest '... basic server test' => sub {

    my $app = Plack::Test->create( PONAPI::Server::Simple::PONAPI->to_app );

    {
        my $res = $app->request( GET '/' );
        is( $res->code, 415, 'missing the {json:api} content-type' );
    }

    {
        my $res = $app->request( GET '/', @CONTENT_TYPE, 'Accept' => $JSONAPI_CONTENT_TYPE . ";v=1" );
        is( $res->code, 406, 'only modified Accept header' );
    }

    {
        my $res = $app->request( GET '/', @CONTENT_TYPE, 'Accept' => $JSONAPI_CONTENT_TYPE );
        is( $res->code, 400, 'missing type - invalid request' );
    }

    {
        my $res = $app->request( GET '/', @CONTENT_TYPE );
        is( $res->code, 400, 'missing type - invalid request' );
    }

    {
        my $res = $app->request( GET '/articles', @CONTENT_TYPE );
        ok( $res->is_success, 'Successful request' );
        is( $res->headers->content_type, 'application/vnd.api+json', 'Successful Content-Type' );
    }

};

done_testing;
