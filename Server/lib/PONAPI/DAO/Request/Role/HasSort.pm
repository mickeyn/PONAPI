package PONAPI::DAO::Request::Role::HasSort;

use Moose::Role;

has sort => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { +[] },
    handles  => {
        "has_sort" => 'count',
    },
);


no Moose::Role; 1;
__END__
