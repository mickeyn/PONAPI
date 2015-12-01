package PONAPI::DAO::Request::Delete;

use Moose;

extends 'PONAPI::DAO::Request';

sub BUILD {
    my $self = shift;

    $self->check_has_id;
    $self->check_no_rel_type;
    $self->check_no_body;
}

sub execute {
    my ( $self, $repo ) = @_;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        eval {
            my ($ret, @extra) = $repo->delete( %{ $self } );
            return unless $self->verify_repository_response($ret, @extra);

            $doc->add_meta(
                message => "successfully deleted the resource /"
                         . $self->type
                         . "/"
                         . $self->id
            );
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
