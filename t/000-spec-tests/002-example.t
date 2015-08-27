#!perl -w

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Resource');
}

# Basic Resource object ...

my $JSON = q[
{
  "type": "articles",
  "id": "1",
  "attributes": {
    "title": "Rails is Omakase"
  },
  "relationships": {
    "author": {
      "links": {
        "self": "/articles/1/relationships/author",
        "related": "/articles/1/author"
      },
      "data": { "type": "people", "id": "9" }
    }
  }
}
];

subtest '... test basic object construction' => sub {

    my $ident = PONAPI::Resource->new(
        id            => '1',
        type          => 'articles',
        attributes    => { title => 'Rails is Omakase' },
        relationships => {
            author => {
                data  => { type => 'people', id => '9' },
                links => {
                    self    => '/articles/1/relationships/author',
                    related => '/articles/1/author',
                }
            }
        }
    );
    isa_ok($ident, 'PONAPI::Resource');

    is($ident->id, '1', '... got the expected ID');
    is($ident->type, 'articles', '... got the expected type');
};

subtest '... test object construction errors' => sub {

    like(
        exception { PONAPI::Resource->new },
        qr/^Attribute \(.*\) is required at constructor PONAPI\:\:Resource\:\:new/,
        '... go the error we expected'
    );

    like(
        exception { PONAPI::Resource->new( id => '1' ) },
        qr/^Attribute \(type\) is required at constructor PONAPI\:\:Resource\:\:new/,
        '... go the error we expected'
    );

    like(
        exception { PONAPI::Resource->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at constructor PONAPI\:\:Resource\:\:new/,
        '... go the error we expected'
    );
};

done_testing;