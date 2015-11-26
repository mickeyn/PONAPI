#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

BEGIN {
    use_ok('PONAPI::Server');
}

my @TEST_HEADERS = ( 'Content-Type' => 'application/vnd.api+json' );

subtest '... include errors' => sub {

    my $app = Plack::Test->create( PONAPI::Server->to_app );

    {
        my $res = $app->request( GET '/articles/2?include=comments', @TEST_HEADERS );
        is( $res->code, 200, 'existing relationships are OK' );
    }

    {
        my $res = $app->request( GET '/articles/2?include=asdasd,comments.not_there', @TEST_HEADERS );
        is( $res->code, 404, 'non-existing relationships are not found' );
    }

};

done_testing;
