# ABSTRACT: request - delete
package PONAPI::Client::Request::Delete;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsDELETE',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasUriSingle';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
