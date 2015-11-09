#!perl

use strict;
use warnings;

use Data::Dumper;
use Scalar::Util qw[ blessed ];

use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('Test::PONAPI::DAO::Repository::MockDB');
    use_ok('Test::PONAPI::DAO::Repository::MockDB::Loader');
}

my $loader = Test::PONAPI::DAO::Repository::MockDB::Loader->new;

my $repository = Test::PONAPI::DAO::Repository::MockDB->new( dbh => $loader->dbh );
isa_ok($repository, 'Test::PONAPI::DAO::Repository::MockDB');

ok($repository->has_type('people'),   '... we have the people type');
ok($repository->has_type('articles'), '... we have the articles type');
ok($repository->has_type('comments'), '... we have the comments type');

ok(!$repository->has_type('widgets'), '... we do not have the widgets type');

ok($repository->has_relationship(articles => 'authors'),   '... we have the expected (articles => author) relationship');
ok($repository->has_relationship(articles => 'comments'),  '... we have the expected (articles => comments) relationship');
ok($repository->has_relationship(comments => 'articles'),  '... we have the expected (comments => article) relationship');
ok($repository->has_relationship(people   => 'articles'),  '... we have the (people => articles) relationship');

ok(!$repository->has_relationship(comments => 'authors'),  '... we do not have the (comments => author) relationship (as expected)');

my $dao = PONAPI::DAO->new( repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

subtest '... retrieve all' => sub {
    my $doc = $dao->retrieve_all( type => 'people' );

    ok(!blessed($doc), '... the document we got is not blessed');
    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    ok(exists $doc->{'jsonapi'}, '... we have a `jsonapi` key');
    ok(exists $doc->{'data'}, '... we have a `data` key');
    is(scalar keys %$doc, 2, '... only got 2 keys');

    is(ref $doc->{'data'}, 'ARRAY', '.... the document->{data} we got is an ARRAY ref');

    foreach my $person ( @{$doc->{'data'}} ) {
        is(ref $person, 'HASH', '... the resource we got is a HASH ref');
        is($person->{type}, 'people', '... got the expected type');

        ok(exists $person->{id}, '... the `id` key exists');
        ok(exists $person->{attributes}, '... the `attributes` key exists');

        ok(exists $person->{attributes}->{name}, '... the attribute `name` key exists');
        ok(exists $person->{attributes}->{age}, '... the attribute `age` key exists');
        ok(exists $person->{attributes}->{gender}, '... the attribute `gender` key exists');
    }
};

subtest '... retrieve' => sub {
    my $doc = $dao->retrieve( type   => 'articles', id => 2,
                              fields => { articles => [qw< title >] } );

    ok(!blessed($doc), '... the document we got is not blessed');
    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    ok($data, '... the document has a `data` key');
    ok(ref $data eq 'HASH', '... the document has one resource');

    ok(scalar keys %{ $data->{attributes} } == 1, '... one key in `attributes`');
    ok(exists $data->{attributes}->{title}, '... the attribute `title` key exists');

};

subtest '... retrieve relationships' => sub {
    my $doc = $dao->retrieve_relationships( type => 'articles', id => 2,
                                            rel_type => 'comments' );

    ok(!blessed($doc), '... the document we got is not blessed');
    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    ok(ref $data eq 'ARRAY', '... the document has multiple resources');
    ok(scalar @{$data} == 2, '... the document has 2 resources');
    ok(ref $data->[0] eq 'HASH', '... the 1st resouce is a HASH ref');
    ok(exists $data->[0]->{type}, '... the 1st resouce has a `type` key');
    ok(exists $data->[0]->{id}, '... the 1st resouce has an `id` key');

};

subtest '... retrieve by relationship' => sub {
    my $doc = $dao->retrieve_by_relationship(
        type => 'articles',
        id   => 2,
        rel_type => 'authors'
    );

    ok(!blessed($doc), '... the document we got is not blessed');
    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    ok(ref $data eq 'HASH', '... the document has one resource');
    ok(exists $data->{attributes}->{age}, '... the attribute `age` key exists');
    ok(exists $data->{attributes}->{gender}, '... the attribute `age` key exists');
    ok(exists $data->{attributes}->{name}, '... the attribute `age` key exists');

};


done_testing;
