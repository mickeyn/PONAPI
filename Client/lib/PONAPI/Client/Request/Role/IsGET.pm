# ABSTRACT: request - role - is GET
package PONAPI::Client::Request::Role::IsGET;

use Moose::Role;

sub method { 'GET' }

no Moose::Role; 1;

__END__
