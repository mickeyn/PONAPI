# ABSTRACT: request - role - has one-to-many data
package PONAPI::Client::Request::Role::HasOneToManyData;

use Moose::Role;

has data => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
);

no Moose::Role; 1;
__END__
