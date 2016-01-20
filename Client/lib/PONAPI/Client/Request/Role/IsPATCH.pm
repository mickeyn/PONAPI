# ABSTRACT: request - role - is PATCH
package PONAPI::Client::Request::Role::IsPATCH;

use Moose::Role;

sub method { 'PATCH' }

no Moose::Role; 1;

__END__
