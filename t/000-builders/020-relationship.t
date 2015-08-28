#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Relationship::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Relationship::Builder->new(
        # ...
    );
    isa_ok($b, 'PONAPI::Relationship::Builder');

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Relationship::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;