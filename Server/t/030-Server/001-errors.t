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

my $BAD_REQUEST_MSG = "{JSON:API} Bad request";

my %CT = ( 'Content-Type' => 'application/vnd.api+json' );

sub error_test {
    my ($res, $expected, $desc) = @_;

    my $h = $res->headers;
    is( $h->header('Content-Type')||'', 'application/vnd.api+json', "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
    is( $h->header('Location')||'', '', "... no location headers since it was an error");

    cmp_ok( $res->code, '>=', 400, "... response is an error" );

    my $content = decode_json $res->content;
    my $errors = $content->{errors};
    isa_ok( $errors, 'ARRAY' );

    my ($err) = grep { $_->{detail} eq $expected->{detail} } @{ $errors };
    is( $err->{detail}, $expected->{detail}, $desc );
    is( $err->{status},  $expected->{status}, '... and it has the expected error code' );
}

### ...

my $app = Plack::Test->create( PONAPI::Server->to_app );

subtest '... include errors' => sub {
    {
        my $res = $app->request( GET '/articles/2?include=comments', %CT );
        is( $res->code, 200, 'existing relationships are OK' );
    }

    {
        my $res = $app->request( GET '/articles/1/relationships/0', %CT );
        is($res->code, 404, "... error on non-existent '0'");
        is_deeply(
            decode_json $res->content,
            {
                errors => [{
                    detail => "Types `articles` and `0` are not related",
                    status => 404,
                }],
                jsonapi => {version => "1.0"}
            },
            "false-value relationships are allowed"
        );
    }
    {
        my $res = $app->request( GET '/articles/1/relationships//', %CT );
        is($res->code, 400, "... error empty-string relationship");
        is(
            (decode_json($res->content)||{})->{errors}[0]{detail},
            $BAD_REQUEST_MSG,
            "empty-string relationships are not allowed"
        );
    }

    {
        my $res = $app->request( GET '/articles/2?include=asdasd,comments.not_there', %CT );
        is( $res->code, 404, 'non-existing relationships are not found' );
    }

    {
        my $res = $app->request( GET '/articles/1?fields[articles]=nope', %CT );
        error_test(
            $res,
            {
                detail => 'Type `articles` does not have at least one of the requested fields',
                status => 400,
            },
            "... bad fields are detected",
        );
    }

    {
        # Note the nope
        my $res = $app->request( GET '/articles/1?include=nope', %CT );
        error_test(
            $res,
            {
                detail => 'Types `articles` and `nope` are not related',
                status => 404,
            },
            "... bad includes are detected",
        );


        $res = $app->request( GET '/articles/1?include=authors&fields[NOPE]=nope', %CT );
        error_test(
            $res,
            {
                detail => 'Type `NOPE` doesn\'t exist.',
                status => 404,
            },
            "... bad field types are detected",
        );

        # Note the 'nope'
        $res = $app->request( GET '/articles/1?include=authors&fields[people]=nope', %CT );
        error_test(
            $res,
            {
                detail => 'Type `people` does not have at least one of the requested fields',
                status => 400,
            },
            "... bad fields are detected",
        );
    }
};

subtest '... bad requests (GET)' => sub {
    # Incomplete requests
    foreach my $req (
            'fields',
            'fields=',
            'fields[articles]',
            'fields[articles]=',
            'include',
            'include=&',
            'include=',
            'include[articles]',
            'page=page',
            'filter=filter',
    ) {
        my $res = $app->request( GET "/articles/1?$req", %CT );
        error_test(
            $res,
            {
                detail => $BAD_REQUEST_MSG,
                status => 400,
            },
            "... bad request $req caught",
        );
    }
};

subtest '... bad requests (POST)' => sub {

    {
        my $res = $app->request( POST "/articles", %CT );
        error_test(
            $res,
            {
                detail => 'request body is missing',
                status => 400,
            },
            "... POST with no body",
        );
    }

    {
        my $res = $app->request( POST "/articles", %CT, Content => "hello" );
        error_test(
            $res,
            {
                detail => $BAD_REQUEST_MSG,
                status => 400,
            },
            "... POST with non-JSON body",
        );
    }

    {
        my $create_rel  = $app->request(
            POST '/articles/2/relationships/authors', %CT,
            Content => encode_json({ data => { id => 5, type => 'people'} }),
        );
        error_test(
            $create_rel,
            {
                detail => 'Parameter `data` expected Collection[Resource], but got a {"id":5,"type":"people"}',
                status => 400,
            }
        )
    }
};

done_testing;
