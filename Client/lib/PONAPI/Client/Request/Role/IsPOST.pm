# ABSTRACT: request - role - is POST
package PONAPI::Client::Request::Role::IsPOST;

use Moose::Role;

sub method { 'POST' }

no Moose::Role; 1;

__END__
