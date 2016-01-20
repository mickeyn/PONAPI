# ABSTRACT: request - role - has fields
package PONAPI::Client::Request::Role::HasFields;

use Moose::Role;

has fields => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_fields',
);

no Moose::Role; 1;

__END__
