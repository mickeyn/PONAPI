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

    ok(!$b->has_id, '... no id specified');
    is($b->action, 'GET', '... got the expected action');
    is($b->type, 'articles', '... got the expected type');

    can_ok( $b, $_ ) foreach qw[
        id
        has_id

        action 
        type

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

        build
    ];

};

subtest '... testing constructor w/id' => sub {

    my $b = PONAPI::Document::Builder->new(
        id     => '10',
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    ok($b->has_id, '... we have an id specified');
    is($b->id, '10', '... and the ID is what we expected');
    is($b->action, 'GET', '... got the expected action');
    is($b->type, 'articles', '... got the expected type');
};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder->new },
        qr/^Attribute \(.+\) is required at constructor PONAPI\:\:Document\:\:Builder\:\:new/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( action => 'GET' ) },
        qr/^Attribute \(type\) is required at constructor PONAPI\:\:Document\:\:Builder\:\:new/,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder->new( type => 'articles' ) },
        qr/^Attribute \(action\) is required at constructor PONAPI\:\:Document\:\:Builder\:\:new/,
        '... got the error we expected'
    );

};

done_testing;