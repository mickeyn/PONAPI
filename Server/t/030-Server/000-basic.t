#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use JSON::XS;

BEGIN {
    use_ok('PONAPI::Server');
}

my $article_1 = {
    data    => {
        attributes  => {
            body    => 'The shortest article. Ever.',
            created => '2015-05-22 14:56:29',
            status  => 'ok',
            title   => 'JSON API paints my bikeshed!',
            updated => '2015-05-22 14:56:29'
        },
        id            => 1,
        links         => { self => '/articles/1' },
        relationships => {
            authors => {
                data => {
                    id   => 42,
                    type => 'people'
                },
                links => {
                    related => '/articles/1/authors',
                    self    => '/articles/1/relationships/authors'
                },
            },
        },
        type    => 'articles'
    },
    jsonapi => { version => '1.0' },
    links   => { self => '/articles/1' }
};

my $JSONAPI_MEDIATYPE = 'application/vnd.api+json';
my %CT                = ( 'Content-Type' => $JSONAPI_MEDIATYPE );

sub test_response_headers {
    my $resp = shift;

    my $h = $resp->headers;
    is( $h->header('Content-Type')||'', 'application/vnd.api+json', "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
}

subtest '... basic server test' => sub {

    my $app = Plack::Test->create( PONAPI::Server->to_app );

    {
        my $res = $app->request( GET '/' );
        is( $res->code, 415, 'missing the {json:api} content-type' );
        test_response_headers($res);
    }

    {
        my $res = $app->request( GET '/' , 'Content-Type' => 'application/json' );
        is( $res->code, 415, 'different content-type' );
        test_response_headers($res);
    }

    {
        my $res = $app->request( GET '/', %CT, 'Accept' => $JSONAPI_MEDIATYPE . ";v=1" );
        is( $res->code, 406, 'only modified Accept header' );
        test_response_headers($res);
    }

    {
        my $res = $app->request( GET '/', %CT, 'Accept' => $JSONAPI_MEDIATYPE );
        is( $res->code, 400, 'missing type - invalid request' );
        test_response_headers($res);
    }

    {
        my $res = $app->request( GET '/', %CT );
        is( $res->code, 400, 'missing type - invalid request' );
        test_response_headers($res);
    }

    {
        my $res = $app->request( GET '/articles', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);
        my $expect = '{"data":[{"relationships":{"authors":{"data":{"type":"people","id":42},"links":{"related":"/articles/1/authors","self":"/articles/1/relationships/authors"}}},"type":"articles","id":"1","attributes":{"created":"2015-05-22 14:56:29","body":"The shortest article. Ever.","status":"ok","updated":"2015-05-22 14:56:29","title":"JSON API paints my bikeshed!"},"links":{"self":"/articles/1"}},{"relationships":{"authors":{"data":{"type":"people","id":88},"links":{"related":"/articles/2/authors","self":"/articles/2/relationships/authors"}},"comments":{"data":[{"type":"comments","id":5},{"type":"comments","id":12}],"links":{"related":"/articles/2/comments","self":"/articles/2/relationships/comments"}}},"type":"articles","id":"2","attributes":{"created":"2015-06-22 14:56:29","body":"The 2nd shortest article. Ever.","status":"ok","updated":"2015-06-22 14:56:29","title":"A second title"},"links":{"self":"/articles/2"}},{"relationships":{"authors":{"data":{"type":"people","id":91},"links":{"related":"/articles/3/authors","self":"/articles/3/relationships/authors"}}},"type":"articles","id":"3","attributes":{"created":"2015-07-22 14:56:29","body":"The 3rd shortest article. Ever.","status":"pending approval","updated":"2015-07-22 14:56:29","title":"a third one"},"links":{"self":"/articles/3"}}],"jsonapi":{"version":"1.0"},"links":{"self":"/articles"}}';
        is($res->content, $expect, "...content is as expected");
    }

    {
        my $res = $app->request( GET '/articles/1', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);

        my $content = decode_json $res->content;
        my $expect;
        is_deeply(
            $content,
            $article_1,
            "... content is as expected"
        );
    }

    {
        my $res = $app->request( GET '/articles/1', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);

        my $content = decode_json $res->content;
        my $expect;
        is_deeply(
            $content,
            $article_1,
            "... content is as expected"
        );
    }


};

# TODO test bad names, ala foo-bar, に, cómbo, ca$hmoney (which is valid sql...),
# etc.

done_testing;
