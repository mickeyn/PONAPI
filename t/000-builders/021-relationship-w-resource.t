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
    my $b = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    ok($b->has_resource, '... we have a resource');
    ok(!$b->has_resources, '... we do not have a resources');

    is_deeply(
        $b->build,
        {
            data  => { id => 10, type => 'foo' },
        },
        '... Relationship with links',
    );
};

done_testing;
