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
        action => 'GET', 
        type   => 'articles',
        data   => { id => '1' }
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    is($b->action, 'GET', '... got the expected action');
    is($b->type, 'articles', '... got the expected type');
    is_deeply($b->data, { id => '1' }, '... got the expected data');

    can_ok( $_ ) foreach qw[
        add_error
        has_error 
        
        add_data
        has_data

        add_meta
        has_meta

        add_links
        has_links

        add_jsonapi
        has_jsonapi

        add_included
        has_included
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder->new },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( action => 'GET' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( action => 'GET', type => 'articles' ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( action => 'GET', type => 'articles', data => [] ) },
        qr/^Whoops/,
        '... got the error we expected'
    );

};

done_testing;