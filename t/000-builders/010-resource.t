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
        id   => '1',        
        type => 'articles',
    );
    isa_ok($b, 'PONAPI::Resource::Builder');

    is($b->id, '1', '... got the expected id');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        add_attributes
        has_attributes
        get_attributes

        has_relationships

        add_links
        has_links

        add_meta
        has_meta
        get_meta
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Resource::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Resource::Builder->new( id => '1' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Resource::Builder->new( type => 'articles' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;