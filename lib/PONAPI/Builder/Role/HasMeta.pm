# ABSTRACT: PONAPI - Perl JSON-API implementation (http://jsonapi.org/) v1.0
package PONAPI::Builder::Role::HasMeta;
use Moose::Role;

has _meta => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_meta  => 'count',
    }
);

sub add_meta {
    my ($self, %args) = shift;
    @{ $self->_meta }{ keys %args } = values %args;
    return $self;
}

no Moose::Role; 1;
