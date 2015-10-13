#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Client::Request::Retrieve');
}

=pod

TODO:

=cut

my %TEST_DATA = (
    type    => 'articles',
    id      => 2,
    fields  => { articles => [qw< title body >] },
    include => [qw< comments author >],
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::Retrieve->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::Retrieve');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsGET');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasId');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFields');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFilter');
    does_ok($req, 'PONAPI::Client::Request::Role::HasInclude');
    does_ok($req, 'PONAPI::Client::Request::Role::HasPage');

    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::Retrieve->new( %TEST_DATA );

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/articles/2',
        query_string => 'fields%5Barticles%5D=title%2Cbody&include=comments%2Cauthor',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
