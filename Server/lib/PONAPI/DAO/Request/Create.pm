package PONAPI::DAO::Request::Create;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';

sub BUILD {
    my $self = shift;

    $self->check_no_id;
    $self->check_no_rel_type;

    # http://jsonapi.org/format/#crud-creating-responses-409
    # We need to return a 409 if $data->{type} ne $self->type
    $self->check_has_data and $self->check_data_has_type and $self->check_data_type_match;
}

sub execute {
    my ( $self, $repo ) = @_;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        eval {
            my $ret = $repo->create( %{ $self } );

            if ( $doc->has_errors || $PONAPI_ERROR_RETURN{$ret} ) {
                $doc->set_status(409) if $ret == PONAPI_CONFLICT_ERROR;
                $doc->set_status(404) if $ret == PONAPI_UNKNOWN_RELATIONSHIP;
            }
            else {
                $doc->add_meta(
                    message => "successfully created the resource: "
                             . $self->type
                             . " => "
                             . $self->json->encode( $self->data )
                );
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $self->_server_failure;
        };
    }

    my @headers;
    if ( !$doc->has_errors ) {
        # TODO make less terrible
        my $document = $doc->build;
        push @headers, Location => "/$document->{data}{type}/$document->{data}{id}";
    }

    return $self->response( @headers );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
