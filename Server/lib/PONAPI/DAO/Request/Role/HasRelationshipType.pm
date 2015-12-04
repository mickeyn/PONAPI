package PONAPI::DAO::Request::Role::HasRelationshipType;

use Moose::Role;

has rel_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rel_type',
);

no Moose::Role; 1;
__END__
