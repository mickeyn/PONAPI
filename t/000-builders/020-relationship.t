#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Relationship');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    can_ok( $b, $_ ) foreach qw[
        has_resource
        has_resources

        links_builder
        add_link
        add_links
        add_meta

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Builder::Relationship->new( resource => {} ) },
        qr/^Attribute \(.+\) is required /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( resource => { id => '1' } ) },
        qr/^Attribute \(type\) is required /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( resource => { type => 'articles' } ) },
        qr/^Attribute \(id\) is required /,
        '... got the error we expected'
    );

};

done_testing;
