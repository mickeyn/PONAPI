#!perl

use strict;
use warnings;

use Data::Dumper;
use YAML::XS;
use Path::Class;

use Test::More;

BEGIN {
    use_ok('PONAPI::DAL');
    use_ok('PONAPI::DAL::Schema::Mock');
}

my $articles = Load( scalar file('share/fixtures/articles.yml')->slurp );
my $comments = Load( scalar file('share/fixtures/comments.yml')->slurp );
my $people   = Load( scalar file('share/fixtures/people.yml'  )->slurp );

my $schema = PONAPI::DAL::Schema::Mock->new(
    data => {
        articles => $articles,
        comments => $comments,
        people   => $people,  
    }
);
isa_ok($schema, 'PONAPI::DAL::Schema::Mock');

my $dal = PONAPI::DAL->new( schema => $schema );
isa_ok($dal, 'PONAPI::DAL');

warn Dumper $dal->retrieve_all( type => 'people' );

done_testing;