package PONAPI::DAL::Schema;
use Moose::Role;

requires 'retrieve';
requires 'retrieve_all';
requires 'retrieve_relationship';
requires 'retrieve_by_relationship';
requires 'create';
requires 'update';
requires 'delete';

no Moose::Role;

1;