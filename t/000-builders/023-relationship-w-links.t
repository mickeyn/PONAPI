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

subtest '... testing links sub-building' => sub {
    my $builder = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok( $builder, 'PONAPI::Builder::Relationship');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    ok(!$builder->has_links, "new relationship should not have links");

    $builder->add_links(
        related => "/related/2",
        self    => "/self/1",
    );

    ok($builder->has_links, "relationship should now have links");

    is_deeply(
        $builder->build,
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
