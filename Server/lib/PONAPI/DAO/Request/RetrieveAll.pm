package PONAPI::DAO::Request::RetrieveAll;

use Moose;

extends 'PONAPI::DAO::Request';

sub BUILD {
    my $self = shift;

    $self->check_no_id;
    $self->check_no_body;
}

sub execute {
    my ( $self, $repo ) = @_;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        $doc->convert_to_collection;

        eval {
            $repo->retrieve_all( %{ $self } );
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
