#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Client::Request::RetrieveAll');
}

=pod

TODO:

=cut

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::RetrieveAll->new(
        type => 'articles',
    );

    isa_ok( $req, 'PONAPI::Client::Request::RetrieveAll');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsGET');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFields');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFilter');
    does_ok($req, 'PONAPI::Client::Request::Role::HasInclude');
    does_ok($req, 'PONAPI::Client::Request::Role::HasPage');

    can_ok( $req, 'method' );
    can_ok( $req, 'path' );
    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::RetrieveAll->new(
        type    => 'articles',
        fields  => { articles => [qw< title body >] },
        filter  => { id => [ 2, 3 ] },
        include => [qw< comments author >],
    );

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/articles',
        query_string => 'filter%5Bid%5D=2%2C3&fields%5Barticles%5D=title%2Cbody&include=comments%2Cauthor',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
