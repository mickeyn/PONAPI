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

subtest '... testing relationship with meta' => sub {
    my $doc = PONAPI::Builder::Document->new;
    isa_ok( $doc, 'PONAPI::Builder::Document');
    does_ok($doc, 'PONAPI::Builder');
    does_ok($doc, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Builder::Role::HasMeta');

    ok(!$doc->has_meta, "... new document shouldn't have meta");

    is(
        exception { $doc->add_meta( info => "a meta info" ) },
        undef,
        '... got the (lack of) error we expected'
    );

    ok($doc->has_meta, "... the document should have meta now");

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            meta    => { info => "a meta info" }
        },
        '... the document now has meta',
    );
};

subtest '... testing relationship with multiple meta' => sub {
    my $doc = PONAPI::Builder::Document->new;
    isa_ok( $doc, 'PONAPI::Builder::Document');
    does_ok($doc, 'PONAPI::Builder');
    does_ok($doc, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Builder::Role::HasMeta');

    ok(!$doc->has_meta, "... new document shouldn't have meta");

    is(
        exception { $doc->add_meta(info => "a meta info") },
        undef,
        '... got the (lack of) error we expected'
    );

    ok($doc->has_meta, "... the document should have meta now");

    is(
        exception { $doc->add_meta(physic => "a meta physic") },
        undef,
        '... got the (lack of) error we expected'
    );

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            meta    => {
                info => "a meta info",
                physic => "a meta physic",
            }
        },
        '... document with meta',
    );
};

subtest '... testing relationship with meta object' => sub {
    my $doc = PONAPI::Builder::Document->new;
    isa_ok( $doc, 'PONAPI::Builder::Document');
    does_ok($doc, 'PONAPI::Builder');
    does_ok($doc, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Builder::Role::HasMeta');

    ok(!$doc->has_meta, "... new document shouldn't have meta");

    is(
        exception { $doc->add_meta(
            foo => {
                info => "a foo info",
            }
        )},
        undef,
        '... got the (lack of) error we expected'
    );

    ok($doc->has_meta, "... the document should have meta now");

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            meta    => {
                foo => {
                    info => "a foo info",
                }
            }
        },
        '... document with meta object',
    );
};

done_testing;
