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

    my $doc = PONAPI::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Builder::Document');
    does_ok($doc, 'PONAPI::Builder');
    does_ok($doc, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Builder::Role::HasMeta');

    is( $doc->version, '1.0', 'given version matches' );

    can_ok( $doc, $_ ) foreach qw[
        add_included
        has_included

        add_resource
        has_resource

        errors_builder

        links_builder
        add_link
        add_links
        add_meta

        is_collection

        build
    ];

};

done_testing;
