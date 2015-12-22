# ABSTRACT: DAO request - delete
package PONAPI::DAO::Request::Delete;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasID';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        $self->repository->delete( %{ $self } );
        $doc->add_meta(
            detail => "successfully deleted the resource /"
                    . $self->type
                    . "/"
                    . $self->id
        );
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
