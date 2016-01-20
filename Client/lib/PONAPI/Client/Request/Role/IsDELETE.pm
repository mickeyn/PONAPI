# ABSTRACT: request - role - is DELETE
package PONAPI::Client::Request::Role::IsDELETE;

use Moose::Role;

sub method { 'DELETE' }

no Moose::Role; 1;

__END__
