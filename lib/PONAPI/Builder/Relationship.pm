package PONAPI::Builder::Relationship;
use Moose;

use PONAPI::Builder::Resource::Identifier;

with 'PONAPI::Builder', 
     'PONAPI::Builder::Role::HasLinksBuilder';

has 'resource_id_builder' => ( 
    is        => 'ro', 
    isa       => 'PONAPI::Builder::Resource::Identifier', 
    predicate => 'has_resource_id_builder',
    writer    => '_set_resource_id_builder',
);

sub BUILD { 
    my ($self, $param) = @_;
    $self->_set_resource_id_builder(
        PONAPI::Builder::Resource::Identifier->new( 
            parent => $self,
            id     => $param->{id},
            type   => $param->{type}
        ) 
    );
}

sub build {
    my $self   = $_[0];
    my $result = {};

    $self->raise_error( 
        title => 'You must specify a resource identifier to relate with'   
    ) unless $self->has_resource_id_builder;

    $result->{data}  = $self->resource_id_builder->build;
    $result->{links} = $self->links_builder->build    
        if $self->has_links_builder;

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
