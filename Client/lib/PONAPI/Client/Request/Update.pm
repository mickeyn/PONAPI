# ABSTRACT: request - update
package PONAPI::Client::Request::Update;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPATCH',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasData',
     'PONAPI::Client::Request::Role::HasUriSingle';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
