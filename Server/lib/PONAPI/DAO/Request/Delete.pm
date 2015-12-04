package PONAPI::DAO::Request::Delete;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasID';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        local $@;
        eval {
            my @ret = $self->repository->delete( %{ $self } );
            $doc->add_meta(
                detail => "successfully deleted the resource /"
                        . $self->type
                        . "/"
                        . $self->id
            );
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
