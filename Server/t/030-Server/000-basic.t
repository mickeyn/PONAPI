#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common qw/GET POST DELETE/;

use Data::Dumper;
use JSON::XS;

BEGIN {
    use_ok('PONAPI::Server');
}

my $JSONAPI_MEDIATYPE = 'application/vnd.api+json';
my %CT      = ( 'Content-Type' => $JSONAPI_MEDIATYPE );
my %JSONAPI = ( jsonapi => { version => '1.0' } );


sub test_response_headers {
    my $resp = shift;

    my $h = $resp->headers;
    is( $h->header('Content-Type')||'', 'application/vnd.api+json', "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
}

sub test_successful_request {
    my $res = shift;

    ok( $res->is_success, 'Successful request to ' . $res->request->method . " " .$res->request->uri )
        or diag(Dumper($res));

    test_response_headers($res);
}

### ...

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
        my $expected = '{"data":[{"relationships":{"authors":{"data":{"type":"people","id":42},"links":{"related":"/articles/1/authors","self":"/articles/1/relationships/authors"}}},"type":"articles","id":"1","attributes":{"created":"2015-05-22 14:56:29","body":"The shortest article. Ever.","status":"ok","updated":"2015-05-22 14:56:29","title":"JSON API paints my bikeshed!"},"links":{"self":"/articles/1"}},{"relationships":{"authors":{"data":{"type":"people","id":88},"links":{"related":"/articles/2/authors","self":"/articles/2/relationships/authors"}},"comments":{"data":[{"type":"comments","id":5},{"type":"comments","id":12}],"links":{"related":"/articles/2/comments","self":"/articles/2/relationships/comments"}}},"type":"articles","id":"2","attributes":{"created":"2015-06-22 14:56:29","body":"The 2nd shortest article. Ever.","status":"ok","updated":"2015-06-22 14:56:29","title":"A second title"},"links":{"self":"/articles/2"}},{"relationships":{"authors":{"data":{"type":"people","id":91},"links":{"related":"/articles/3/authors","self":"/articles/3/relationships/authors"}}},"type":"articles","id":"3","attributes":{"created":"2015-07-22 14:56:29","body":"The 3rd shortest article. Ever.","status":"pending approval","updated":"2015-07-22 14:56:29","title":"a third one"},"links":{"self":"/articles/3"}}],"jsonapi":{"version":"1.0"},"links":{"self":"/articles"}}';

        my $res = $app->request( GET '/articles', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);
        is_deeply(
            decode_json $res->content,
            decode_json $expected,
            "...content is as expected"
        );
    }

    {
        my $expected = {
            data => {
                type  => 'articles',
                id    => 1,
                links => { self => '/articles/1' },
                attributes  => {
                    body    => 'The shortest article. Ever.',
                    created => '2015-05-22 14:56:29',
                    status  => 'ok',
                    title   => 'JSON API paints my bikeshed!',
                    updated => '2015-05-22 14:56:29',
                },
                relationships => {
                    authors => {
                        data => { id => 42, type => 'people' },
                        links => {
                            related => '/articles/1/authors',
                            self    => '/articles/1/relationships/authors',
                        },
                    },
                },
            },
            links => { self => '/articles/1' },
            %JSONAPI
        };

        my $res = $app->request( GET '/articles/1', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);

        my $content = decode_json $res->content;
        is_deeply( $content, $expected, "... content is as expected" );
    }

    {
        my $expected = {
            id    => 42,
            type  => 'people',
            links => { self => '/people/42' },
            attributes => {
                name   => 'John',
                gender => 'male',
                age    => 80,
            },
        };

        my $res = $app->request( GET '/articles/1?include=authors', %CT );
        ok( $res->is_success, 'Successful request' );
        test_response_headers($res);

        my $content  = decode_json($res->content);
        my $included = $content->{included}->[0];
        is_deeply( $included, $expected, "... included is as expected" );

        my $link = $included->{links}{self};
        my $retrieve_res = $app->request( GET $link, %CT );

        my $retrieve_content = decode_json $retrieve_res->content;
        my %test = map +( $_ => $retrieve_content->{data}{$_} ), qw/type id attributes links/;

        is_deeply(
            \%test,
            $included,
            "... and the included data is the same we fetch"
        ) or diag(Dumper($retrieve_content));
    }
};

subtest '... mix' => sub {
    my $app = Plack::Test->create( PONAPI::Server->to_app );

    my $retrieve_all = $app->request( GET '/articles',   %CT );
    test_successful_request($retrieve_all);

    my $retrieve = $app->request( GET '/articles/2', %CT );
    test_successful_request($retrieve);

    my $retrieve_by_rel = $app->request( GET '/articles/2/authors', %CT );
    test_successful_request($retrieve_by_rel);
    is(
        decode_json($retrieve_by_rel->content)->{links}{self},
        "/people/88",
        "... retrieve by rel works"
    );

    my $retrieve_rel = $app->request( GET '/articles/1/relationships/authors', %CT );
    test_successful_request($retrieve_rel);
    is(
        decode_json($retrieve_rel->content)->{links}{self},
        "/people/42",
        "... retrive relationships"
    );

    my $create_rel = $app->request(
        POST '/articles/2/relationships/comments', %CT,
        Content => encode_json({ data => [{ id => 5555, type => 'comments'}] }),
    );
    test_successful_request($create_rel);

    my $delete_rel = $app->request(
        DELETE '/articles/2/relationships/comments', %CT,
        Content => encode_json({ data => [{ id => 5555, type => 'comments'}] }),
    );
    test_successful_request($delete_rel);

    my $delete = $app->request( DELETE '/articles/2', %CT );
    test_successful_request($delete);
    is_deeply(
        decode_json($delete->content),
        {
            %JSONAPI,
            meta => { detail => 'successfully deleted the resource /articles/2' },
        },
        "... deleted a resource, got the right meta"
    );

    my $delete_again = $app->request( DELETE '/articles/2', %CT );
    test_successful_request($delete_again);
    is_deeply(
        decode_json($delete_again->content),
        {
            %JSONAPI,
            meta => { detail => 'successfully deleted the resource /articles/2' },
        },
        "... deleted a deleted, got the right meta"
    );

    my $retrieve_2 = $app->request( GET '/articles/2', %CT );
    test_successful_request($retrieve_2);
    is_deeply(
        decode_json($retrieve_2->content),
        {
            %JSONAPI,
            data => undef,
        },
        "... retrieved a now-deleted resource, got data => undef"
    );
};

# TODO test bad names, ala foo-bar, に, cómbo, ca$hmoney (which is valid sql...),
# etc.

done_testing;
