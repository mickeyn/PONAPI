#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Document->new;
    isa_ok( $b, 'PONAPI::Builder::Document');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    ok(!$b->is_collection, '... this document is not a collection');

    ok(!$b->has_resource, '... the document does not have a resource');
    ok(!$b->has_resources, '... the document does not have a resource');

    my $r = $b->add_resource( type => 'article', id => 10 );
    isa_ok($r, 'PONAPI::Builder::Resource');

    like(
        exception { $b->add_resource( type => 'article', id => 11 ) },
        qr/^Cannot add more then one resource unless the Document is in collection mode/,
        '... could not add another resource with not a collection'
    );

    ok($b->has_resource, '... the document now has a resource');
    ok(!$b->has_resources, '... the document does not have a resource');

    is_deeply(
        $b->build,
        {
            jsonapi => { version => '1.0' },
            data    => { type => 'article', id => 10 },
        },
        '... got the build product we expected'
    );

};

done_testing;
