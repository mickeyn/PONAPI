#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource');
}

subtest '... adding attributes to resource' => sub {

    my $builder = PONAPI::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    ok(!$builder->has_links, "new resource should not have links");

    $builder->add_links(
        related => "/related/2",
        self    => "/self/1",
    );

    ok($builder->has_links, "resource should now have links");

    is_deeply(
        $builder->build,
        {
            id   => '1',
            type => 'articles',
            links => {
                self    => "/self/1",
                related => "/related/2",
            }
        },
        '... built as expected'
    )
};


done_testing;
