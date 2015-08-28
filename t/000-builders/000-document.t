#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Document::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Document::Builder->new(
        'GET', 
        'articles',
        { id => '1' }
    );
    isa_ok($b, 'PONAPI::Document::Builder');

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( 'GET' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( 'GET', 'articles' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( 'GET', 'articles', [] ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;