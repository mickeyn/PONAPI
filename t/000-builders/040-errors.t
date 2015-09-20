#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Errors::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Errors::Builder->new;
    isa_ok($b, 'PONAPI::Errors::Builder');

    can_ok( $b, $_ ) foreach qw[
        add_error
        has_errors

        build
    ];

};

done_testing;
