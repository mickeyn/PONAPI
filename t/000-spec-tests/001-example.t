#!perl -w

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Resource::Identifier');
}

# Resource Identifier Object ...

my $JSON = q[
{
  "data": {
    "type": "articles",
    "id": "1"
  }
}
];

subtest '... test basic object construction' => sub {

    my $ident = PONAPI::Resource::Identifier->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($ident, 'PONAPI::Resource::Identifier');

    is($ident->id, '1', '... got the expected ID');
    is($ident->type, 'articles', '... got the expected type');
};

subtest '... test object construction errors' => sub {

    like(
        exception { PONAPI::Resource::Identifier->new },
        qr/^Attribute \(.*\) is required at constructor PONAPI\:\:Resource\:\:Identifier\:\:new/,
        '... go the error we expected'
    );

    like(
        exception { PONAPI::Resource::Identifier->new( id => '1' ) },
        qr/^Attribute \(type\) is required at constructor PONAPI\:\:Resource\:\:Identifier\:\:new/,
        '... go the error we expected'
    );

    like(
        exception { PONAPI::Resource::Identifier->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at constructor PONAPI\:\:Resource\:\:Identifier\:\:new/,
        '... go the error we expected'
    );
};

done_testing;