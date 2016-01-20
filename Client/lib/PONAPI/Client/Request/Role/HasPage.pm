# ABSTRACT: request - role - has page
package PONAPI::Client::Request::Role::HasPage;

use Moose::Role;

has page => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_page',
);

no Moose::Role; 1;

__END__
