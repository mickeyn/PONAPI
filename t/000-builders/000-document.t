#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Document->new;
    isa_ok( $b, 'PONAPI::Builder::Document' );
    does_ok( $b, 'PONAPI::Builder' );
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    can_ok( $b, $_ ) foreach qw[
        add_included
        has_included

        add_resource
        has_resource

        errors_builder

        links_builder
        add_link
        add_links

        build
    ];

};

done_testing;
