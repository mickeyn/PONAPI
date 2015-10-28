#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource');
}

my %TEST_DATA = (
    id   => '1',
    type => 'articles',
);

subtest '... adding relationship errors' => sub {

    my $builder = PONAPI::Builder::Resource->new( %TEST_DATA );
    like (
        exception { $builder->add_relationship("this should fail") },
        qr/^Relationship resource information must be a reference \(HASH or ARRAY\)/,
        '... got the error we expected'
    );

};

subtest '... adding relationship to resource' => sub {

    my $builder = PONAPI::Builder::Resource->new( %TEST_DATA );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    my $relationship_builder = $builder->add_relationship(
        'author' => { id => 5, type => 'person' }
    );
    isa_ok($relationship_builder, 'PONAPI::Builder::Relationship');
    does_ok($relationship_builder, 'PONAPI::Builder');
    does_ok($relationship_builder, 'PONAPI::Builder::Role::HasLinksBuilder');

    $relationship_builder->add_links(
        related => "/articles/1/related/person",
        self    => "/person/5",
    );

    is_deeply(
        $builder->build,
        {
            id   => '1',
            type => 'articles',
            relationships => {
                author => {
                    data => {
                        id => 5, type => 'person'
                    },
                    links => {
                        related => "/articles/1/related/person",
                        self    => "/person/5",
                    }
                }
            }
        },
        '... built as expected'
    );
};

subtest '... adding multiple relationship of same type to resource' => sub {

    my $builder = PONAPI::Builder::Resource->new( %TEST_DATA );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    my $relationship_builder = $builder->add_relationship(
        'comments' => { id => 5, type => 'comment' }
    );
    my $relationship_builder = $builder->add_relationship(
        'comments' => { id => 12, type => 'comment' }
    );
    isa_ok($relationship_builder, 'PONAPI::Builder::Relationship');
    does_ok($relationship_builder, 'PONAPI::Builder');
    does_ok($relationship_builder, 'PONAPI::Builder::Role::HasLinksBuilder');

    is_deeply(
        $builder->build,
        {
            id   => '1',
            type => 'articles',
            relationships => {
                comments => {
                    data => [
                        { id => 5, type => 'comment' },
                        { id => 12, type => 'comment' },
                    ],
                }
            }
        },
        '... built as expected'
    );
};

done_testing;
