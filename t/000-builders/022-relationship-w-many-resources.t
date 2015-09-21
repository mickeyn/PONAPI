#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Relationship');
}

=pod

TODO:

=cut


subtest '... testing relationship with multiple data' => sub {
    my $b = PONAPI::Builder::Relationship->new( 
        resources => [
            { id => "1", type => "articles" }, 
            { id => "1", type => "nouns" }
        ]
    );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($b, 'PONAPI::Builder::Role::HasMeta');   

    ok($b->has_resource, '... we have a resource');
    ok($b->has_resources, '... we have many resources');

    is_deeply(
        $b->build,
        {
            data => [
                { id => "1", type => "articles" }, 
                { id => "1", type => "nouns" },
            ]
        },
        '... Relationship with multiple data',
    );
};

done_testing;
