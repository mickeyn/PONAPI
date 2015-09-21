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

# http://jsonapi.org/

my $JSON = JSON::XS->new->utf8;

# the expected result
my $EXPECTED = $JSON->decode(q[
{
    "links":{
        "self":"http://example.com/articles",
        "next":"http://example.com/articles?page[offset]=2",
        "last":"http://example.com/articles?page[offset]=10"
    },
    "data":[
        {
            "type":"articles",
            "id":"1",
            "attributes":{
                "title":"JSON API paints my bikeshed!"
            },
            "relationships":{
                "author":{
                    "links":{
                        "self":"http://example.com/articles/1/relationships/author",
                        "related":"http://example.com/articles/1/author"
                    },
                    "data":{
                        "type":"people",
                        "id":"9"
                    }
                },
                "comments":{
                    "links":{
                        "self":"http://example.com/articles/1/relationships/comments",
                        "related":"http://example.com/articles/1/comments"
                    },
                    "data":[
                        {
                            "type":"comments",
                            "id":"5"
                        },
                        {
                            "type":"comments",
                            "id":"12"
                        }
                    ]
                }
            },
            "links":{
                "self":"http://example.com/articles/1"
            }
        }
    ],
    "included":[
        {
            "type":"people",
            "id":"9",
            "attributes":{
                "first-name":"Dan",
                "last-name":"Gebhardt",
                "twitter":"dgeb"
            },
            "links":{
                "self":"http://example.com/people/9"
            }
        },
        {
            "type":"comments",
            "id":"5",
            "attributes":{
                "body":"First!"
            },
            "relationships":{
                "author":{
                    "data":{
                        "type":"people",
                        "id":"2"
                    }
                }
            },
            "links":{
                "self":"http://example.com/comments/5"
            }
        },
        {
            "type":"comments",
            "id":"12",
            "attributes":{
                "body":"I like XML better"
            },
            "relationships":{
                "author":{
                    "data":{
                        "type":"people",
                        "id":"9"
                    }
                }
            },
            "links":{
                "self":"http://example.com/comments/12"
            }
        }
    ]
}
]);

my $GOT;

TODO: { 
    local $TODO = '... need to write this test';
    is_deeply( $GOT, $EXPECTED, '... got the expected result' );
}

done_testing;
