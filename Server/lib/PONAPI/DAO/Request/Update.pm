package PONAPI::DAO::Request::Update;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataAttribute',
     'PONAPI::DAO::Request::Role::HasDataMethods';

has '+update_nothing_status' => (
    # http://jsonapi.org/format/#crud-updating-responses-404
    default => sub { 404 },
);

sub BUILD {
    my $self = shift;

    $self->check_has_id;
    $self->check_no_rel_type;

    # http://jsonapi.org/format/#crud-updating-responses-409
    # A server MUST return 409 Conflict when processing a PATCH request in which the
    # resource object's type and id do not match the server's endpoint.
    $self->check_has_data and $self->check_data_has_type and $self->check_data_type_match;
}

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        local $@;
        eval {
            my @ret = $self->repository->update( %{ $self } );

            $self->_add_success_meta(@ret)
                if $self->_verify_update_response(@ret);

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
