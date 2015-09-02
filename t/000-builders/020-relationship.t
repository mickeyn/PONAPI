#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Relationship::Builder');
    use_ok('PONAPI::Links::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Relationship::Builder->new;
    isa_ok($b, 'PONAPI::Relationship::Builder');

    can_ok( $b, $_ ) foreach qw[
        add_links
        has_links

        add_meta
        has_meta

        add_data
        has_data

        build
    ];

};

subtest '... testing constructor errors' => sub {

    is(
        exception { PONAPI::Relationship::Builder->new },
        undef,
        '... got the (lack of) error we expected'
    );

};

subtest '... testing links sub-building' => sub {
    my $b = PONAPI::Relationship::Builder->new;

    $b->add_links({
        related => "/related/2",
        self    => "/self/1",
    });

    is_deeply(
        $b->build,
        {
            links => {
                self    => "/self/1",
                related => "/related/2",
            }
        },
        '... Relationship with links',
    );
};

subtest '... testing build errors' => sub {

    subtest '... for empty Relationship' => sub {
        my $b = PONAPI::Relationship::Builder->new;
        is_deeply(
            $b->build,
            {
                errors => [{
                    detail => 'Relationship should contain at least one of "links", "data" or "meta"',
                }],
            },
            '... No empty Relationship',
        );
    };

    subtest '... links' => sub {
        my $b = PONAPI::Relationship::Builder->new;

        $b->add_links({
            about => "/about/something",
        });

        is_deeply(
            $b->build,
            {
                errors => [{
                    detail => 'Relationship links should contain at least one of "self" or "related"',
                }],
            },
            '... Relationship with links error',
        );
    };
};

done_testing;
