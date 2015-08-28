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
        data => { type => 'articles', id => '1' }
    );
    isa_ok($b, 'PONAPI::Relationship::Builder');

    is_deeply($b->data, { type => 'articles', id => '1' }, '... got the expected data');

    can_ok( $_ ) foreach qw[
        add_links
        has_links

        add_meta
        has_meta
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Relationship::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;