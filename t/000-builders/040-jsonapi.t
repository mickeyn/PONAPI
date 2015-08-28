#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::JSONAPI::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::JSONAPI::Builder->new(
        # ...
    );
    isa_ok($b, 'PONAPI::JSONAPI::Builder');

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::JSONAPI::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;