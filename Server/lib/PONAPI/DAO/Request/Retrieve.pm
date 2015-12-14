# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::Retrieve;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasFields',
     'PONAPI::DAO::Request::Role::HasFilter',
     'PONAPI::DAO::Request::Role::HasInclude',
     # paginate included resources
     'PONAPI::DAO::Request::Role::HasPage',
     # sort is needed by page
     'PONAPI::DAO::Request::Role::HasSort',
     'PONAPI::DAO::Request::Role::HasID';

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        local $@;
        eval {
            $self->repository->retrieve( %{ $self } );
            $self->document->add_null_resource
                unless $self->document->_has_resource_builders;
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
