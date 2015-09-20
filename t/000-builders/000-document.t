#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
	use_ok('PONAPI::Document::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

	my $b = PONAPI::Document::Builder->new;
	isa_ok( $b, 'PONAPI::Document::Builder' );
    does_ok( $b, 'PONAPI::Builder' );
    does_ok($b, 'PONAPI::Role::HasLinksBuilder');

	can_ok( $b, $_ ) foreach qw[
        add_included
        has_included

        resource_builder
        set_resource

        errors_builder

        links_builder
        add_link
        add_links      

        build
	];

};

done_testing;
