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
        id     has_id
        status has_status
        code   has_code
        title  has_title
        detail has_detail
        source has_source

        add_source

        build
    ];

};

done_testing;
