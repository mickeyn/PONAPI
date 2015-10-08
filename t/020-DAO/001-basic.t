#!perl

use strict;
use warnings;

use Data::Dumper;
use YAML::XS;
use Path::Class;
use Scalar::Util qw[ blessed ];

use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('PONAPI::DAO::Repository::Mock');
}

my $articles = Load( scalar file('share/fixtures/articles.yml')->slurp );
my $comments = Load( scalar file('share/fixtures/comments.yml')->slurp );
my $people   = Load( scalar file('share/fixtures/people.yml'  )->slurp );

my $repository = PONAPI::DAO::Repository::Mock->new(
    rel_spec => {
        comments => {
            article => { has_one => 'articles' },
        },
        articles => { 
            author   => { has_one  => 'people'   },
            comments => { has_many => 'comments' },
        }
    },
    data => {
        articles => $articles,
        comments => $comments,
        people   => $people,  
    }
);
isa_ok($repository, 'PONAPI::DAO::Repository::Mock');

ok($repository->has_type('people'),   '... we have the people type');
ok($repository->has_type('articles'), '... we have the articles type');
ok($repository->has_type('comments'), '... we have the comments type');

ok(!$repository->has_type('widgets'), '... we do not have the widgets type');

is_deeply($repository->has_relationship(articles => 'author'   ), { has_one  => 'people'   }, '... we have the expected relationship');
is_deeply($repository->has_relationship(articles => 'comments' ), { has_many => 'comments' }, '... we have the expected relationship');
is_deeply($repository->has_relationship(comments => 'article'  ), { has_one  => 'articles' }, '... we have the expected relationship');

ok(!$repository->has_relationship(people   => 'articles' ), '... we do not have the relationship (as expected)');
ok(!$repository->has_relationship(comments => 'author' ), '... we do not have the relationship (as expected)');

my $dao = PONAPI::DAO->new( repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

my $doc = $dao->retrieve_all( type => 'people' );

ok(!blessed($doc), '.... the document we got is not blessed');
is(ref $doc, 'HASH', '.... the document we got is a HASH ref');

ok(exists $doc->{'jsonapi'}, '... we have a `jsonapi` key');
ok(exists $doc->{'data'}, '... we have a `data` key');
is(scalar keys %$doc, 2, '... only got 2 keys');

is(ref $doc->{'data'}, 'ARRAY', '.... the document->{data} we got is an ARRAY ref');

foreach my $person ( @{$doc->{'data'}} ) {
    is(ref $person, 'HASH', '.... the resource we got is a HASH ref');
    is($person->{type}, 'people', '... got the expected type');

    ok(exists $person->{id}, '... the `id` key exists');
    ok(exists $person->{attributes}, '... the `attributes` key exists');

    ok(exists $person->{attributes}->{name}, '... the attribute `name` key exists');
    ok(exists $person->{attributes}->{age}, '... the attribute `age` key exists');
    ok(exists $person->{attributes}->{gender}, '... the attribute `gender` key exists');
}


done_testing;


