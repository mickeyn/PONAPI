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
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    is($b->action, 'GET', '... got the expected action');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        add_errors
        has_errors 
        
        add_data
        has_data

        add_meta
        has_meta

        add_links
        has_links

        add_included
        has_include
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder->new },
        qr/^\[PONAPI\:\:Document\:\:Builder\] new\: missing action/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( action => 'GET' ) },
        qr/^\[PONAPI\:\:Document\:\:Builder\] new\: missing type/,
        '... got the error we expected'
    );

};

done_testing;