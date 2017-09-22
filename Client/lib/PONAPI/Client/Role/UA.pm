package PONAPI::Client::Role::UA;

use Moose::Role;

requires 'send_http_request';
requires 'before_request';
requires 'after_request';

no Moose::Role;
1;
