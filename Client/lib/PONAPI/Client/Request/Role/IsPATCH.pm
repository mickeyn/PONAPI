# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Role::IsPATCH;

use Moose::Role;

sub method { 'PATCH' }

no Moose::Role; 1;

__END__
