#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Links::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Links::Builder->new(
        # ...
    );
    isa_ok($b, 'PONAPI::Links::Builder');

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Links::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;