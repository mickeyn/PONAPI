#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Errors');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Builder::Errors->new;
    isa_ok( $builder, 'PONAPI::Builder::Errors');
    does_ok($builder, 'PONAPI::Builder');

    can_ok( $builder, $_ ) foreach qw[
        add_error
        has_errors

        build
    ];

};

done_testing;
