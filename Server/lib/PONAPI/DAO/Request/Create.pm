# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::Create;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasDataAttribute',
     'PONAPI::DAO::Request::Role::HasDataMethods';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    my @headers;
    if ( $self->is_valid ) {
        local $@;
        eval {
            $self->repository->create( %{ $self } );
            $doc->add_meta(
                detail => "successfully created the resource: "
                        . $self->type
                        . " => "
                        . $self->json->encode( $self->data )
            );

            $doc->set_status(201) unless $doc->has_status;

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

__END__
