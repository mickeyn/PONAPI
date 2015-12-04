package PONAPI::DAO::Request::Role::HasID;

use Moose::Role;

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

no Moose::Role; 1;
__END__
