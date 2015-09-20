#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource::ID');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Resource::ID->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($b, 'PONAPI::Builder::Resource::ID');
    does_ok($b, 'PONAPI::Builder');

    is($b->id, '1', '... got the expected id');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Builder::Resource::ID->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Resource::ID->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Resource::ID->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

done_testing;
