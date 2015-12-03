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
        local $@;
        eval {
            my @ret = $repo->delete( %{ $self } );
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
