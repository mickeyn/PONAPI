#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok( $builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    is($builder->id, '1', '... got the expected id');
    is($builder->type, 'articles', '... got the expected type');

    can_ok( $builder, $_ ) foreach qw[
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
        add_meta

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Builder::Resource->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Resource->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Resource->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

done_testing;
