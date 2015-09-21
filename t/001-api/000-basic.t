#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Builder::Document')
}

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;

my $EXPECTED = $JSON->decode(q[
{
    "data":{
        "type":"articles",
        "id":"1",
        "attributes":{
            "title":"Rails is Omakase",
            "body":"WHAT?!?!?!"
        },
        "relationships":{
            "author":{
                "links":{
                    "self":"/articles/1/relationships/author",
                    "related":"/articles/1/author"
                },
                "data":{
                    "type":"people",
                    "id":"9"
                }
            }
        }
    },
    "included":[
        {
            "type":"people",
            "id":"9",
            "attributes":{
                "name":"DHH"
            },
            "links":{
                "self":"/people/9"
            }
        }
    ]
}
]);

my $GOT = PONAPI::Builder::Document
    ->new
        ->add_resource( id => 1, type => 'articles' )
            ->add_attributes(
                title => 'Rails is Omakase',
                body  => 'WHAT?!?!?!'
            )
            ->add_relationship( 'author' => ( id => 9, type => 'people' ) )
                ->add_links(
                    self    => '/articles/1/relationships/author',
                    related => '/articles/1/author'
                )
            ->parent
        ->parent
        ->add_included( id => 9, type => 'people' )
            ->add_attributes( name => 'DHH' )
            ->add_link( self => '/people/9' )
        ->parent
    ->build
;

#warn Dumper $GOT;
is_deeply( $GOT, $EXPECTED, '... got the expected result' );

## ----------------------------------------------------------------------------

done_testing;
