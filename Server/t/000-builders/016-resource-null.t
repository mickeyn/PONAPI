#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource::Null');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $doc = PONAPI::Builder::Resource::Null->new();

    isa_ok( $doc, 'PONAPI::Builder::Resource::Null');
    does_ok($doc, 'PONAPI::Builder');

    can_ok( $doc, 'build' );

};

subtest '... testing build output' => sub {

    my $doc = PONAPI::Builder::Resource::Null->new();

    my $EXPECTED = undef;

    my $GOT = $doc->build;

    is( $GOT, $EXPECTED, 'null resource builds into undef' );

};

done_testing;
