#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use JSON::XS;

BEGIN {
    use_ok('PONAPI::Request::Body');
}

my $payload = JSON::XS->new->utf8->decode(q[
{
  "data": {
    "type": "photos",
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "attributes": {
      "title": "Ember Hamster",
      "src": "http://example.com/images/productivity.png"
    }
  }
}
]);

my $body = PONAPI::Request::Body->new( $payload );
isa_ok($body, 'PONAPI::Request::Body');

is($body->type, 'photos', '... got the type expected');
is($body->id, '550e8400-e29b-41d4-a716-446655440000', '... got the ID expected');

ok($body->has_attribute('title'), '... yes, we have a title attribute');
ok($body->has_attribute('src'), '... yes, we have a src attribute');
ok(!$body->has_attribute('something'), '... no, we do not have a something attribute');

is($body->get_attribute('title'), 'Ember Hamster', '... yes, we have the correct value for title attribute');
is($body->get_attribute('src'), 'http://example.com/images/productivity.png', '... yes, we have the correct value for src attribute');

is_deeply([ sort $body->get_attribute_keys ], [ 'src', 'title' ], '... got the right attribute keys');
is_deeply(
    $body->attributes,
    {
        title => 'Ember Hamster',
        src   => 'http://example.com/images/productivity.png'
    },
    '... got the right attributes'
);

is_deeply($body->relationships, {}, '... got the right (empty) relationships');

ok(!$body->has_relationship('foo'), '... no relationships called foo');

done_testing;
