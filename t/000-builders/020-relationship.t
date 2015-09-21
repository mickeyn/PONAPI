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

    my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    isa_ok($b->resource_id_builder, 'PONAPI::Builder::Resource::Identifier');
    does_ok($b->resource_id_builder, 'PONAPI::Builder');

    is($b->resource_id_builder->id, 10, '... got the ID we expected');
    is($b->resource_id_builder->type, 'foo', '... got the type we expected');

    can_ok( $b, $_ ) foreach qw[
        resource_id_builder

        links_builder
        add_link
        add_links

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Builder::Relationship->new },
        qr/^Attribute \(.+\) does not pass the type constraint /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( id => '1' ) },
        qr/^Attribute \(type\) does not pass the type constraint /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( type => 'articles' ) },
        qr/^Attribute \(id\) does not pass the type constraint /,
        '... got the error we expected'
    );

};

subtest '... testing links sub-building' => sub {
    my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');

    ok(!$b->has_links, "new relationship should not have links");

    $b->add_links(
        related => "/related/2",
        self    => "/self/1",
    );

    ok($b->has_links, "relationship should now have links");

    is_deeply(
        $b->build,
        {
            data  => { id => 10, type => 'foo' },
            links => {
                self    => "/self/1",
                related => "/related/2",
            }
        },
        '... Relationship with links',
    );
};

done_testing;
