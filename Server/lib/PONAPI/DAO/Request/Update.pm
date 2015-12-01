package PONAPI::DAO::Request::Update;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike';

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
    my ( $self, $repo ) = @_;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        eval {
            my @ret = $repo->update( %{ $self } );

            if ( $self->_verify_repository_response(@ret) ) {
                $self->_add_success_meta(@ret)
                    if $self->_verify_update_response($repo, @ret);
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $self->_server_failure;
        };
    }

    return $self->response();
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
