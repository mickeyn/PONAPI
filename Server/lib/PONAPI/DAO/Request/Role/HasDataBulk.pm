# ABSTRACT: DAO request role - `data-bulk`
package PONAPI::DAO::Request::Role::HasDataBulk;

use Moose::Role;

has data => (
    is        => 'ro',
    isa       => 'ArrayRef[HashRef]',
    predicate => 'has_data',
);

no Moose::Role; 1;

__END__
