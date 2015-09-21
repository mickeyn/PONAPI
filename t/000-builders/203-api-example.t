#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use Plack::Request;
use JSON::XS;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

=pod

URL: http://jsonapi.org/examples/#sparse-fieldsets

=cut

my $JSON = JSON::XS->new->utf8;

# the expected result
my $EXPECTED = $JSON->decode(q[
{
    "jsonapi":{"version":"1.0"},
    "data":[{
        "type":"articles",
        "id":"1",
        "attributes":{
            "title":"JSON API paints my bikeshed!",
            "body":"The shortest article. Ever.",
            "created":"2015-05-22 14:56:29",
            "updated":"2015-05-22 14:56:28"
        },
        "relationships":{
            "author":{
                "data":{
                    "id":"42",
                    "type":"people"
                }
            }
        }
    }],
    "included":[
        {
            "type":"people",
            "id":"42",
            "attributes":{
                "name":"John",
                "age":80,
                "gender":"male"
            }
        }
    ]
}
]);

# some data makers ...

sub fetch_action_and_type_from_request {
    my $r = shift;

    my $path = $r->path_info;
    $path =~ s/^\///;

    return ($r->method, $path);
}

sub fetch_all_articles {
    return (
        [
            1,                               # id
            'JSON API paints my bikeshed!',  # title
            'The shortest article. Ever.',   # body
            '2015-05-22 14:56:29',           # created
            '2015-05-22 14:56:28',           # updated
            42,                              # author_id
        ]
    )
}

sub fetch_author {
    my ($id) = @_;
    return (
        [
            42,     # id
            'John', # name
            80,     # age
            'male'  # gender
        ]
    )
}

=pod

REQUEST:

GET /articles?include=author

=cut

# the Plack request we will get ....

my $r = Plack::Request->new({
    REQUEST_METHOD => 'GET',
    PATH_INFO      => '/articles',
    QUERY_STRING   => 'include=author',
});

isa_ok($r, 'Plack::Request');
is($r->path_info, '/articles', '... got the right path info');
is($r->param('include'), 'author', '... got the expected include parameter');

# the Builder

my ($ACTION, $TYPE) = fetch_action_and_type_from_request( $r );

is($TYPE, 'articles', '... got the type we expected from the request');
is($ACTION, 'GET', '... got the action we expected from the request');

# the Builder

my $b = PONAPI::Builder::Document->new( is_collection => 1 );
isa_ok($b, 'PONAPI::Builder::Document');
does_ok( $b, 'PONAPI::Builder' );
does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');

ok($b->is_collection, '... we are a collection document');

# building the document

my @articles = fetch_all_articles;

foreach my $article ( @articles ) {
    my ($id, $title, $body, $created, $updated, $author_id) = @$article;

    $b->add_resource(
        # this is from the request ... hmm, feels odd
        type => $TYPE,
        # data from DB
        id => $id,
    )->add_attributes(
        title   => $title,
        body    => $body,
        created => $created,
        updated => $updated,
    )->add_relationship(
        author => { type => 'people', id => $author_id }
    );

    if ( my ($author) = fetch_author( $author_id ) ) {
        my ($id, $name, $age, $gender) = @$author;

        $b->add_included(
            type       => 'people',
            id         => $author_id,
        )->add_attributes(
            name   => $name,
            age    => $age,
            gender => $gender
        );
    }
}

my $GOT = $b->build;

#use Data::Dumper;
#warn Dumper $GOT;

is_deeply($EXPECTED, $GOT, '... does our result match?');

done_testing;

1;
