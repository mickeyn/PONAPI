#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Plack::Middleware::MethodOverride;

use Data::Dumper;
use JSON::XS;

BEGIN {
    use_ok('PONAPI::Server');
}

my $JSONAPI_MEDIATYPE = 'application/vnd.api+json';
my @TEST_HEADERS      = ( 'Content-Type' => $JSONAPI_MEDIATYPE, 'X-HTTP-Method-Override' => 'GET' );

sub test_response_headers {
    my $resp = shift;

    my $h = $resp->headers;
    is( $h->header('Content-Type')||'', $JSONAPI_MEDIATYPE, "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
}

subtest '... method override (middleware not loaded)' => sub {

    my $app = Plack::Test->create( PONAPI::Server->to_app );

    {
        my $res = $app->request( POST '/articles/1?include=authors', @TEST_HEADERS );
        is( $res->code, 404, 'Not Found (as expected)' );
        test_response_headers($res);
    }

};

subtest '... method override (middleware loaded)' => sub {

    my $app = Plack::Test->create(
        Plack::Middleware::MethodOverride->wrap(PONAPI::Server->to_app )
    );

    {
        my $res = $app->request( POST '/articles/1?include=authors', @TEST_HEADERS );

        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);

        my $content  = decode_json($res->content);
        my $included = $content->{included}->[0];
        my $expect = {
            id    => 42,
            type  => 'people',
            links => { self => '/people/42' },
            attributes => {
                name   => 'John',
                age    => 80,
                gender => 'male',
            },
        };
        is_deeply(
            $included,
            $expect,
            "... included is as expected"
        );
    }

    {
        my $res  = $app->request(
            POST '/articles/2/relationships/authors',
            'Content-Type' => $JSONAPI_MEDIATYPE,
            'X-HTTP-Method-Override' => 'PATCH',
            Content => encode_json({ data => { id => 5, type => 'people'} }),
        );
        ok( $res->is_success, 'Successful request to ' . $res->request->method . " " .$res->request->uri );
        my $h = $res->headers;
        is(
            $h->header('Content-Type')||'',
            'application/vnd.api+json',
            "... has the right content-type",
        );
        is(
            $h->header('X-PONAPI-Server-Version')||'',
            '1.0',
            "... and gives us the custom X-PONAPI-Server-Version header",
        );

        my $content  = decode_json($res->content);
        is_deeply(
            $content,
            {
                jsonapi => { version => '1.0' },
                meta    => {
                    detail => 'successfully modified /articles/2/authors => {"id":5,"type":"people"}',
                },
            },
            "... got the right response",
        );
    }
};

done_testing;
