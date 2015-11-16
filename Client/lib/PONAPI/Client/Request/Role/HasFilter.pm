package PONAPI::Client::Request::Role::HasFilter;

use Moose::Role;

has filter => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_filter',
);

no Moose::Role; 1;
__END__
