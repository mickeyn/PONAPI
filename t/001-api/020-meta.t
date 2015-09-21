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


=pod

TODO:{
    local $TODO = "... update to the new API";


    subtest '... testing relationship with meta' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(info => "a meta info") },
            undef,
            '... got the (lack of) error we expected'
        );

        ok($b->has_meta, "relationship should have meta");

        is_deeply(
            $b->build,
            {
                meta => { info => "a meta info", }
            },
            '... Relationship with meta',
        );
    };

    subtest '... testing relationship with multiple meta' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(info => "a meta info") },
            undef,
            '... got the (lack of) error we expected'
        );

        ok($b->has_meta, "relationship should have meta");

        is(
            exception { $b->add_meta(physic => "a meta physic") },
            undef,
            '... got the (lack of) error we expected'
        );

        is_deeply(
            $b->build,
            {
                meta => {
                    info => "a meta info",
                    physic => "a meta physic",
                }
            },
            '... Relationship with meta',
        );
    };

    subtest '... testing relationship with meta object' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(
                foo => {
                    info => "a foo info",
                }
            )},
            undef,
            '... got the (lack of) error we expected'
        );

        ok($b->has_meta, "relationship should have meta");

        is_deeply(
            $b->build,
            {
                meta => {
                    foo => {
                        info => "a foo info",
                    }
                }
            },
            '... Relationship with meta object',
        );
    };

}

=cut

done_testing;
