#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

subtest '... creating a document with links' => sub {

    my $b = PONAPI::Builder::Document->new;
    isa_ok( $b, 'PONAPI::Builder::Document');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');

    $b->add_links(
        self    => "http://example.com/articles/1",
        related => {
            href => "http://example.com/articles/1/author",
            meta => { info => "a meta info" }
        },
    );

    is_deeply(
        $b->build,
        {
            jsonapi => { version => '1.0' },
            links   => {
                self    => "http://example.com/articles/1",
                related => {
                    href => "http://example.com/articles/1/author",
                    meta => { info => "a meta info" }
                },
            },
        },
        "... the document now has links",
    );
};


done_testing;
