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

    my @headers;
    if ( $self->is_valid ) {
        local $@;
        eval {
            $repo->create( %{ $self } );
            $doc->add_meta(
                detail => "successfully created the resource: "
                        . $self->type
                        . " => "
                        . $self->json->encode( $self->data )
            );

            my $document  = $doc->build;
            my $self_link = $document->{data}{links}{self};
            $self_link  //= "/$document->{data}{type}/$document->{data}{id}";

            push @headers, Location => $self_link;

            1;
        } or do {
            my $e = $@;
            $self->_handle_error($e);
        };
    }

    return $self->response( @headers );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
