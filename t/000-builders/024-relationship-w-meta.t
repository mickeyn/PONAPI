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

subtest '... testing meta sub-building' => sub {
    my $builder = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok( $builder, 'PONAPI::Builder::Relationship');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    ok(!$builder->has_meta, "... new document shouldn't have meta");

    is(
        exception { $builder->add_meta( info => "a meta info" ) },
        undef,
        '... got the (lack of) error we expected'
    );

    ok($builder->has_meta, "... the document should have meta now");

    is_deeply(
        $builder->build,
        {
            data  => { id => 10, type => 'foo' },
            meta  => { info => "a meta info" }
        },
        '... Relationship with meta',
    );
};

done_testing;
