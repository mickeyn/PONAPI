# ABSTRACT: request - create relationships
package PONAPI::Client::Request::CreateRelationships;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPOST',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasRelationshipType',
     'PONAPI::Client::Request::Role::HasOneToManyData',
     'PONAPI::Client::Request::Role::HasUriRelationships';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
