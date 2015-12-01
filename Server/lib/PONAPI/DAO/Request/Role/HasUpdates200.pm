package PONAPI::DAO::Request::Role::HasUpdates200;

use Moose::Role;

has 'respond_to_updates_with_200' => (
    is  => 'ro',
    isa => 'Bool',
);

no Moose::Role; 1;
