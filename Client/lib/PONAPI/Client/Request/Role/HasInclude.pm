# ABSTRACT: request - role - has include
package PONAPI::Client::Request::Role::HasInclude;

use Moose::Role;

has include => (
    is        => 'ro',
    isa       => 'ArrayRef',
    predicate => 'has_include',
);

no Moose::Role; 1;

__END__
