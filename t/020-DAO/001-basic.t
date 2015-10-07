#!perl

use strict;
use warnings;

use Data::Dumper;
use YAML::XS;
use Path::Class;

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

ok($repository->has_relationship('articles' => author   => { has_one  => 'people'   } ), '... we have the expected relationship');
ok($repository->has_relationship('articles' => comments => { has_many => 'comments' } ), '... we have the expected relationship');
ok($repository->has_relationship('comments' => article  => { has_one  => 'articles' } ), '... we have the expected relationship');

ok(!$repository->has_relationship('people'   => articles => { has_many => 'articles' } ), '... we do not have the relationship (as expected)');
ok(!$repository->has_relationship('comments' => author   => { has_one  => 'people'   } ), '... we do not have the relationship (as expected)');

my $dal = PONAPI::DAO->new( repository => $repository );
isa_ok($dal, 'PONAPI::DAO');

warn Dumper $dal->retrieve_all( type => 'people' );

done_testing;