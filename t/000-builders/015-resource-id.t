#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::ResourceID::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::ResourceID::Builder->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($b, 'PONAPI::ResourceID::Builder');
    does_ok($b, 'PONAPI::Builder');

    is($b->id, '1', '... got the expected id');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::ResourceID::Builder->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::ResourceID::Builder->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::ResourceID::Builder->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

done_testing;
