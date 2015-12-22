# ABSTRACT: DAO request - retrieve all
package PONAPI::DAO::Request::RetrieveAll;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasFields',
     'PONAPI::DAO::Request::Role::HasFilter',
     'PONAPI::DAO::Request::Role::HasInclude',
     'PONAPI::DAO::Request::Role::HasPage',
     'PONAPI::DAO::Request::Role::HasSort';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        $doc->convert_to_collection;
        $self->repository->retrieve_all( %{ $self } );
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
