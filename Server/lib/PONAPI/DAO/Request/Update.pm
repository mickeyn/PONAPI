package PONAPI::DAO::Request::Update;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasUpdates200';

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
            my $ret = $repo->update( %{ $self } );

### ???
            if ( !exists $PONAPI_UPDATE_RETURN_VALUES{$ret} ) {
                die ref($repo), "->update returned an unexpected value";
            }

            if ( $PONAPI_ERROR_RETURN{$ret} ) {
                $doc->set_status(409) if $ret == PONAPI_CONFLICT_ERROR;
                $doc->set_status(404) if $ret == PONAPI_UNKNOWN_RELATIONSHIP;
                return 1; # return from eval
            }

            my $resource = "/"
                         . $self->type
                         . "/"
                         . $self->id
                         . " => "
                         .$self->json->encode( $self->data );

            my $message = "successfully updated the resource $resource";
            if ( $ret == PONAPI_UPDATED_NOTHING ) {
                $doc->set_status(404);
                $message = "updated nothing for the resource $resource"
            }

            $doc->add_meta( message => $message );

            unless ( $doc->has_errors or $doc->has_status ) {
                if ( $self->respond_to_updates_with_200 ) {
                    $doc->set_status(200);
                    return $repo->retrieve(
                        type     => $self->type,
                        id       => $self->id,
                        document => $doc,
                    ) if $ret == PONAPI_UPDATED_EXTENDED;
                }
                else {
                    $doc->set_status(202);
                }
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
