# ABSTRACT: request - update relationships
package PONAPI::Client::Request::UpdateRelationships;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPATCH',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasRelationshipType',
     'PONAPI::Client::Request::Role::HasRelationshipUpdateData',
     'PONAPI::Client::Request::Role::HasUriRelationships';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
