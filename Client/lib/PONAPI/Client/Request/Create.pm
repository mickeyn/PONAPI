# ABSTRACT: request - create
package PONAPI::Client::Request::Create;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPOST',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasData',
     'PONAPI::Client::Request::Role::HasUriAll';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
