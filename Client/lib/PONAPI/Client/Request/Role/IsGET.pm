# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Role::IsGET;

use Moose::Role;

sub method { 'GET' }

no Moose::Role; 1;

__END__
