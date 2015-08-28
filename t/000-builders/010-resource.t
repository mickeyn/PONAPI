#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Resource::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Resource::Builder->new(
        # ...
    );
    isa_ok($b, 'PONAPI::Resource::Builder');

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Resource::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;