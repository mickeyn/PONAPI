#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use JSON::XS;
use Data::Dumper;

BEGIN {
    use_ok('PONAPI::Server');
}

my $BAD_REQUEST_MSG = "{JSON:API} Bad request";

my @TEST_HEADERS = ( 'Content-Type' => 'application/vnd.api+json' );

sub error_test {
    my ($res, $expect, $desc) = @_;

    my $h = $res->headers;
    is( $h->header('Content-Type')||'', 'application/vnd.api+json', "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
    is( $h->header('Location')||'', '', "... no location headers since it was an error");

    cmp_ok( $res->code, '>=', 400, "... response is an error" );

    my $content = decode_json $res->content;
    my $errors = $content->{errors};
    isa_ok( $errors, 'ARRAY' );

    my ($err) = grep { $_->{detail} eq $expect->{detail} } @{ $errors };
    is( $err->{detail}, $expect->{detail}, $desc ) or diag(Dumper($content));
    is( $err->{status},  $expect->{status}, '... and it has the expected error code' );
}

subtest '... include errors' => sub {

    my $app = Plack::Test->create( PONAPI::Server->to_app );

    {
        my $res = $app->request( GET '/articles/2?include=comments', @TEST_HEADERS );
        is( $res->code, 200, 'existing relationships are OK' );
    }

    {
        my $res = $app->request( GET '/articles/1/relationships/0', @TEST_HEADERS );
        is($res->code, 404, "... error on non-existent '0'");
        is_deeply(
            decode_json $res->content,
            {
                errors => [{
                    status => 404,
                    detail => "Types `articles` and `0` are not related"
                }],
                jsonapi => {version => "1.0"}
            },
            "false-value relationships are allowed"
        );
    }
    {
        my $res = $app->request( GET '/articles/1/relationships//', @TEST_HEADERS );
        is($res->code, 400, "... error empty-string relationship");
        is(
            (decode_json($res->content)||{})->{errors}[0]{detail},
            $BAD_REQUEST_MSG,
            "empty-string relationships are not allowed"
        );
    }

    {
        my $res = $app->request( GET '/articles/2?include=asdasd,comments.not_there', @TEST_HEADERS );
        is( $res->code, 404, 'non-existing relationships are not found' );
    }

    {
        my $res = $app->request( GET '/articles/1?fields[articles]=nope', @TEST_HEADERS );
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
        my $res = $app->request( GET '/articles/1?include=nope', @TEST_HEADERS );
        error_test(
            $res,
            {
                detail => 'Types `articles` and `nope` are not related',
                status => 404,
            },
            "... bad includes are detected",
        );


        $res = $app->request( GET '/articles/1?include=authors&fields[NOPE]=nope', @TEST_HEADERS );
        error_test(
            $res,
            {
                detail => 'Type `NOPE` doesn\'t exist.',
                status => 404,
            },
            "... bad field types are detected",
        );

        # Note the 'nope'
        $res = $app->request( GET '/articles/1?include=authors&fields[people]=nope', @TEST_HEADERS );
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

done_testing;
