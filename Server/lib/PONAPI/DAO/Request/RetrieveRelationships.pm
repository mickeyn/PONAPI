# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::RetrieveRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasFields',
     'PONAPI::DAO::Request::Role::HasFilter',
     'PONAPI::DAO::Request::Role::HasInclude',
     'PONAPI::DAO::Request::Role::HasPage',
     'PONAPI::DAO::Request::Role::HasSort',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        local $@;
        eval {
            $self->repository->retrieve_relationships( %{ $self } );
            1;
        } or do {
            my $e = $@;
            $self->_handle_error($e);
        };
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
