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
    my $doc = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok($doc, 'PONAPI::Builder::Relationship');
    does_ok($doc, 'PONAPI::Builder');
    does_ok($doc, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Builder::Role::HasMeta');

    ok($doc->has_resource, '... we have a resource');
    ok(!$doc->has_resources, '... we do not have a resources');

    is_deeply(
        $doc->build,
        {
            data  => { id => 10, type => 'foo' },
        },
        '... Relationship with links',
    );
};

done_testing;
