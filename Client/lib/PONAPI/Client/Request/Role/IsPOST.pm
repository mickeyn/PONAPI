# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Role::IsPOST;

use Moose::Role;

sub method { 'POST' }

no Moose::Role; 1;

__END__
