#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Links');
}

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Builder::Links->new;
    isa_ok( $builder, 'PONAPI::Builder::Links');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    can_ok( $builder, $_ ) foreach qw[
        has_links
        has_link

        get_link

        add_link
        add_links
        add_meta

        build
    ];

};

done_testing;
