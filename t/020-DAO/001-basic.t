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
    data => {
        articles => $articles,
        comments => $comments,
        people   => $people,  
    }
);
isa_ok($repository, 'PONAPI::DAO::Repository::Mock');

my $dal = PONAPI::DAO->new( repository => $repository );
isa_ok($dal, 'PONAPI::DAO');

warn Dumper $dal->retrieve_all( type => 'people' );

done_testing;