#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Builder::Errors');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Errors->new;
    isa_ok($b, 'PONAPI::Builder::Errors');

    can_ok( $b, $_ ) foreach qw[
        add_error
        has_errors

        build
    ];

};

done_testing;
