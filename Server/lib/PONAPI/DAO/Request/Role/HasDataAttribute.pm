# ABSTRACT: DAO request role - `data`
package PONAPI::DAO::Request::Role::HasDataAttribute;

use Moose::Role;

has data => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_data" => 'count',
    },
);

no Moose::Role; 1;

__END__
