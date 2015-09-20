#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Resource::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Resource::Builder->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($b, 'PONAPI::Resource::Builder');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Role::HasLinksBuilder');

    is($b->id, '1', '... got the expected id');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        add_attribute
        add_attributes
        has_attributes
        has_attribute_for

        add_relationship
        has_relationships
        has_relationship_for

        links_builder
        add_link
        add_links

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Resource::Builder->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Resource::Builder->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Resource::Builder->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

done_testing;
