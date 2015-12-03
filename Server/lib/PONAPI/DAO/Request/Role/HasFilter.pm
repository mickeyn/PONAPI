package PONAPI::DAO::Request::Role::HasFilter;

use Moose::Role;

has filter => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_filter" => 'count',
    },
);


no Moose::Role; 1;
__END__
