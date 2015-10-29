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

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Builder::Relationship->new( resource => { id => 10, type => 'foo' } );
    isa_ok( $builder, 'PONAPI::Builder::Relationship');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    can_ok( $builder, $_ ) foreach qw[
        has_resource
        has_resources

        links_builder
        add_link
        add_links
        add_meta

        build
    ];

};

done_testing;
