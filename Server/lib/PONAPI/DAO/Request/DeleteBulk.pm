# ABSTRACT: DAO request - delete bulk
package PONAPI::DAO::Request::DeleteBulk;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasDataBulk',
     'PONAPI::DAO::Request::Role::HasDataMethods';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        $doc->set_bulk;

        $self->repository->delete_bulk( %{ $self } );
        # TODO:
        # $doc->add_meta(
        #     detail => "successfully deleted the resource /"
        #             . $self->type
        #             . "/"
        #             . $self->id
        # );

        $doc->build;
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
