# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder::Relationship;
use Moose;

use PONAPI::Builder::Resource::Identifier;

with 'PONAPI::Builder',
     'PONAPI::Builder::Role::HasLinksBuilder',
     'PONAPI::Builder::Role::HasMeta';

has '_resource_id_builders' => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    isa       => 'ArrayRef[ PONAPI::Builder::Resource::Identifier ]',
    lazy      => 1,
    default   => sub { +[] },
    predicate => '_has_resource_id_builders',
    handles   => {
        '_num_resource_id_builders' => 'count',
        # private ...
        '_add_resource_id_builder'  => 'push',
        '_get_resource_id_builder'  => 'get',
    }
);

sub has_resource {
    my $self = $_[0];
    $self->_has_resource_id_builders && $self->_num_resource_id_builders > 0;
}

sub has_resources {
    my $self = $_[0];
    $self->_has_resource_id_builders && $self->_num_resource_id_builders > 1;
}

sub add_resource {
    my ($self, $resource) = @_;
    my $b = PONAPI::Builder::Resource::Identifier->new( parent => $self, %$resource );
    $b->add_meta( %{ $resource->{meta} } ) if $resource->{meta};
    $self->_add_resource_id_builder( $b );
}

sub build {
    my $self   = $_[0];
    my $result = {};

    if ( $self->has_resources ) {
        # if it is a collection, then
        # call build on each one ...
        $result->{data} = [ map { $_->build } @{ $self->_resource_id_builders } ];
    }
    else {
        # if it is a single resource,
        # just use that one
        $result->{data} = $self->_get_resource_id_builder(0)->build;
    }

    $result->{links} = $self->links_builder->build if $self->has_links_builder;
    $result->{meta}  = $self->_meta                if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
