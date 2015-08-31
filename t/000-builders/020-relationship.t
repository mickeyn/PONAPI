#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Relationship::Builder');
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

done_testing;