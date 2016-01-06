# ABSTRACT: DAO request - retrieve relationships
package PONAPI::DAO::Request::RetrieveRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasFilter',
     'PONAPI::DAO::Request::Role::HasPage',
     'PONAPI::DAO::Request::Role::HasSort',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        my $repo        = $self->repository;
        my $document    = $self->document;
        my $one_to_many = $repo->has_one_to_many_relationship($self->type, $self->rel_type);

        $document->convert_to_collection if $one_to_many;

        $repo->retrieve_relationships( %{ $self } );

        $document->add_null_resource
            unless $one_to_many or $document->has_resource_builders;
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
