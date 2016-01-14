# ABSTRACT: DAO request - create bulk
package PONAPI::DAO::Request::CreateBulk;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasDataBulk',
     'PONAPI::DAO::Request::Role::HasDataMethods';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    my @headers;
    if ( $self->is_valid ) {
        $self->document->set_bulk;
        $self->repository->create_bulk( %{ $self } );
        $doc->add_meta(
            detail => "successfully created the resources: "
                    . $self->type
                    . " => "
                    . $self->json->encode( $self->data )
        );

        $doc->set_status(201) unless $doc->has_status;

        my $document  = $doc->build;
        # TODO: what links/headers are returned in bulk creation???
        # my $self_link = $document->{data}{links}{self};
        # $self_link  //= "/$document->{data}{type}/$document->{data}{id}";

        # push @headers, Location => $self_link;
    }

    return $self->response( @headers );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
