#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use lib 'lib/PONAPI/Server/routes';

BEGIN {
    use_ok('PONAPI');
}

my @TEST_HEADERS = ( 'Content-Type' => 'application/vnd.api+json' );

subtest '... basic server test' => sub {

    my $app = Plack::Test->create( PONAPI->to_app );

    {
        my $res = $app->request( GET '/' );
        is( $res->code, 404, '/ is not a valid resource query' );
    }

    {
        my $res = $app->request( GET '/articles', @TEST_HEADERS );
        ok( $res->is_success, 'Successful request' );
        is( $res->headers->content_type, 'application/vnd.api+json', 'Successful Content-Type' );
    }

};

done_testing;
