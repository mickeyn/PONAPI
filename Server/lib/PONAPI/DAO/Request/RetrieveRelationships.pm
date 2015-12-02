package PONAPI::DAO::Request::RetrieveRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

sub BUILD {
    my $self = shift;

    $self->check_has_id;
    $self->check_has_rel_type;
    $self->check_no_body;
}

sub execute {
    my ( $self, $repo ) = @_;

    if ( $self->is_valid ) {
        eval {
            my @ret = $repo->retrieve_relationships( %{ $self } );
            $self->_verify_repository_response(@ret);

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
