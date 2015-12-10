# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
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
